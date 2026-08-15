import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/business_write_coordinator.dart';
import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/application/model_activation_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/baseline_shadow_replay.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/baseline_production_learner.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/life_day/life_day_calculator.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

enum AutomaticLearningTrigger {
  settlement,
  coldStart,
  resumed,
  safeRestore,
  retry,
}

enum LearningCoordinationSkipReason {
  integrityGateFailed,
  noSettledEvidence,
  blockedByOtherParameterFamily,
  unchangedEvidence,
}

final class LearningCoordinationReport {
  const LearningCoordinationReport({
    required this.trigger,
    required this.createdRuns,
    required this.resumedRuns,
    required this.completedRuns,
    required this.retryableFailures,
    required this.terminalFailures,
    required this.skipReason,
  });

  final AutomaticLearningTrigger trigger;
  final int createdRuns;
  final int resumedRuns;
  final int completedRuns;
  final int retryableFailures;
  final int terminalFailures;
  final LearningCoordinationSkipReason? skipReason;
}

abstract interface class AutomaticLearningRequester {
  Future<LearningCoordinationReport> request(AutomaticLearningTrigger trigger);
}

abstract interface class LearningIntegrityVerifier {
  Future<bool> verify();
}

final class BackupRoundTripLearningIntegrityVerifier
    implements LearningIntegrityVerifier {
  const BackupRoundTripLearningIntegrityVerifier({
    required this.exportService,
    required this.codec,
    required this.clock,
  });

  final JsonExporter exportService;
  final JsonBackupCodec codec;
  final Clock clock;

  @override
  Future<bool> verify() async {
    try {
      final exported = await exportService.create(exportedAt: clock.now());
      codec.inspect(
        fileName: exported.fileName,
        bytes: Uint8List.fromList(utf8.encode(exported.contents)),
      );
      return true;
    } on BackupFormatException {
      return false;
    } on Object {
      return false;
    }
  }
}

final class RetryableShadowLearningException implements Exception {
  const RetryableShadowLearningException();
}

final class TerminalShadowLearningException implements Exception {
  const TerminalShadowLearningException();
}

final class AutomaticLearningCoordinator implements AutomaticLearningRequester {
  AutomaticLearningCoordinator({
    required this.writeCoordinator,
    required this.transactionRunner,
    required this.clock,
    required this.integrityVerifier,
    required this.observations,
    required this.mornings,
    required this.summaries,
    required this.learningRuns,
    ShadowLearningConfig? config,
    this.evidenceBuilder = const ShadowEvidenceBuilder(),
    this.evaluator = const BaselineShadowLearner(),
    this.productionLearner = const BaselineProductionLearner(),
    this.productionGate,
    this.productionConfig,
    this.modelActivationService,
    this.personalizationVersions,
    this.appSettings,
    this.canonicalEncoder = const CanonicalJsonEncoder(),
  }) : config = config ?? ShadowLearningConfig.evidenceReadinessV1();

  final BusinessWriteCoordinator writeCoordinator;
  final TransactionRunner transactionRunner;
  final Clock clock;
  final LearningIntegrityVerifier integrityVerifier;
  final EnergyObservationsRepository observations;
  final MorningCheckInsRepository mornings;
  final DailySummariesRepository summaries;
  final LearningRunsRepository learningRuns;
  final ShadowLearningConfig config;
  final ShadowEvidenceBuilder evidenceBuilder;
  final ShadowLearningEvaluator evaluator;
  final BaselineProductionLearner productionLearner;
  final CanonicalJsonEncoder canonicalEncoder;

  /// Optional B2-1 dependencies. They are absent for the B1 shadow-only
  /// coordinator and are supplied only by an explicitly configured
  /// pre-production harness or a future released production provider.
  final LearningProductionGate? productionGate;
  final BaselineProductionConfig? productionConfig;
  final ModelActivationService? modelActivationService;
  final PersonalizationVersionsRepository? personalizationVersions;
  final AppSettingsRepository? appSettings;

