import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/activity_impact_contract.dart';
import 'package:power_manager/domain/learning/activity_impact_learner.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

void main() {
  const learner = ActivityImpactLearner();
  final current = ActivityImpactLearningCurrentModel(
    personalizationVersionId: 'pv-1',
    factorRegimeStartedLifeDay: LifeDay(2026, 8, 1),
    factors: {
      ActivityImpactKey(
        subcategory: ActivitySubcategory.selfStudyOrThesis,
        impactSign: ActivityImpactSign.consumption,
      ): 1.0,
    },
  );

  test('user initiated evidence never enters the learner', () {
    final item = _observation(
      day: LifeDay(2026, 8, 1),
      direction: ActivityFeedbackDirection.strongerImpact,
      source: ActivityFeedbackCollectionSource.userInitiated,
    );

    final result = learner.evaluate(observations: [item], current: current);

    expect(result.result, LearningRunResult.insufficientEvidence);
    expect(result.candidates, isEmpty);
    expect(result.reasonCodes, contains('userInitiatedFeedbackExcluded'));
  });

  test(
    'eligible sampled evidence produces a deterministic bounded candidate',
    () {
      final observations = [
        for (var index = 0; index < 8; index++)
          _observation(
            day: LifeDay(2026, 8, 1 + index % 4),
            id: 'strong-$index',
            direction: ActivityFeedbackDirection.strongerImpact,
          ),
      ];

      final first = learner.evaluate(
        observations: observations,
        current: current,
      );
      final second = learner.evaluate(
        observations: observations.reversed,
        current: current,
      );

      expect(first.result, LearningRunResult.candidate);
      expect(first.candidates.single.candidateFactor, 1.05);
      expect(first.candidateValuesJson, isNotNull);
      expect(first.candidateValuesJson, contains('factorBps":105'));
      expect(first.candidateExecutable, isFalse);
      expect(first.evidenceHash, second.evidenceHash);
      expect(first.candidateValuesJson, second.candidateValuesJson);
    },
  );

  test('weaker feedback decreases factor and about-right makes no change', () {
    final weaker = learner.evaluate(
      observations: [
        for (var index = 0; index < 8; index++)
          _observation(
            day: LifeDay(2026, 8, 1 + index % 4),
            id: 'weak-$index',
            direction: ActivityFeedbackDirection.weakerImpact,
          ),
      ],
      current: current,
    );
    final aboutRight = learner.evaluate(
      observations: [
        for (var index = 0; index < 8; index++)
          _observation(
            day: LifeDay(2026, 8, 1 + index % 4),
            id: 'right-$index',
            direction: ActivityFeedbackDirection.aboutRight,
          ),
      ],
      current: current,
    );

    expect(weaker.result, LearningRunResult.candidate);
    expect(weaker.candidates.single.candidateFactor, 0.95);
    expect(aboutRight.result, LearningRunResult.noChange);
  });

  test('stale regime, truncation, and unsupported policy are excluded', () {
    final stale = _observation(
      day: LifeDay(2026, 8, 1),
      id: 'stale',
      regime: LifeDay(2026, 7, 1),
    );
    final truncated = _observation(
      day: LifeDay(2026, 8, 1),
      id: 'truncated',
      appliedDelta: -9,
    );
    final unsupported = _observation(
      day: LifeDay(2026, 8, 1),
      id: 'policy',
      policyVersion: 'old-policy',
    );

    final result = learner.evaluate(
      observations: [stale, truncated, unsupported],
      current: current,
    );

    expect(result.result, LearningRunResult.insufficientEvidence);
    expect(result.reasonCodes, contains('staleFactorRegime'));
    expect(result.reasonCodes, contains('zeroOrTruncatedEvidence'));
    expect(result.reasonCodes, contains('unsupportedSamplingPolicy'));
  });

  test(
    'direction mismatch veto and duration heterogeneity are safety stops',
    () {
      final mismatch = learner.evaluate(
        observations: [
          for (var index = 0; index < 8; index++)
            _observation(
              day: LifeDay(2026, 8, 1 + index % 4),
              id: 'mismatch-$index',
              direction: index < 2
                  ? ActivityFeedbackDirection.directionMismatch
                  : ActivityFeedbackDirection.strongerImpact,
            ),
        ],
        current: current,
      );
      final heterogeneous = learner.evaluate(
        observations: [
          for (var index = 0; index < 8; index++)
            _observation(
              day: LifeDay(2026, 8, 1 + index % 4),
              id: 'duration-$index',
              duration: index.isEven
                  ? DurationSlot.minutes15
                  : DurationSlot.minutes120,
            ),
        ],
        current: current,
      );

      expect(mismatch.result, LearningRunResult.unstable);
      expect(mismatch.reasonCodes, contains('directionMismatchVeto'));
      expect(heterogeneous.result, LearningRunResult.unstable);
      expect(heterogeneous.reasonCodes, contains('durationHeterogeneity'));
    },
  );
}

