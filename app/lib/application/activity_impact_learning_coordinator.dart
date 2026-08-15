import 'package:power_manager/application/automatic_learning_coordinator.dart';
import 'package:power_manager/application/business_write_coordinator.dart';
import 'package:power_manager/application/model_activation_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/activity_impact_contract.dart';
import 'package:power_manager/domain/learning/activity_impact_learner.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day_calculator.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

/// Production-bound activity-impact coordinator.  The learner remains pure;
/// this class owns evidence joining, idempotent run persistence, gate checks,
/// and hand-off to the shared personalization lifecycle.
final class ActivityImpactLearningCoordinator
    implements AutomaticLearningRequester {
  ActivityImpactLearningCoordinator({
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
    this.learner = const ActivityImpactLearner(),
    this.canonicalEncoder = const CanonicalJsonEncoder(),
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
  final ActivityImpactLearner learner;
  final CanonicalJsonEncoder canonicalEncoder;

  @override
  Future<LearningCoordinationReport> request(AutomaticLearningTrigger trigger) {
    return writeCoordinator.run(() async {
      if (!await integrityVerifier.verify()) {
        return _report(
          trigger,
          LearningCoordinationSkipReason.integrityGateFailed,
        );
      }
      if (!productionGate.automaticLearningEngineEnabled ||
          !productionGate.activityImpactProductionLearningEnabled ||
          !productionGate.supportedActivityImpactAlgorithms.contains(
            activityImpactLearningAlgorithmV1,
          ) ||
          !productionGate.supportedActivityImpactConfigs.contains(
            activityImpactLearningConfigV1,
          )) {
        return _report(
          trigger,
          LearningCoordinationSkipReason.unchangedEvidence,
        );
      }
      final currentSettings = await settings.get();
      if (currentSettings.activityImpactLearningMode == LearningMode.off ||
          currentSettings.activityImpactLearningSuspended ||
          _cooldownActive(currentSettings) ||
          currentSettings.activeRuleVersion !=
              activityImpactSupportedRuleVersion ||
          !const ActivityImpactSamplingPolicyV1().isValid) {
        return _report(
          trigger,
          LearningCoordinationSkipReason.unchangedEvidence,
        );
      }
      final pending = await versions.findPending();
      if (pending != null) {
        // A pending baseline change has priority.  The shared pending slot is
        // also the final defense against cross-family races.
        return _report(
          trigger,
          pending.changedParameterFamily.parameterFamily ==
                  LearningParameterFamily.activityImpact
              ? LearningCoordinationSkipReason.unchangedEvidence
              : LearningCoordinationSkipReason.blockedByOtherParameterFamily,
        );
      }
      final active = await versions.getActive();
      final settled = {
        for (final summary in await summaries.list()) summary.lifeDay,
      };
      final activityById = {
        for (final activity in await activities.listAllForExport())
          activity.id: activity,
      };
      final feedbackById = {
        for (final item in await feedback.list()) item.id: item,
      };
      final samplesById = {
        for (final item in await samples.list()) item.id: item,
      };
      final observations = <ActivityImpactLearningObservation>[];
      for (final sample in samplesById.values) {
        if (sample.status != ActivityFeedbackSampleStatus.responded ||
            sample.feedbackId == null) {
          continue;
        }
        final activity = activityById[sample.activityRecordId];
        final item = feedbackById[sample.feedbackId!];
        if (activity == null || item == null) continue;
        observations.add(
          ActivityImpactLearningObservation(
            activity: activity,
            sample: sample,
            feedback: item,
            lifeDaySettled: settled.contains(item.lifeDay),
          ),
        );
      }
      if (observations.isEmpty) {
        // A trigger without a responded sample is not new learning evidence.
        // Do not create an auditable run whose only purpose is to say that
        // nothing happened; the next response should be the idempotency key.
        return _report(
          trigger,
          LearningCoordinationSkipReason.noSettledEvidence,
        );
      }
      final factorRows = await factors.listForVersion(active.id);
      final factorMap = {
        for (final row in factorRows)
          ActivityImpactKey(
            subcategory: row.subcategory,
            impactSign: row.impactSign,
          ): row.factor,
      };
      final regime = factorRows.isEmpty
          ? LifeDayCalculator().lifeDayFor(clock.now())
          : factorRows
                .map((row) => row.factorRegimeStartedLifeDay)
                .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
      final evaluation = learner.evaluate(
        observations: observations,
        current: ActivityImpactLearningCurrentModel(
          personalizationVersionId: active.id,
          factorRegimeStartedLifeDay: regime,
          factors: factorMap,
        ),
        config: ActivityImpactLearningConfig(
          mode: currentSettings.activityImpactLearningMode,
          productionLearningEnabled:
              productionGate.activityImpactProductionLearningEnabled,
          automaticLearningEngineEnabled:
              productionGate.automaticLearningEngineEnabled,
          automaticApplyEnabled: productionGate.activityImpactAutoApplyEnabled,
        ),
      );
      final runOutcome = await _completeRun(
        active: active,
        evaluation: evaluation,
        triggeredAt: clock.now().toUtc(),
      );
      if (evaluation.result == LearningRunResult.candidate) {
        try {
          await modelActivationService.registerLearningCandidate(
            run: runOutcome.run,
            currentLifeDay: LifeDayCalculator().lifeDayFor(clock.now()),
            atLocal: clock.now(),
            // Activity factors are governed by the activity-rule contract,
            // not the energy-rule setting stored on AppSettings.
            ruleVersion: activityImpactSupportedRuleVersion,
          );
        } on StateError {
          // The run is an immutable audit record; a later trigger may retry
          // candidate registration against the current parent model.
        }
      }
      return LearningCoordinationReport(
        trigger: trigger,
        createdRuns: runOutcome.created ? 1 : 0,
        resumedRuns: 0,
        completedRuns: runOutcome.created ? 1 : 0,
        retryableFailures: 0,
        terminalFailures: 0,
        skipReason: null,
      );
    });
  }

  Future<_ActivityRunOutcome> _completeRun({
    required PersonalizationVersion active,
    required ActivityImpactLearningEvaluation evaluation,
    required DateTime triggeredAt,
  }) async {
    final id = deterministicLearningRunId(
      parameterFamily: LearningParameterFamily.activityImpact,
      sourceModelIdentity: active.id,
      algorithmVersion: activityImpactLearningAlgorithmV1,
      configVersion: activityImpactLearningConfigV1,
      evidenceHash: evaluation.evidenceHash,
      canonicalEncoder: canonicalEncoder,
    );
    final existing = await learningRuns.findByIdempotency(
      parameterFamily: LearningParameterFamily.activityImpact,
      sourceModelIdentity: active.id,
      algorithmVersion: activityImpactLearningAlgorithmV1,
      configVersion: activityImpactLearningConfigV1,
      evidenceHash: evaluation.evidenceHash,
    );
    if (existing != null) {
      return _ActivityRunOutcome(run: existing, created: false);
    }
    final pending = LearningRun(
      id: id,
      parameterFamily: LearningParameterFamily.activityImpact,
      sourceModelIdentity: active.id,
      sourcePersonalizationVersionId: active.id,
      status: LearningRunStatus.pending,
      result: null,
      evidenceSnapshotJson: evaluation.evidenceSnapshotJson,
      evidenceHash: evaluation.evidenceHash,
      evidenceHashVersion: canonicalEvidenceHashV1,
      algorithmVersion: activityImpactLearningAlgorithmV1,
      configVersion: activityImpactLearningConfigV1,
      currentValuesJson: evaluation.currentValuesJson,
      candidateValuesJson: null,
      reasonCodesJson: '[]',
      triggeredAt: triggeredAt,
      completedAt: null,
    );
    await transactionRunner.run(() => learningRuns.insert(pending));
    final running = _transition(
      pending,
      status: LearningRunStatus.running,
      result: null,
      candidateValuesJson: null,
      reasonCodes: const [],
      completedAt: null,
    );
    await transactionRunner.run(() => learningRuns.update(running));
    final completed = _transition(
      running,
      status: LearningRunStatus.completed,
      result: evaluation.result,
      candidateValuesJson: evaluation.candidateValuesJson,
      reasonCodes: evaluation.reasonCodes,
      completedAt: _completionTime(running),
    );
    await transactionRunner.run(() => learningRuns.update(completed));
    return _ActivityRunOutcome(run: completed, created: true);
  }

  LearningRun _transition(
    LearningRun run, {
    required LearningRunStatus status,
    required LearningRunResult? result,
    required String? candidateValuesJson,
    required List<String> reasonCodes,
    required DateTime? completedAt,
  }) => LearningRun(
    id: run.id,
    parameterFamily: run.parameterFamily,
    sourceModelIdentity: run.sourceModelIdentity,
    sourcePersonalizationVersionId: run.sourcePersonalizationVersionId,
    status: status,
    result: result,
    evidenceSnapshotJson: run.evidenceSnapshotJson,
    evidenceHash: run.evidenceHash,
    evidenceHashVersion: run.evidenceHashVersion,
    algorithmVersion: run.algorithmVersion,
    configVersion: run.configVersion,
    currentValuesJson: run.currentValuesJson,
    candidateValuesJson: candidateValuesJson,
    reasonCodesJson: canonicalEncoder.encode(reasonCodes),
    triggeredAt: run.triggeredAt,
    completedAt: completedAt?.toUtc(),
  );

  bool _cooldownActive(AppSettings value) =>
      value.activityImpactLearningCooldownUntil?.toUtc().isAfter(
        clock.now().toUtc(),
      ) ??
      false;

  DateTime _completionTime(LearningRun run) {
    final now = clock.now().toUtc();
    return now.isBefore(run.triggeredAt) ? run.triggeredAt : now;
  }

  LearningCoordinationReport _report(
    AutomaticLearningTrigger trigger,
    LearningCoordinationSkipReason reason,
  ) => LearningCoordinationReport(
    trigger: trigger,
    createdRuns: 0,
    resumedRuns: 0,
    completedRuns: 0,
    retryableFailures: 0,
    terminalFailures: 0,
    skipReason: reason,
  );
}

final class _ActivityRunOutcome {
  const _ActivityRunOutcome({required this.run, required this.created});

  final LearningRun run;
  final bool created;
}

final class CombinedAutomaticLearningRequester
    implements AutomaticLearningRequester {
  const CombinedAutomaticLearningRequester({required this.requesters});

  final List<AutomaticLearningRequester> requesters;

  @override
  Future<LearningCoordinationReport> request(
    AutomaticLearningTrigger trigger,
  ) async {
    final reports = <LearningCoordinationReport>[];
    for (final requester in requesters) {
      reports.add(await requester.request(trigger));
    }
    if (reports.isEmpty) {
      return LearningCoordinationReport(
        trigger: trigger,
        createdRuns: 0,
        resumedRuns: 0,
        completedRuns: 0,
        retryableFailures: 0,
        terminalFailures: 0,
        skipReason: LearningCoordinationSkipReason.unchangedEvidence,
      );
    }
    final changed = reports.any(
      (report) =>
          report.createdRuns > 0 ||
          report.resumedRuns > 0 ||
          report.completedRuns > 0 ||
          report.retryableFailures > 0 ||
          report.terminalFailures > 0,
    );
    final skipReason = changed
        ? null
        : reports
              .map((report) => report.skipReason)
              .whereType<LearningCoordinationSkipReason>()
              .firstWhere(
                (reason) =>
                    reason != LearningCoordinationSkipReason.unchangedEvidence,
                orElse: () => LearningCoordinationSkipReason.unchangedEvidence,
              );
    return LearningCoordinationReport(
      trigger: trigger,
      createdRuns: reports.fold(0, (sum, item) => sum + item.createdRuns),
      resumedRuns: reports.fold(0, (sum, item) => sum + item.resumedRuns),
      completedRuns: reports.fold(0, (sum, item) => sum + item.completedRuns),
      retryableFailures: reports.fold(
        0,
        (sum, item) => sum + item.retryableFailures,
      ),
      terminalFailures: reports.fold(
        0,
        (sum, item) => sum + item.terminalFailures,
      ),
      skipReason: skipReason,
    );
  }
}
