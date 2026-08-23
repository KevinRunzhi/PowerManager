import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/learning/activity_impact_contract.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

void main() {
  group('ActivityImpactFeasibilityAudit', () {
    test(
      'keeps user initiated research separate from sampled qualification',
      () {
        final observations = <ActivityImpactFeedbackObservation>[
          _observation(
            day: LifeDay(2026, 8, 1),
            source: ActivityFeedbackCollectionSource.userInitiated,
          ),
          _observation(
            day: LifeDay(2026, 8, 2),
            source: ActivityFeedbackCollectionSource.sampledPrompt,
          ),
          _observation(
            day: LifeDay(2026, 8, 3),
            source: ActivityFeedbackCollectionSource.sampledPrompt,
            direction: ActivityFeedbackDirection.strongerImpact,
          ),
          _observation(
            day: LifeDay(2026, 8, 4),
            source: ActivityFeedbackCollectionSource.sampledPrompt,
            direction: ActivityFeedbackDirection.weakerImpact,
          ),
          _observation(
            day: LifeDay(2026, 8, 5),
            source: ActivityFeedbackCollectionSource.sampledPrompt,
            direction: ActivityFeedbackDirection.aboutRight,
          ),
        ];
        final audit = const ActivityImpactFeasibilityAudit().audit(
          observations,
        );
        final key = const ActivityImpactKey(
          subcategory: ActivitySubcategory.selfStudyOrThesis,
          impactSign: ActivityImpactSign.consumption,
        );
        final result = audit[key]!;

        expect(result.totalCount, 5);
        expect(result.activeCount, 5);
        expect(result.sampledComparableCount, 4);
        expect(result.sampledFactorEligibleCount, 4);
        expect(result.sampledLifeDays.length, 4);
        expect(result.count(ActivityFeedbackDirection.strongerImpact), 1);
        expect(result.count(ActivityFeedbackDirection.aboutRight), 3);
        expect(result.count(ActivityFeedbackDirection.weakerImpact), 1);
      },
    );

    test(
      'records invalidated, zero and recovery truncation without qualifying them',
      () {
        final values = [
          _observation(
            day: LifeDay(2026, 8, 1),
            status: ActivityFeedbackStatus.invalidated,
          ),
          _observation(
            day: LifeDay(2026, 8, 2),
            theoreticalDelta: 0,
            appliedDelta: 0,
            impactSign: ActivityImpactSign.zero,
          ),
          _observation(
            day: LifeDay(2026, 8, 3),
            theoreticalDelta: 8,
            appliedDelta: 5,
            impactSign: ActivityImpactSign.recovery,
          ),
        ];
        final result = const ActivityImpactFeasibilityAudit()
            .audit(values)
            .values
            .toList();

        expect(result, hasLength(3));
        final consumption = result.firstWhere(
          (item) => item.key.impactSign == ActivityImpactSign.consumption,
        );
        expect(consumption.invalidatedCount, 1);
        final recovery = result.firstWhere(
          (item) => item.key.impactSign == ActivityImpactSign.recovery,
        );
        expect(recovery.recoveryTruncatedCount, 1);
        expect(recovery.comparableCount, 0);
        final zero = result.firstWhere(
          (item) => item.key.impactSign == ActivityImpactSign.zero,
        );
        expect(zero.zeroTheoreticalCount, 1);
      },
    );
  });

  group('ActivityImpactSampler', () {
    final day = LifeDay(2026, 8, 15);

    test('off mode never prompts and selection is stable across restarts', () {
      final activities = [_activity('a'), _activity('b'), _activity('c')];
      const sampler = ActivityImpactSampler();

      final off = sampler.select(
        mode: LearningMode.off,
        currentLifeDay: day,
        activities: activities,
        samples: const [],
      );
      final first = sampler.select(
        mode: LearningMode.review,
        currentLifeDay: day,
        activities: activities,
        samples: const [],
      );
      final restarted = sampler.select(
        mode: LearningMode.review,
        currentLifeDay: day,
        activities: activities,
        samples: const [],
      );

      expect(off.reason, ActivityImpactNoPromptReason.modeOff);
      expect(first.activity!.id, restarted.activity!.id);
    });

    test('enforces daily cap, skip cooldown and no-response cooldown', () {
      const sampler = ActivityImpactSampler();
      final selected = _sample('a', day, ActivityImpactSampleStatus.selected);
      expect(
        sampler
            .select(
              mode: LearningMode.automatic,
              currentLifeDay: day,
              activities: [_activity('a'), _activity('b')],
              samples: [selected],
            )
            .reason,
        ActivityImpactNoPromptReason.dailyCap,
      );

      final skippedYesterday = _sample(
        'old',
        day.previous,
        ActivityImpactSampleStatus.skipped,
      );
      expect(
        sampler
            .select(
              mode: LearningMode.review,
              currentLifeDay: day,
              activities: [_activity('b')],
              samples: [skippedYesterday],
            )
            .reason,
        ActivityImpactNoPromptReason.skipCooldown,
      );

      final promptedYesterday = _sample(
        'old',
        day.previous,
        ActivityImpactSampleStatus.prompted,
      );
      expect(
        sampler
            .select(
              mode: LearningMode.review,
              currentLifeDay: day,
              activities: [_activity('b')],
              samples: [promptedYesterday],
            )
            .reason,
        ActivityImpactNoPromptReason.noResponseCooldown,
      );
    });

    test(
      'does not reuse invalidated samples or count another policy version',
      () {
        const sampler = ActivityImpactSampler();
        final result = sampler.select(
          mode: LearningMode.review,
          currentLifeDay: day,
          activities: [_activity('a')],
          samples: [
            _sample('a', day, ActivityImpactSampleStatus.invalidated),
            ActivityImpactSampleState(
              activityRecordId: 'legacy',
              lifeDay: LifeDay(2026, 8, 15),
              policyVersion: 'activity-impact-sampling-preprod-v0',
              status: ActivityImpactSampleStatus.selected,
            ),
          ],
        );

        expect(result.hasPrompt, isTrue);
        expect(result.activity!.id, 'a');
      },
    );

    test(
      'filters zero, recovery truncation, inactive and wrong-rule activities',
      () {
        const sampler = ActivityImpactSampler();
        final result = sampler.select(
          mode: LearningMode.review,
          currentLifeDay: day,
          activities: [
            _activity('zero', theoreticalDelta: 0, appliedDelta: 0),
            _activity('truncated', theoreticalDelta: 8, appliedDelta: 5),
            _activity('deleted', status: ActivityRecordStatus.deleted),
            _activity('old-rule', ruleVersion: 'old-rule'),
          ],
          samples: const [],
        );

        expect(result.reason, ActivityImpactNoPromptReason.noEligibleActivity);
      },
    );
  });

  group('ActivityImpactFactorGate', () {
    test('passes only a sampled key with minimum samples and days', () {
      final values = [
        for (var index = 0; index < 8; index++)
          _observation(
            day: LifeDay(2026, 8, index + 1),
            source: ActivityFeedbackCollectionSource.sampledPrompt,
            direction: index.isEven
                ? ActivityFeedbackDirection.aboutRight
                : ActivityFeedbackDirection.strongerImpact,
          ),
      ];
      final audit = const ActivityImpactFeasibilityAudit()
          .audit(values)
          .values
          .single;
      final decision = const ActivityImpactFactorGate().evaluate(audit);

      expect(decision.result, ActivityImpactFactorGateResult.eligible);
      expect(decision.eligibleForShadow, isTrue);
    });

    test('vetoes sampled direction mismatch and heterogeneous durations', () {
      final mismatch = [
        for (var index = 0; index < 8; index++)
          _observation(
            day: LifeDay(2026, 8, index + 1),
            source: ActivityFeedbackCollectionSource.sampledPrompt,
            direction: index < 2
                ? ActivityFeedbackDirection.directionMismatch
                : ActivityFeedbackDirection.aboutRight,
          ),
      ];
      final mismatchAudit = const ActivityImpactFeasibilityAudit()
          .audit(mismatch)
          .values
          .single;
      expect(
        const ActivityImpactFactorGate().evaluate(mismatchAudit).result,
        ActivityImpactFactorGateResult.directionMismatchVeto,
      );

      final heterogeneous = [
        for (var index = 0; index < 8; index++)
          _observation(
            day: LifeDay(2026, 8, index + 1),
            source: ActivityFeedbackCollectionSource.sampledPrompt,
            duration: index.isEven
                ? DurationSlot.minutes15
                : DurationSlot.minutes90,
          ),
      ];
      final heterogeneousAudit = const ActivityImpactFeasibilityAudit()
          .audit(heterogeneous)
          .values
          .single;
      expect(
        const ActivityImpactFactorGate().evaluate(heterogeneousAudit).result,
        ActivityImpactFactorGateResult.unstableDuration,
      );
    });
  });

  group('ActivityImpactFactorCalculator', () {
    test('rounds before applying the existing recovery ceiling', () {
      const calculator = ActivityImpactFactorCalculator();
      final consumption = calculator.calculate(
        theoreticalDelta: -5,
        factor: 1.50,
        currentEstimate: 50,
        initialEstimate: 100,
      );
      final recovery = calculator.calculate(
        theoreticalDelta: 5,
        factor: 1.50,
        currentEstimate: 98,
        initialEstimate: 100,
      );

      expect(consumption.personalizedTheoreticalDelta, -8);
      expect(consumption.appliedDelta, -8);
      expect(recovery.personalizedTheoreticalDelta, 8);
      expect(recovery.appliedDelta, 2);
    });

    test('rejects zero and out-of-range factors', () {
      const calculator = ActivityImpactFactorCalculator();
      expect(
        () => calculator.calculate(
          theoreticalDelta: 0,
          factor: 1.0,
          currentEstimate: 50,
          initialEstimate: 100,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculator.calculate(
          theoreticalDelta: -5,
          factor: 1.01,
          currentEstimate: 50,
          initialEstimate: 100,
        ),
        throwsArgumentError,
      );
    });
  });
}

ActivityImpactFeedbackObservation _observation({
  required LifeDay day,
  ActivityFeedbackCollectionSource source =
      ActivityFeedbackCollectionSource.userInitiated,
  ActivityFeedbackDirection direction = ActivityFeedbackDirection.aboutRight,
  ActivityFeedbackStatus status = ActivityFeedbackStatus.active,
  DurationSlot duration = DurationSlot.minutes30,
  int theoreticalDelta = -6,
  int appliedDelta = -6,
  ActivityImpactSign impactSign = ActivityImpactSign.consumption,
  String ruleVersion = activityImpactSupportedRuleVersion,
}) {
  return ActivityImpactFeedbackObservation(
    lifeDay: day,
    subcategory: ActivitySubcategory.selfStudyOrThesis,
    duration: duration,
    theoreticalDelta: theoreticalDelta,
    appliedDelta: appliedDelta,
    impactSign: impactSign,
    ruleVersion: ruleVersion,
    direction: direction,
    status: status,
    collectionSource: source,
  );
}

ActivityImpactSamplingActivity _activity(
  String id, {
  int theoreticalDelta = -6,
  int appliedDelta = -6,
  String ruleVersion = activityImpactSupportedRuleVersion,
  ActivityRecordStatus status = ActivityRecordStatus.active,
}) {
  return ActivityImpactSamplingActivity(
    id: id,
    lifeDay: LifeDay(2026, 8, 15),
    subcategory: ActivitySubcategory.selfStudyOrThesis,
    duration: DurationSlot.minutes30,
    theoreticalDelta: theoreticalDelta,
    appliedDelta: appliedDelta,
    ruleVersion: ruleVersion,
    status: status,
  );
}

ActivityImpactSampleState _sample(
  String id,
  LifeDay day,
  ActivityImpactSampleStatus status,
) {
  return ActivityImpactSampleState(
    activityRecordId: id,
    lifeDay: day,
    policyVersion: activityFeedbackSamplingPolicyV1,
    status: status,
  );
}
