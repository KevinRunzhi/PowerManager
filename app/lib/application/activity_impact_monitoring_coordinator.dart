import 'package:power_manager/application/automatic_learning_coordinator.dart';
import 'package:power_manager/application/business_write_coordinator.dart';
import 'package:power_manager/application/model_activation_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/activity_impact_contract.dart';
import 'package:power_manager/domain/learning/activity_impact_learner.dart';
import 'package:power_manager/domain/learning/activity_impact_monitoring.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day_calculator.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

final class ActivityImpactMonitoringCoordinator {
  ActivityImpactMonitoringCoordinator({
    required this.writeCoordinator,
    required this.transactionRunner,
    required this.clock,
    required this.integrityVerifier,
    required this.activities,
    required this.feedback,
    required this.samples,
    required this.summaries,
    required this.factors,
    required this.versions,
    required this.learningRuns,
    required this.settings,
    required this.modelActivationService,
    required this.productionGate,
    this.evaluator = const ActivityImpactMonitoringEvaluator(),
    this.encoder = const CanonicalJsonEncoder(),
  });

  final BusinessWriteCoordinator writeCoordinator;
  final TransactionRunner transactionRunner;
  final Clock clock;
  final LearningIntegrityVerifier integrityVerifier;
  final ActivityRecordsRepository activities;
  final ActivityFeedbackRepository feedback;
  final ActivityFeedbackSamplesRepository samples;
  final DailySummariesRepository summaries;
  final PersonalizationActivityFactorsRepository factors;
  final PersonalizationVersionsRepository versions;
  final LearningRunsRepository learningRuns;
  final AppSettingsRepository settings;
  final ModelActivationService modelActivationService;
  final LearningProductionGate productionGate;
  final ActivityImpactMonitoringEvaluator evaluator;
  final CanonicalJsonEncoder encoder;

  Future<LearningRun?> request() {
    return writeCoordinator.run(() async {
      if (!productionGate.automaticLearningEngineEnabled ||
          !productionGate.activityImpactProductionLearningEnabled ||
          !await integrityVerifier.verify()) {
        return null;
      }
      final appSettings = await settings.get();
      if (appSettings.activityImpactLearningMode == LearningMode.off ||
          appSettings.activityImpactLearningSuspended ||
          _cooldownActive(appSettings) ||
          !const ActivityImpactSamplingPolicyV1().isValid) {
        return null;
      }
      // Monitoring is part of the same serial parameter-family lifecycle as
      // candidate generation.  Never evaluate old evidence while another
      // family has a pending version waiting for activation.
      if (await versions.findPending() != null) {
        return null;
      }
      final active = await versions.getActive();
      final settled = {for (final item in await summaries.list()) item.lifeDay};
      final activitiesById = {
        for (final item in await activities.listAllForExport()) item.id: item,
      };
      final feedbackById = {
        for (final item in await feedback.list()) item.id: item,
      };
      final samplesById = {
        for (final item in await samples.list()) item.id: item,
      };
      final observations = <ActivityImpactLearningObservation>[];
      for (final sample in samplesById.values) {
        if (sample.feedbackId == null ||
            sample.status != ActivityFeedbackSampleStatus.responded) {
          continue;
        }
        final activity = activitiesById[sample.activityRecordId];
        final item = feedbackById[sample.feedbackId!];
        if (activity != null && item != null) {
          observations.add(
            ActivityImpactLearningObservation(
              activity: activity,
              sample: sample,
              feedback: item,
              lifeDaySettled: settled.contains(item.lifeDay),
            ),
          );
        }
      }
      if (observations.isEmpty) {
        // Monitoring is evidence-driven too.  Avoid a zero-evidence run on
        // every settlement/restart trigger.
        return null;
      }
      final rows = await factors.listForVersion(active.id);
      final regime = rows.isEmpty
          ? active.effectiveLifeDay ??
                LifeDayCalculator().lifeDayFor(clock.now())
          : rows
                .map((item) => item.factorRegimeStartedLifeDay)
                .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
      final evaluation = evaluator.evaluate(
        observations: observations,
        current: ActivityImpactLearningCurrentModel(
          personalizationVersionId: active.id,
          factorRegimeStartedLifeDay: regime,
          factors: {
            for (final row in rows)
              ActivityImpactKey(
                subcategory: row.subcategory,
                impactSign: row.impactSign,
              ): row.factor,
          },
        ),
      );
      final id = deterministicLearningRunId(
        parameterFamily: LearningParameterFamily.activityImpact,
        sourceModelIdentity: active.id,
        algorithmVersion: activityImpactMonitoringAlgorithmV1,
        configVersion: activityImpactMonitoringConfigV1,
        evidenceHash: evaluation.evidenceHash,
        canonicalEncoder: encoder,
      );
      final existing = await learningRuns.findByIdempotency(
        parameterFamily: LearningParameterFamily.activityImpact,
        sourceModelIdentity: active.id,
        algorithmVersion: activityImpactMonitoringAlgorithmV1,
        configVersion: activityImpactMonitoringConfigV1,
        evidenceHash: evaluation.evidenceHash,
      );
      if (existing != null) return existing;
      final now = clock.now().toUtc();
      final run = LearningRun(
        id: id,
        parameterFamily: LearningParameterFamily.activityImpact,
        sourceModelIdentity: active.id,
        sourcePersonalizationVersionId: active.id,
        status: LearningRunStatus.completed,
        result: evaluation.result,
        evidenceSnapshotJson: evaluation.evidenceSnapshotJson,
        evidenceHash: evaluation.evidenceHash,
        evidenceHashVersion: canonicalEvidenceHashV1,
        algorithmVersion: activityImpactMonitoringAlgorithmV1,
        configVersion: activityImpactMonitoringConfigV1,
        currentValuesJson: encoder.encode({
          'factors': {
            for (final row in rows)
              ActivityImpactKey(
                subcategory: row.subcategory,
                impactSign: row.impactSign,
              ).value: {
                'factorBps': (row.factor * 100).round(),
              },
          },
        }),
        candidateValuesJson: null,
        reasonCodesJson: encoder.encode(evaluation.reasonCodes),
        triggeredAt: now,
        completedAt: now,
      );
      await transactionRunner.run(() => learningRuns.insert(run));
      if (run.result == LearningRunResult.worsened) {
        try {
          await modelActivationService.suspendLearning(
            parameterFamily: LearningParameterFamily.activityImpact,
            learningRunId: run.id,
            reasonCode: 'activityImpactMonitoringWorsened',
            at: now,
          );
        } on StateError {
          // Keep the monitoring run for audit; a retry can apply suspension.
        }
      }
      return run;
    });
  }

  bool _cooldownActive(AppSettings value) =>
      value.activityImpactLearningCooldownUntil?.toUtc().isAfter(
        clock.now().toUtc(),
      ) ??
      false;
}
