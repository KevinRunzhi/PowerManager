import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/business_write_coordinator.dart';
import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
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
  final CanonicalJsonEncoder canonicalEncoder;

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