ActivityImpactLearningObservation _observation({
  required LifeDay day,
  String id = 'activity-1',
  ActivityFeedbackDirection direction = ActivityFeedbackDirection.aboutRight,
  ActivityFeedbackCollectionSource source =
      ActivityFeedbackCollectionSource.sampledPrompt,
  String policyVersion = activityFeedbackSamplingPolicyV1,
  LifeDay? regime,
  DurationSlot duration = DurationSlot.minutes30,
  int appliedDelta = -10,
}) {
  final activity = StoredEstimatedActivity(
    id: id,
    lifeDay: day,
    completedAt: DateTime.utc(2026, 8, day.day, 10),
    createdAt: DateTime.utc(2026, 8, day.day, 10),
    updatedAt: DateTime.utc(2026, 8, day.day, 10),
    category: ActivityCategory.study,
    subcategory: ActivitySubcategory.selfStudyOrThesis,
    duration: duration,
    theoreticalDelta: -10,
    appliedDelta: appliedDelta,
    ruleVersion: activityImpactSupportedRuleVersion,
    status: ActivityRecordStatus.active,
    deletedAt: null,
    personalizationVersionId: 'pv-1',
    factorRegimeStartedLifeDay: regime ?? LifeDay(2026, 8, 1),
    defaultTheoreticalDelta: -10,
    factor: 1.0,
    personalizedTheoreticalDelta: -10,
  );
  final feedback = ActivityFeedback(
    id: 'feedback-$id',
    activityRecordId: id,
    lifeDay: day,
    subcategorySnapshot: activity.subcategory,
    durationSnapshot: duration,
    theoreticalDeltaSnapshot: -10,
    appliedDeltaSnapshot: appliedDelta,
    impactSignSnapshot: ActivityImpactSign.consumption,
    ruleVersionSnapshot: activity.ruleVersion,
    activityUpdatedAtSnapshot: activity.updatedAt,
    direction: direction,
    status: ActivityFeedbackStatus.active,
    invalidationReason: null,
    observedAt: activity.updatedAt,
    defaultTheoreticalDeltaSnapshot: -10,
    factorSnapshot: 1.0,
    personalizedTheoreticalDeltaSnapshot: -10,
    personalizationVersionId: 'pv-1',
    factorRegimeStartedLifeDay: regime ?? LifeDay(2026, 8, 1),
    collectionSource: source,
    samplingPolicyVersion:
        source == ActivityFeedbackCollectionSource.sampledPrompt
        ? policyVersion
        : null,
    sampledAt: source == ActivityFeedbackCollectionSource.sampledPrompt
        ? activity.updatedAt
        : null,
    sampleId: source == ActivityFeedbackCollectionSource.sampledPrompt
        ? 'sample-$id'
        : null,
  );
  final sample = ActivityFeedbackSample(
    id: 'sample-$id',
    activityRecordId: id,
    lifeDay: day,
    samplingPolicyVersion: policyVersion,
    status: ActivityFeedbackSampleStatus.responded,
    selectedAt: activity.updatedAt,
    promptedAt: activity.updatedAt,
    respondedAt: activity.updatedAt,
    feedbackId: feedback.id,
    invalidatedAt: null,
    invalidationReason: null,
  );
  return ActivityImpactLearningObservation(
    activity: activity,
    sample: sample,
    feedback: feedback,
    lifeDaySettled: true,
  );
}