  @override
  Future<LearningCoordinationReport> request(AutomaticLearningTrigger trigger) {
    return writeCoordinator.run(() async {
      if (!await integrityVerifier.verify()) {
        return _emptyReport(
          trigger,
          skipReason: LearningCoordinationSkipReason.integrityGateFailed,
        );
      }
      final evidence = await transactionRunner.run(() async {
        final observationItems = await observations.list();
        final morningItems = await mornings.list();
        final summaryItems = await summaries.list();
        return evidenceBuilder.buildAll(
          observations: observationItems,
          morningLifeDays: {for (final item in morningItems) item.lifeDay},
          settledLifeDays: {for (final item in summaryItems) item.lifeDay},
          config: config,
        );
      });
      if (evidence.isEmpty) {
        return _emptyReport(
          trigger,
          skipReason: LearningCoordinationSkipReason.noSettledEvidence,
        );
      }

      var created = 0;
      var resumed = 0;
      var completed = 0;
      var retryable = 0;
      var terminal = 0;
      for (final package in evidence) {
        final outcome = await _process(package);
        created += outcome.created ? 1 : 0;
        resumed += outcome.resumed ? 1 : 0;
        completed += outcome.completed ? 1 : 0;
        retryable += outcome.retryableFailure ? 1 : 0;
        terminal += outcome.terminalFailure ? 1 : 0;
        if (_hasProductionDependencies) {
          final production = await _processProduction(package);
          created += production.created ? 1 : 0;
          resumed += production.resumed ? 1 : 0;
          completed += production.completed ? 1 : 0;
          retryable += production.retryableFailure ? 1 : 0;
          terminal += production.terminalFailure ? 1 : 0;
        }
      }
      final unchanged =
          created == 0 &&
          resumed == 0 &&
          completed == 0 &&
          retryable == 0 &&
          terminal == 0;
      return LearningCoordinationReport(
        trigger: trigger,
        createdRuns: created,
        resumedRuns: resumed,
        completedRuns: completed,
        retryableFailures: retryable,
        terminalFailures: terminal,
        skipReason: unchanged
            ? LearningCoordinationSkipReason.unchangedEvidence
            : null,
      );
    });
  }

  bool get _hasProductionDependencies =>
      productionGate != null &&
      productionConfig != null &&
      modelActivationService != null &&
      personalizationVersions != null &&
      appSettings != null;

  Future<_RunOutcome> _process(ShadowEvidencePackage evidence) async {
    final id = deterministicLearningRunId(
      parameterFamily: LearningParameterFamily.baseline,
      sourceModelIdentity: evidence.sourceModelIdentity,
      algorithmVersion: config.algorithmVersion,
      configVersion: config.configVersion,
      evidenceHash: evidence.evidenceHash,
      canonicalEncoder: canonicalEncoder,
    );
    LearningRun? run = await transactionRunner.run(
      () => learningRuns.findByIdempotency(
        parameterFamily: LearningParameterFamily.baseline,
        sourceModelIdentity: evidence.sourceModelIdentity,
        algorithmVersion: config.algorithmVersion,
        configVersion: config.configVersion,
        evidenceHash: evidence.evidenceHash,
      ),
    );
    if (run?.status == LearningRunStatus.completed ||
        run?.status == LearningRunStatus.terminalFailure) {
      return const _RunOutcome();
    }

    var created = false;
    var resumed = run != null;
    if (run == null) {
      final triggeredAt = clock.now().toUtc();
      run = LearningRun(
        id: id,
        parameterFamily: LearningParameterFamily.baseline,
        sourceModelIdentity: evidence.sourceModelIdentity,
        sourcePersonalizationVersionId: null,
        status: LearningRunStatus.pending,
        result: null,
        evidenceSnapshotJson: evidence.evidenceSnapshotJson,
        evidenceHash: evidence.evidenceHash,
        evidenceHashVersion: config.evidenceHashVersion,
        algorithmVersion: config.algorithmVersion,
        configVersion: config.configVersion,
        currentValuesJson: evidence.currentValuesJson,
        candidateValuesJson: null,
        reasonCodesJson: '[]',
        triggeredAt: triggeredAt,
        completedAt: null,
      );
      try {
        await transactionRunner.run(() => learningRuns.insert(run!));
        created = true;
        resumed = false;
      } catch (_) {
        final existing = await transactionRunner.run(
          () => learningRuns.findByIdempotency(
            parameterFamily: LearningParameterFamily.baseline,
            sourceModelIdentity: evidence.sourceModelIdentity,
            algorithmVersion: config.algorithmVersion,
            configVersion: config.configVersion,
            evidenceHash: evidence.evidenceHash,
          ),
        );
        if (existing == null) {
          return const _RunOutcome(retryableFailure: true);
        }
        run = existing;
        resumed = true;
        if (run.status == LearningRunStatus.completed ||
            run.status == LearningRunStatus.terminalFailure) {
          return const _RunOutcome();
        }
      }
    }

    if (!_matchesEvidence(run, evidence)) {
      final terminal = _transition(
        run,
        status: LearningRunStatus.terminalFailure,
        result: null,
        reasonCodes: const ['persistedRunMismatch'],
        completedAt: _completionTime(run),
      );
      try {
        await transactionRunner.run(() => learningRuns.update(terminal));
      } catch (_) {
        return _RunOutcome(created: created, retryableFailure: true);
      }
      return _RunOutcome(
        created: created,
        resumed: resumed,
        terminalFailure: true,
      );
    }

    if (run.status != LearningRunStatus.running) {
      run = _transition(
        run,
        status: LearningRunStatus.running,
        result: null,
        reasonCodes: const [],
        completedAt: null,
      );
      try {
        await transactionRunner.run(() => learningRuns.update(run!));
      } catch (_) {
        return _RunOutcome(
          created: created,
          resumed: resumed,
          retryableFailure: true,
        );
      }
    }

    final ShadowLearningEvaluation evaluation;
    try {
      evaluation = evaluator.evaluate(evidence: evidence, config: config);
    } on RetryableShadowLearningException {
      await _markFailure(
        run,
        status: LearningRunStatus.retryableFailure,
        reasonCode: 'retryableLearningFailure',
      );
      return _RunOutcome(
        created: created,
        resumed: resumed,
        retryableFailure: true,
      );
    } on TerminalShadowLearningException {
      final marked = await _markFailure(
        run,
        status: LearningRunStatus.terminalFailure,
        reasonCode: 'deterministicEvidenceFailure',
      );
      return _RunOutcome(
        created: created,
        resumed: resumed,
        retryableFailure: !marked,
        terminalFailure: marked,
      );
    } on Object {
      final marked = await _markFailure(
        run,
        status: LearningRunStatus.terminalFailure,
        reasonCode: 'deterministicEvidenceFailure',
      );
      return _RunOutcome(
        created: created,
        resumed: resumed,
        retryableFailure: !marked,
        terminalFailure: marked,
      );
    }

    final completedRun = _transition(
      run,
      status: LearningRunStatus.completed,
      result: evaluation.result,
      reasonCodes: [for (final reason in evaluation.reasonCodes) reason.code],
      completedAt: _completionTime(run),
    );
    try {
      await transactionRunner.run(() => learningRuns.update(completedRun));
      return _RunOutcome(created: created, resumed: resumed, completed: true);
    } on Object {
      await _markFailure(
        run,
        status: LearningRunStatus.retryableFailure,
        reasonCode: 'retryableLearningFailure',
      );
      return _RunOutcome(
        created: created,
        resumed: resumed,
        retryableFailure: true,
        terminalFailure: false,
      );
    }
  }

