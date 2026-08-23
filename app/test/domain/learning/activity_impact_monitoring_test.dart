import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/activity_impact_contract.dart';
import 'package:power_manager/domain/learning/activity_impact_learner.dart';
import 'package:power_manager/domain/learning/activity_impact_monitoring.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

void main() {
  const evaluator = ActivityImpactMonitoringEvaluator();
  final current = ActivityImpactLearningCurrentModel(
    personalizationVersionId: 'pv-1',
    factorRegimeStartedLifeDay: LifeDay(2026, 8, 1),
    factors: {
      const ActivityImpactKey(
        subcategory: ActivitySubcategory.selfStudyOrThesis,
        impactSign: ActivityImpactSign.consumption,
      ): 1,
    },
  );

  test('stable about-right evidence is reported as improved', () {
    final result = evaluator.evaluate(
      observations: [
        for (var index = 0; index < 8; index++)
          _observation(index + 1, ActivityFeedbackDirection.aboutRight),
      ],
      current: current,
    );

    expect(result.result, LearningRunResult.improved);
    expect(result.reasonCodes, contains('stableAboutRightEvidence'));
  });

  test('mismatch veto reports worsened at both safety boundaries', () {
    final result = evaluator.evaluate(
      observations: [
        _observation(1, ActivityFeedbackDirection.directionMismatch),
        _observation(2, ActivityFeedbackDirection.directionMismatch),
        for (var index = 3; index <= 8; index++)
          _observation(index, ActivityFeedbackDirection.aboutRight),
      ],
      current: current,
    );

    expect(result.result, LearningRunResult.worsened);
    expect(result.reasonCodes, contains('directionMismatchVeto'));
  });

  test(
    'insufficient settled coverage never produces a monitoring decision',
    () {
      final result = evaluator.evaluate(
        observations: [
          _observation(1, ActivityFeedbackDirection.aboutRight),
          _observation(2, ActivityFeedbackDirection.aboutRight),
          _observation(3, ActivityFeedbackDirection.aboutRight),
        ],
        current: current,
      );

      expect(result.result, LearningRunResult.insufficientEvidence);
      expect(result.reasonCodes, contains('minimumSampleOrDayNotMet'));
    },
  );
}

ActivityImpactLearningObservation _observation(
  int day,
  ActivityFeedbackDirection direction,
) {
  final lifeDay = LifeDay(2026, 8, day);
  final at = DateTime.utc(2026, 8, day, 10);
  final activity = StoredEstimatedActivity(
    id: 'activity-$day',
    lifeDay: lifeDay,
    completedAt: at,
    createdAt: at,
    updatedAt: at,
    category: ActivityCategory.study,
    subcategory: ActivitySubcategory.selfStudyOrThesis,
    duration: DurationSlot.minutes30,
    theoreticalDelta: -10,
    appliedDelta: -10,
    ruleVersion: activityImpactSupportedRuleVersion,
    status: ActivityRecordStatus.active,
    deletedAt: null,
    personalizationVersionId: 'pv-1',
    factorRegimeStartedLifeDay: LifeDay(2026, 8, 1),
    defaultTheoreticalDelta: -10,
    factor: 1,
    personalizedTheoreticalDelta: -10,
  );
  final feedback = ActivityFeedback(
    id: 'feedback-$day',
    activityRecordId: activity.id,
    lifeDay: lifeDay,
    subcategorySnapshot: activity.subcategory,
    durationSnapshot: activity.duration,
    theoreticalDeltaSnapshot: -10,
    appliedDeltaSnapshot: -10,
    impactSignSnapshot: ActivityImpactSign.consumption,
    ruleVersionSnapshot: activity.ruleVersion,
    activityUpdatedAtSnapshot: at,
    direction: direction,
    status: ActivityFeedbackStatus.active,
    invalidationReason: null,
    observedAt: at,
    defaultTheoreticalDeltaSnapshot: -10,
    factorSnapshot: 1,
    personalizedTheoreticalDeltaSnapshot: -10,
    personalizationVersionId: 'pv-1',
    factorRegimeStartedLifeDay: LifeDay(2026, 8, 1),
    collectionSource: ActivityFeedbackCollectionSource.sampledPrompt,
    samplingPolicyVersion: activityFeedbackSamplingPolicyV1,
    sampledAt: at,
    sampleId: 'sample-$day',
  );
  final sample = ActivityFeedbackSample(
    id: 'sample-$day',
    activityRecordId: activity.id,
    lifeDay: lifeDay,
    samplingPolicyVersion: activityFeedbackSamplingPolicyV1,
    status: ActivityFeedbackSampleStatus.responded,
    selectedAt: at,
    promptedAt: at,
    respondedAt: at,
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
