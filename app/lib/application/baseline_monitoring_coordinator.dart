import 'dart:convert';

import 'package:power_manager/application/model_activation_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/energy/observation_comparison_service.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/baseline_monitoring.dart';
import 'package:power_manager/domain/learning/baseline_shadow_replay.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

enum BaselineMonitoringTrigger { settlement, coldStart, resumed, retry }

enum BaselineMonitoringSkipReason {
  noLearningActivation,
  noCurrentEpochEvidence,
  alreadySettled,
  learningSuspended,
  cooldownActive,
}

final class BaselineMonitoringReport {
  const BaselineMonitoringReport({
    required this.trigger,
    required this.createdRuns,
    required this.completedRuns,
    required this.suspended,
    required this.skipReason,
  });

  final BaselineMonitoringTrigger trigger;
  final int createdRuns;
  final int completedRuns;
  final bool suspended;
  final BaselineMonitoringSkipReason? skipReason;
}

abstract interface class BaselineMonitoringRequester {
  Future<BaselineMonitoringReport> request(BaselineMonitoringTrigger trigger);
}

/// Formal app provider uses the no-op implementation until the monitoring
/// configuration is explicitly enabled in a pre-production harness.
final class NoopBaselineMonitoringRequester
    implements BaselineMonitoringRequester {
  const NoopBaselineMonitoringRequester();

  @override
  Future<BaselineMonitoringReport> request(
    BaselineMonitoringTrigger trigger,
  ) async => BaselineMonitoringReport(
    trigger: trigger,
    createdRuns: 0,
    completedRuns: 0,
    suspended: false,
    skipReason: BaselineMonitoringSkipReason.noLearningActivation,
  );
}