  Future<_RunOutcome> _processProduction(ShadowEvidencePackage shadow) async {
    final gate = productionGate!;
    final productionConfig = this.productionConfig!;
    final settings = await appSettings!.get();
    final mode = settings.baselineLearningMode;
    // The off mode is an explicit user choice: do not create a new production
    // run, while preserving the existing B1 shadow run for audit continuity.
    if (mode == LearningMode.off) return const _RunOutcome();

    final active = await personalizationVersions!.getActive();
    final evidence = shadow.reidentify(
      algorithmVersion: productionConfig.algorithmVersion,
      configVersion: productionConfig.configVersion,
      canonicalEncoder: canonicalEncoder,
    );
    final id = deterministicLearningRunId(
      parameterFamily: LearningParameterFamily.baseline,
      sourceModelIdentity: evidence.sourceModelIdentity,
      algorithmVersion: productionConfig.algorithmVersion,
      configVersion: productionConfig.configVersion,
      evidenceHash: evidence.evidenceHash,
      canonicalEncoder: canonicalEncoder,
    );

    LearningRun? run = await transactionRunner.run(
      () => learningRuns.findByIdempotency(
        parameterFamily: LearningParameterFamily.baseline,
        sourceModelIdentity: evidence.sourceModelIdentity,
        algorithmVersion: productionConfig.algorithmVersion,
        configVersion: productionConfig.configVersion,
        evidenceHash: evidence.evidenceHash,
      ),
    );
    if (run case final completed?
        when completed.status == LearningRunStatus.completed) {
      if (completed.result == LearningRunResult.candidate) {
        await _ensureCandidate(
          completed,
          active: active,
          currentLifeDay: _currentLifeDay(),
        );
      }
      return const _RunOutcome();
    }
    if (run?.status == LearningRunStatus.terminalFailure) {
      return const _RunOutcome();
    }

    var created = false;
    var resumed = run != null;
    if (run == null) {
      run = LearningRun(
        id: id,
        parameterFamily: LearningParameterFamily.baseline,
        sourceModelIdentity: evidence.sourceModelIdentity,
        sourcePersonalizationVersionId: active.id,
        status: LearningRunStatus.pending,
        result: null,
        evidenceSnapshotJson: evidence.evidenceSnapshotJson,
        evidenceHash: evidence.evidenceHash,
        evidenceHashVersion: canonicalEvidenceHashV1,
        algorithmVersion: productionConfig.algorithmVersion,
        configVersion: productionConfig.configVersion,
        currentValuesJson: evidence.currentValuesJson,
        candidateValuesJson: null,
        reasonCodesJson: '[]',
        triggeredAt: clock.now().toUtc(),
        completedAt: null,
      );
      try {
        final pendingRun = run;
        await transactionRunner.run(() => learningRuns.insert(pendingRun));
        created = true;
        resumed = false;
      } catch (_) {
        final existing = await transactionRunner.run(
          () => learningRuns.findByIdempotency(
            parameterFamily: LearningParameterFamily.baseline,
            sourceModelIdentity: evidence.sourceModelIdentity,
            algorithmVersion: productionConfig.algorithmVersion,
            configVersion: productionConfig.configVersion,
            evidenceHash: evidence.evidenceHash,
          ),
        );
        if (existing == null) return const _RunOutcome(retryableFailure: true);
        run = existing;
        resumed = true;
        if (run.status == LearningRunStatus.completed ||
            run.status == LearningRunStatus.terminalFailure) {
          return const _RunOutcome();
        }
      }
    }
    if (run.sourcePersonalizationVersionId != active.id ||
        run.evidenceHash != evidence.evidenceHash ||
        run.currentValuesJson != evidence.currentValuesJson) {
      final failed = _productionTransition(
        run,
        status: LearningRunStatus.terminalFailure,
        result: null,
        candidateValuesJson: null,
        reasonCodes: const ['persistedRunMismatch'],
        completedAt: _completionTime(run),
      );
      try {
        await transactionRunner.run(() => learningRuns.update(failed));
      } catch (_) {
        return _RunOutcome(
          created: created,
          resumed: resumed,
          retryableFailure: true,
        );
      }
      return _RunOutcome(
        created: created,
        resumed: resumed,
        terminalFailure: true,
      );
    }
    if (run.status != LearningRunStatus.running) {
      run = _productionTransition(
        run,
        status: LearningRunStatus.running,
        result: null,
        candidateValuesJson: null,
        reasonCodes: const [],
        completedAt: null,
      );
      try {
        await transactionRunner.run(() => learningRuns.update(run!));
      } catch (_) {
        return _RunOutcome(
          created: created,
          resumed: resumed,
          retryableFailure: true,
        );
      }
    }

    final evaluation = _evaluateProduction(
      shadow: shadow,
      evidence: evidence,
      active: active,
      settings: settings,
      mode: mode,
      gate: gate,
      config: productionConfig,
    );
    final completedRun = _productionTransition(
      run,
      status: LearningRunStatus.completed,
      result: evaluation.result,
      candidateValuesJson: evaluation.candidateValuesJson,
      reasonCodes: evaluation.reasonCodes.isEmpty
          ? const ['configurationBlocked']
          : evaluation.reasonCodes,
      completedAt: _completionTime(run),
    );
    try {
      await transactionRunner.run(() => learningRuns.update(completedRun));
    } catch (_) {
      return _RunOutcome(
        created: created,
        resumed: resumed,
        retryableFailure: true,
      );
    }
    if (evaluation.result == LearningRunResult.candidate) {
      await _ensureCandidate(
        completedRun,
        active: active,
        currentLifeDay: _currentLifeDay(),
      );
    }
    return _RunOutcome(created: created, resumed: resumed, completed: true);
  }

