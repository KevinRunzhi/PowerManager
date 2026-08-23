import 'package:crypto/crypto.dart';
import 'package:power_manager/application/model_activation_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/drift_transaction_runner.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/activity_impact_contract.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

import '../data/db/test_database.dart';

const _gate = LearningProductionGate(
  baselineProductionLearningEnabled: false,
  activityImpactProductionLearningEnabled: true,
  automaticLearningEngineEnabled: true,
  supportedActivityImpactAlgorithms: {activityImpactLearningAlgorithmV1},
  supportedActivityImpactConfigs: {activityImpactLearningConfigV1},
);

void main() {
  test(
    'activity review preserves active factor until accepted activation',
    () async {
      final database = createTestDatabase(clock: const _TestClock());
      addTearDown(database.close);
      final settings = DriftAppSettingsRepository(database.appSettingsDao);
      final versions = DriftPersonalizationVersionsRepository(
        database.personalizationVersionsDao,
      );
      final runs = DriftLearningRunsRepository(database.learningRunsDao);
      final consents = DriftLearningConsentsRepository(
        database.learningConsentsDao,
      );
      final notices = DriftLearningNoticesRepository(
        database.learningNoticesDao,
      );
      final factors = DriftPersonalizationActivityFactorsRepository(
        database.personalizationActivityFactorsDao,
      );
      final service = ModelActivationService(
        transactionRunner: DriftTransactionRunner(database),
        settings: settings,
        versions: versions,
        learningRuns: runs,
        consents: consents,
        notices: notices,
        activityFactors: factors,
        productionGate: _gate,
      );
      final createdAt = DateTime.utc(2026, 8, 15, 8);
      await service.changeLearningMode(
        parameterFamily: LearningParameterFamily.activityImpact,
        mode: LearningMode.review,
        acceptCurrentDisclosure: true,
        at: createdAt,
      );
      final active = await versions.getActive();
      const encoder = CanonicalJsonEncoder();
      final currentValues = encoder.encode({
        'factors': {
          'selfStudyOrThesis|consumption': {'factorBps': 100},
        },
      });
      final candidateValues = encoder.encode({
        'factors': {
          'selfStudyOrThesis|consumption': {'factorBps': 105},
        },
      });
      final evidence = encoder.encode({
        'algorithmVersion': activityImpactSamplingAlgorithmV1,
        'currentFactorRegimeStartedLifeDay': '2026-08-15',
        'currentPersonalizationVersionId': active.id,
        'observations': [
          {
            'activityId': 'activity-1',
            'feedbackId': 'feedback-1',
            'sampleId': 'sample-1',
            'lifeDay': '2026-08-15',
            'subcategory': ActivitySubcategory.selfStudyOrThesis.code,
            'durationMinutes': DurationSlot.minutes30.minutes,
            'defaultTheoreticalDelta': -6,
            'factorBps': 100,
            'personalizedTheoreticalDelta': -6,
            'appliedDelta': -6,
            'impactSign': ActivityImpactSign.consumption.code,
            'direction': ActivityFeedbackDirection.aboutRight.code,
            'collectionSource':
                ActivityFeedbackCollectionSource.sampledPrompt.code,
            'samplingPolicyVersion': activityFeedbackSamplingPolicyV1,
            'sampleStatus': ActivityFeedbackSampleStatus.responded.code,
            'settled': true,
          },
        ],
        'policyVersion': activityFeedbackSamplingPolicyV1,
      });
      final run = LearningRun(
        id: deterministicLearningRunId(
          parameterFamily: LearningParameterFamily.activityImpact,
          sourceModelIdentity: active.id,
          algorithmVersion: activityImpactLearningAlgorithmV1,
          configVersion: activityImpactLearningConfigV1,
          evidenceHash: _hash(evidence),
        ),
        parameterFamily: LearningParameterFamily.activityImpact,
        sourceModelIdentity: active.id,
        sourcePersonalizationVersionId: active.id,
        status: LearningRunStatus.completed,
        result: LearningRunResult.candidate,
        evidenceSnapshotJson: evidence,
        evidenceHash: _hash(evidence),
        evidenceHashVersion: canonicalEvidenceHashV1,
        algorithmVersion: activityImpactLearningAlgorithmV1,
        configVersion: activityImpactLearningConfigV1,
        currentValuesJson: currentValues,
        candidateValuesJson: candidateValues,
        reasonCodesJson: '["sampleCount"]',
        triggeredAt: createdAt,
        completedAt: createdAt.add(const Duration(minutes: 1)),
      );
      await runs.insert(run);

      final candidate = await service.registerLearningCandidate(
        run: run,
        currentLifeDay: LifeDay(2026, 8, 15),
        atLocal: createdAt.add(const Duration(hours: 1)),
        ruleVersion: activityImpactSupportedRuleVersion,
      );
      expect(
        candidate.version.status,
        PersonalizationVersionStatus.awaitingReview,
      );
      expect(await factors.listForVersion(active.id), isEmpty);

      final scheduled = await service.acceptReviewCandidate(
        versionId: candidate.version.id,
        currentLifeDay: LifeDay(2026, 8, 15),
        effectiveLifeDay: LifeDay(2026, 8, 16),
        at: createdAt.add(const Duration(hours: 2)),
      );
      expect(scheduled.status, PersonalizationVersionStatus.scheduled);
      final scheduledFactor = (await factors.listForVersion(
        scheduled.id,
      )).single;
      expect(scheduledFactor.factor, 1.05);
      expect(scheduledFactor.factorRegimeStartedLifeDay, LifeDay(2026, 8, 16));

      final activation = await service.activateDue(
        currentLifeDay: LifeDay(2026, 8, 16),
        at: DateTime.utc(2026, 8, 16, 4),
      );
      expect(activation.activated, isTrue);
      expect((await versions.getActive()).id, scheduled.id);
    },
  );
}

String _hash(String value) => sha256.convert(value.codeUnits).toString();

final class _TestClock implements Clock {
  const _TestClock();

  @override
  DateTime now() => DateTime.utc(2026, 8, 15, 8);
}