final class BaselineMonitoringCoordinator
    implements BaselineMonitoringRequester {
  BaselineMonitoringCoordinator({
    required this.transactionRunner,
    required this.clock,
    required this.observations,
    required this.mornings,
    required this.summaries,
    required this.learningRuns,
    required this.versions,
    required this.settings,
    required this.modelActivationService,
    required this.config,
    this.evidenceBuilder = const ShadowEvidenceBuilder(),
    this.evaluator = const BaselineMonitoringEvaluator(),
    this.comparisonService = const ObservationComparisonService(),
    this.canonicalEncoder = const CanonicalJsonEncoder(),
    this.regimeKeyBuilder = const ModelRegimeKeyBuilder(),
  });

  final TransactionRunner transactionRunner;
  final Clock clock;
  final EnergyObservationsRepository observations;
  final MorningCheckInsRepository mornings;
  final DailySummariesRepository summaries;
  final LearningRunsRepository learningRuns;
  final PersonalizationVersionsRepository versions;
  final AppSettingsRepository settings;
  final ModelActivationService modelActivationService;
  final BaselineMonitoringConfig config;
  final ShadowEvidenceBuilder evidenceBuilder;
  final BaselineMonitoringEvaluator evaluator;
  final ObservationComparisonService comparisonService;
  final CanonicalJsonEncoder canonicalEncoder;
  final ModelRegimeKeyBuilder regimeKeyBuilder;

  @override
  Future<BaselineMonitoringReport> request(
    BaselineMonitoringTrigger trigger,
  ) async {
    if (!config.isValid) {
      return _report(
        trigger,
        skipReason: BaselineMonitoringSkipReason.noLearningActivation,
      );
    }
    final active = await versions.getActive();
    if (active.creationSource != PersonalizationCreationSource.learningRun ||
        active.parentVersionId == null ||
        active.sourceLearningRunId == null) {
      return _report(
        trigger,
        skipReason: BaselineMonitoringSkipReason.noLearningActivation,
      );
    }
    final parent = await versions.find(active.parentVersionId!);
    final sourceRun = await learningRuns.find(active.sourceLearningRunId!);
    if (parent == null ||
        sourceRun == null ||
        sourceRun.status != LearningRunStatus.completed ||
        sourceRun.result != LearningRunResult.candidate) {
      return _report(
        trigger,
        skipReason: BaselineMonitoringSkipReason.noLearningActivation,
      );
    }
    final appSettings = await settings.get();
    if (appSettings.baselineLearningSuspended) {
      return _report(
        trigger,
        skipReason: BaselineMonitoringSkipReason.learningSuspended,
      );
    }
    if (appSettings.baselineLearningCooldownUntil?.toUtc().isAfter(
          clock.now().toUtc(),
        ) ??
        false) {
      return _report(
        trigger,
        skipReason: BaselineMonitoringSkipReason.cooldownActive,
      );
    }

    final expectedDirection = active.baseEnergy < parent.baseEnergy
        ? BaselineReplayDirection.decrease
        : BaselineReplayDirection.increase;
    final evidence = await _currentEpochEvidence(active, appSettings);
    if (evidence == null) {
      return _report(
        trigger,
        skipReason: BaselineMonitoringSkipReason.noCurrentEpochEvidence,
      );
    }
    final monitorEvidence = evidence.reidentify(
      algorithmVersion: config.algorithmVersion,
      configVersion: config.configVersion,
      canonicalEncoder: canonicalEncoder,
    );
    final baselineMetrics = _baselineMetrics(sourceRun);
    if (baselineMetrics == null) {
      return _report(
        trigger,
        skipReason: BaselineMonitoringSkipReason.noLearningActivation,
      );
    }
    final evaluation = evaluator.evaluate(
      evidence: monitorEvidence,
      expectedDirection: expectedDirection,
      baselineAligned: baselineMetrics.aligned,
      baselineOrdinalError: baselineMetrics.ordinalError,
      config: config,
    );
    final id = deterministicLearningRunId(
      parameterFamily: LearningParameterFamily.baseline,
      sourceModelIdentity: monitorEvidence.sourceModelIdentity,
      algorithmVersion: config.algorithmVersion,
      configVersion: config.configVersion,
      evidenceHash: monitorEvidence.evidenceHash,
      canonicalEncoder: canonicalEncoder,
    );
    final existing = await learningRuns.findByIdempotency(
      parameterFamily: LearningParameterFamily.baseline,
      sourceModelIdentity: monitorEvidence.sourceModelIdentity,
      algorithmVersion: config.algorithmVersion,
      configVersion: config.configVersion,
      evidenceHash: monitorEvidence.evidenceHash,
    );
    if (existing?.status == LearningRunStatus.completed ||
        existing?.status == LearningRunStatus.terminalFailure) {
      return _report(
        trigger,
        skipReason: BaselineMonitoringSkipReason.alreadySettled,
      );
    }
    final run = LearningRun(
      id: existing?.id ?? id,
      parameterFamily: LearningParameterFamily.baseline,
      sourceModelIdentity: monitorEvidence.sourceModelIdentity,
      sourcePersonalizationVersionId: active.id,
      status: LearningRunStatus.completed,
      result: evaluation.result,
      evidenceSnapshotJson: monitorEvidence.evidenceSnapshotJson,
      evidenceHash: monitorEvidence.evidenceHash,
      evidenceHashVersion: canonicalEvidenceHashV1,
      algorithmVersion: config.algorithmVersion,
      configVersion: config.configVersion,
      currentValuesJson: monitorEvidence.currentValuesJson,
      candidateValuesJson: null,
      reasonCodesJson: canonicalEncoder.encode(evaluation.reasonCodes),
      triggeredAt: existing?.triggeredAt ?? clock.now().toUtc(),
      completedAt: clock.now().toUtc(),
    );
    await transactionRunner.run(() async {
      if (existing == null) {
        await learningRuns.insert(run);
      } else {
        await learningRuns.update(run);
      }
      if (evaluation.result == LearningRunResult.worsened) {
        await modelActivationService.suspendLearning(
          parameterFamily: LearningParameterFamily.baseline,
          learningRunId: run.id,
          reasonCode: evaluation.reasonCodes.first,
          at: clock.now(),
        );
      }
    });
    final suspended = evaluation.result == LearningRunResult.worsened;
    return BaselineMonitoringReport(
      trigger: trigger,
      createdRuns: existing == null ? 1 : 0,
      completedRuns: 1,
      suspended: suspended,
      skipReason: null,
    );
  }

  Future<ShadowEvidencePackage?> _currentEpochEvidence(
    PersonalizationVersion active,
    AppSettings appSettings,
  ) async {
    final all = await transactionRunner.run(() async {
      final observationItems = await observations.list();
      final morningItems = await mornings.list();
      final summaryItems = await summaries.list();
      return evidenceBuilder.buildAll(
        observations: observationItems,
        morningLifeDays: {for (final item in morningItems) item.lifeDay},
        settledLifeDays: {for (final item in summaryItems) item.lifeDay},
        config: ShadowLearningConfig.evidenceReadinessV1(),
      );
    });
    final keys = {
      for (final reference in ObservationReferenceType.values)
        regimeKeyBuilder.build(
          referenceType: reference,
          baseEnergy: active.baseEnergy,
          ruleVersion: appSettings.activeRuleVersion,
          comparisonBandVersion: mvpBComparisonBandV1,
          effectiveModelFingerprint: active.effectiveModelFingerprint,
          modelRegimeEpoch: active.modelRegimeEpoch,
        ),
    };
    return all
        .where((item) => keys.contains(item.sourceModelIdentity))
        .toList()
        .firstOrNull;
  }

  _BaselineMetrics? _baselineMetrics(LearningRun run) {
    try {
      final decoded = jsonDecode(run.evidenceSnapshotJson);
      if (decoded is! Map<String, Object?>) return null;
      final hashInput = decoded['hashInput'];
      if (hashInput is! Map<String, Object?>) return null;
      final selected = hashInput['selectedEligibleEvidence'];
      if (selected is! List<Object?> || selected.length != 14) return null;
      var aligned = 0;
      var ordinalError = 0;
      for (final raw in selected) {
        if (raw is! Map<String, Object?> ||
            raw['absoluteState'] is! String ||
            raw['estimateAtObservation'] is! int ||
            raw['initialEstimateAtObservation'] is! int) {
          return null;
        }
        final state = AbsoluteEnergyState.values.firstWhere(
          (item) => item.code == raw['absoluteState'],
          orElse: () => throw const FormatException('state'),
        );
        final comparison = comparisonService.compare(
          actualState: state,
          estimate: raw['estimateAtObservation']! as int,
          initialEstimate: raw['initialEstimateAtObservation']! as int,
        );
        if (!comparison.isValid) return null;
        if (comparison.direction == ObservationAlignmentDirection.aligned) {
          aligned++;
        }
        ordinalError += comparison.alignmentDelta!.abs();
      }
      return _BaselineMetrics(aligned: aligned, ordinalError: ordinalError);
    } on Object {
      return null;
    }
  }

  BaselineMonitoringReport _report(
    BaselineMonitoringTrigger trigger, {
    required BaselineMonitoringSkipReason skipReason,
  }) => BaselineMonitoringReport(
    trigger: trigger,
    createdRuns: 0,
    completedRuns: 0,
    suspended: false,
    skipReason: skipReason,
  );
}

final class _BaselineMetrics {
  const _BaselineMetrics({required this.aligned, required this.ordinalError});

  final int aligned;
  final int ordinalError;
}