  BaselineProductionEvaluation _evaluateProduction({
    required ShadowEvidencePackage shadow,
    required ShadowEvidencePackage evidence,
    required PersonalizationVersion active,
    required AppSettings settings,
    required LearningMode mode,
    required LearningProductionGate gate,
    required BaselineProductionConfig config,
  }) {
    String blocked(String reason) => reason;
    final blockedReason = !gate.automaticLearningEngineEnabled
        ? blocked('automaticLearningEngineDisabled')
        : !gate.baselineProductionLearningEnabled
        ? blocked('productionGateClosed')
        : !gate.supportedBaselineAlgorithms.contains(config.algorithmVersion) ||
              !gate.supportedBaselineConfigs.contains(config.configVersion)
        ? blocked('unsupportedProductionConfiguration')
        : !config.isValid
        ? blocked('invalidProductionConfiguration')
        : settings.baselineLearningSuspended
        ? blocked('learningSuspended')
        : (settings.baselineLearningCooldownUntil?.toUtc().isAfter(
                clock.now().toUtc(),
              ) ??
              false)
        ? blocked('learningCooldownActive')
        : mode == LearningMode.automatic && !gate.baselineAutoApplyEnabled
        ? blocked('automaticApplyDisabled')
        : null;
    if (blockedReason != null) {
      return BaselineProductionEvaluation(
        result: LearningRunResult.configurationBlocked,
        reasonCodes: [blockedReason],
        evidence: evidence,
      );
    }
    return productionLearner.evaluate(
      shadowEvidence: shadow,
      baselineAnchorEnergy: active.baselineAnchorEnergy,
      mode: mode == LearningMode.automatic
          ? BaselineReplayMode.automatic
          : BaselineReplayMode.review,
      config: config,
    );
  }

