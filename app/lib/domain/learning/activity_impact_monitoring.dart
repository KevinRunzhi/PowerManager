import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/learning/activity_impact_contract.dart';
import 'package:power_manager/domain/learning/activity_impact_learner.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';

final class ActivityImpactMonitoringConfig {
  const ActivityImpactMonitoringConfig({
    this.policy = const ActivityImpactSamplingPolicyV1(),
    this.minimumSamples = 8,
    this.minimumCoverageDays = 4,
  });

  final ActivityImpactSamplingPolicyV1 policy;
  final int minimumSamples;
  final int minimumCoverageDays;
}

final class ActivityImpactMonitoringEvaluation {
  const ActivityImpactMonitoringEvaluation({
    required this.result,
    required this.reasonCodes,
    required this.evidenceSnapshotJson,
    required this.evidenceHash,
  });

  final LearningRunResult result;
  final List<String> reasonCodes;
  final String evidenceSnapshotJson;
  final String evidenceHash;
}

final class ActivityImpactMonitoringEvaluator {
  const ActivityImpactMonitoringEvaluator({
    this.encoder = const CanonicalJsonEncoder(),
  });

  final CanonicalJsonEncoder encoder;

  ActivityImpactMonitoringEvaluation evaluate({
    required Iterable<ActivityImpactLearningObservation> observations,
    required ActivityImpactLearningCurrentModel current,
    ActivityImpactMonitoringConfig config =
        const ActivityImpactMonitoringConfig(),
  }) {
    final accepted = observations.where((item) {
      final feedback = item.feedback;
      final activity = item.activity;
      return item.lifeDaySettled &&
          feedback.collectionSource ==
              ActivityFeedbackCollectionSource.sampledPrompt &&
          feedback.status == ActivityFeedbackStatus.active &&
          item.sample.status == ActivityFeedbackSampleStatus.responded &&
          feedback.personalizationVersionId ==
              current.personalizationVersionId &&
          activity.personalizationVersionId ==
              current.personalizationVersionId &&
          feedback.factorRegimeStartedLifeDay ==
              current.factorRegimeStartedLifeDay &&
          activity.factorRegimeStartedLifeDay ==
              current.factorRegimeStartedLifeDay;
    }).toList();
    final days = accepted.map((item) => item.feedback.lifeDay).toSet();
    final mismatches = accepted
        .where(
          (item) =>
              item.feedback.direction ==
              ActivityFeedbackDirection.directionMismatch,
        )
        .length;
    final mismatched =
        accepted.isNotEmpty &&
        mismatches >= config.policy.minimumDirectionMismatchCount &&
        mismatches / accepted.length >=
            config.policy.directionMismatchVetoRatio;
    final result = mismatched
        ? LearningRunResult.worsened
        : accepted.length < config.minimumSamples ||
              days.length < config.minimumCoverageDays
        ? LearningRunResult.insufficientEvidence
        : accepted
                  .where(
                    (item) =>
                        item.feedback.direction ==
                        ActivityFeedbackDirection.aboutRight,
                  )
                  .length >=
              (accepted.length * 0.75).ceil()
        ? LearningRunResult.improved
        : LearningRunResult.noChange;
    final reason = mismatched
        ? 'directionMismatchVeto'
        : result == LearningRunResult.insufficientEvidence
        ? 'minimumSampleOrDayNotMet'
        : result == LearningRunResult.improved
        ? 'stableAboutRightEvidence'
        : 'noMaterialChange';
    final snapshot = encoder.encode({
      'algorithmVersion': activityImpactMonitoringAlgorithmV1,
      'configVersion': activityImpactMonitoringConfigV1,
      'personalizationVersionId': current.personalizationVersionId,
      'factorRegimeStartedLifeDay': current.factorRegimeStartedLifeDay
          .toString(),
      'observationIds': [for (final item in accepted) item.feedback.id]..sort(),
      'result': result.code,
    });
    return ActivityImpactMonitoringEvaluation(
      result: result,
      reasonCodes: [reason],
      evidenceSnapshotJson: snapshot,
      evidenceHash: sha256.convert(utf8.encode(snapshot)).toString(),
    );
  }
}