  Future<void> _ensureCandidate(
    LearningRun run, {
    required PersonalizationVersion active,
    required LifeDay currentLifeDay,
  }) async {
    try {
      await modelActivationService!.registerLearningCandidate(
        run: run,
        currentLifeDay: currentLifeDay,
        atLocal: clock.now(),
        ruleVersion: (await appSettings!.get()).activeRuleVersion,
      );
    } on StateError {
      // A changed parent, pending model, cooldown or notice failure is
      // fail-closed. The completed run remains an immutable audit record and
      // a later evidence trigger can retry against the current model.
    }
  }

  LifeDay _currentLifeDay() => LifeDayCalculator().lifeDayFor(clock.now());

  LearningRun _productionTransition(
    LearningRun run, {
    required LearningRunStatus status,
    required LearningRunResult? result,
    required String? candidateValuesJson,
    required List<String> reasonCodes,
    required DateTime? completedAt,
  }) {
    return LearningRun(
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
  }

  bool _matchesEvidence(LearningRun run, ShadowEvidencePackage evidence) {
    return run.id ==
            deterministicLearningRunId(
              parameterFamily: LearningParameterFamily.baseline,
              sourceModelIdentity: evidence.sourceModelIdentity,
              algorithmVersion: config.algorithmVersion,
              configVersion: config.configVersion,
              evidenceHash: evidence.evidenceHash,
              canonicalEncoder: canonicalEncoder,
            ) &&
        run.parameterFamily == LearningParameterFamily.baseline &&
        run.sourceModelIdentity == evidence.sourceModelIdentity &&
        run.sourcePersonalizationVersionId == null &&
        run.evidenceHash == evidence.evidenceHash &&
        run.evidenceHashVersion == config.evidenceHashVersion &&
        run.algorithmVersion == config.algorithmVersion &&
        run.configVersion == config.configVersion &&
        run.currentValuesJson == evidence.currentValuesJson &&
        run.candidateValuesJson == null;
  }

  Future<bool> _markFailure(
    LearningRun run, {
    required LearningRunStatus status,
    required String reasonCode,
  }) async {
    try {
      await transactionRunner.run(
        () => learningRuns.update(
          _transition(
            run,
            status: status,
            result: null,
            reasonCodes: [reasonCode],
            completedAt: _completionTime(run),
          ),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  LearningRun _transition(
    LearningRun run, {
    required LearningRunStatus status,
    required LearningRunResult? result,
    required List<String> reasonCodes,
    required DateTime? completedAt,
  }) {
    return LearningRun(
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
      candidateValuesJson: null,
      reasonCodesJson: canonicalEncoder.encode(reasonCodes),
      triggeredAt: run.triggeredAt,
      completedAt: completedAt?.toUtc(),
    );
  }

  LearningCoordinationReport _emptyReport(
    AutomaticLearningTrigger trigger, {
    required LearningCoordinationSkipReason skipReason,
  }) {
    return LearningCoordinationReport(
      trigger: trigger,
      createdRuns: 0,
      resumedRuns: 0,
      completedRuns: 0,
      retryableFailures: 0,
      terminalFailures: 0,
      skipReason: skipReason,
    );
  }

  DateTime _completionTime(LearningRun run) {
    final now = clock.now().toUtc();
    return now.isBefore(run.triggeredAt) ? run.triggeredAt : now;
  }
}

final class _RunOutcome {
  const _RunOutcome({
    this.created = false,
    this.resumed = false,
    this.completed = false,
    this.retryableFailure = false,
    this.terminalFailure = false,
  });

  final bool created;
  final bool resumed;
  final bool completed;
  final bool retryableFailure;
  final bool terminalFailure;
}
