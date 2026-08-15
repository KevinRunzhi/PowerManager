import 'package:power_manager/application/automatic_learning_coordinator.dart';
import 'package:power_manager/application/business_write_coordinator.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/db/drift_transaction_runner.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';
import 'package:test/test.dart';

import '../data/db/test_database.dart';

void main() {
  late _Harness harness;

  setUp(() async {
    harness = _Harness();
    await harness.seedDay(0);
  });

  tearDown(() => harness.close());

  test('settled evidence creates a completed read-only run', () async {
    final before = await harness.models.getActive();
    final settingsBefore = await harness.settings.get();

    final report = await harness.coordinator().request(
      AutomaticLearningTrigger.settlement,
    );

    expect(report.createdRuns, 1);
    expect(report.completedRuns, 1);
    expect(report.retryableFailures, 0);
    final runs = await harness.runs.list();
    expect(runs, hasLength(1));
    expect(runs.single.status, LearningRunStatus.completed);
    expect(runs.single.result, LearningRunResult.insufficientEvidence);
    expect(runs.single.candidateValuesJson, isNull);
    expect(
      (await harness.models.getActive()).baseEnergy,
      before.baseEnergy,
    );
    expect((await harness.settings.get()).updatedAt, settingsBefore.updatedAt);
  });

  test(
    '13 pairs persist insufficient and the 14th persists readyForAudit',
    () async {
      for (var index = 1; index < 13; index++) {
        await harness.seedDay(index * 2);
      }
      final settingsBefore = await harness.settings.get();
      final modelBefore = await harness.models.getActive();

      final thirteen = await harness.coordinator().request(
        AutomaticLearningTrigger.settlement,
      );
      final firstRun = (await harness.runs.list()).single;
      expect(thirteen.completedRuns, 1);
      expect(firstRun.result, LearningRunResult.insufficientEvidence);
      expect(firstRun.candidateValuesJson, isNull);

      await harness.seedDay(26);
      final fourteen = await harness.coordinator().request(
        AutomaticLearningTrigger.settlement,
      );
      final runs = await harness.runs.list();
      expect(fourteen.completedRuns, 1);
      expect(runs, hasLength(2));
      expect(
        runs.where((run) => run.result == LearningRunResult.readyForAudit),
        hasLength(1),
      );
      expect(runs.every((run) => run.candidateValuesJson == null), isTrue);
      final settingsAfter = await harness.settings.get();
      expect(
        (await harness.models.getActive()).id,
        modelBefore.id,
      );
      expect(settingsAfter.activeRuleVersion, settingsBefore.activeRuleVersion);
      expect(
        settingsAfter.pendingRuleVersion,
        settingsBefore.pendingRuleVersion,
      );
      expect(settingsAfter.updatedAt, settingsBefore.updatedAt);
    },
  );

  test(
    'same evidence across repeated and concurrent requests writes once',
    () async {
      final coordinator = harness.coordinator();

      final concurrent = await Future.wait([
        coordinator.request(AutomaticLearningTrigger.coldStart),
        coordinator.request(AutomaticLearningTrigger.resumed),
      ]);
      final repeated = await coordinator.request(
        AutomaticLearningTrigger.retry,
      );

      expect(
        concurrent.map((item) => item.createdRuns).reduce((a, b) => a + b),
        1,
      );
      expect(await harness.runs.list(), hasLength(1));
      expect(
        repeated.skipReason,
        LearningCoordinationSkipReason.unchangedEvidence,
      );
      expect(harness.countingRuns.inserts, 1);
      expect(harness.countingRuns.updates, 2);
    },
  );

  test('unsettled evidence produces no run until a summary exists', () async {
    await harness.close();
    harness = _Harness();
    await harness.seedDay(0, settled: false);
    final coordinator = harness.coordinator();

    final before = await coordinator.request(
      AutomaticLearningTrigger.coldStart,
    );
    expect(before.skipReason, LearningCoordinationSkipReason.noSettledEvidence);
    expect(await harness.runs.list(), isEmpty);

    await harness.seedSummary(0);
    final after = await coordinator.request(
      AutomaticLearningTrigger.settlement,
    );
    expect(after.createdRuns, 1);
    expect(after.completedRuns, 1);
  });

  test('failed integrity gate is fail-closed with zero writes', () async {
    final report = await harness
        .coordinator(integrity: const _Integrity(false))
        .request(AutomaticLearningTrigger.coldStart);

    expect(
      report.skipReason,
      LearningCoordinationSkipReason.integrityGateFailed,
    );
    expect(await harness.runs.list(), isEmpty);
    expect(harness.countingRuns.inserts, 0);
  });

  test('retryable failure resumes the same id and triggeredAt', () async {
    final evaluator = _RetryOnceEvaluator();
    final coordinator = harness.coordinator(evaluator: evaluator);

    final first = await coordinator.request(
      AutomaticLearningTrigger.settlement,
    );
    final failed = (await harness.runs.list()).single;
    harness.clock.value = harness.clock.value.add(const Duration(minutes: 5));
    final second = await coordinator.request(AutomaticLearningTrigger.retry);
    final completed = (await harness.runs.list()).single;

    expect(first.retryableFailures, 1);
    expect(failed.status, LearningRunStatus.retryableFailure);
    expect(second.resumedRuns, 1);
    expect(second.completedRuns, 1);
    expect(completed.id, failed.id);
    expect(completed.triggeredAt, failed.triggeredAt);
    expect(completed.status, LearningRunStatus.completed);
    expect(evaluator.calls, 2);
  });

  test('a crash that leaves pending resumes the same run', () async {
    final failingRuns = _FailFirstStatusRepository(
      harness.countingRuns,
      LearningRunStatus.running,
    );
    final coordinator = harness.coordinator(learningRuns: failingRuns);

    final first = await coordinator.request(
      AutomaticLearningTrigger.settlement,
    );
    final pending = (await harness.runs.list()).single;
    expect(first.retryableFailures, 1);
    expect(pending.status, LearningRunStatus.pending);

    final second = await coordinator.request(AutomaticLearningTrigger.retry);
    final completed = (await harness.runs.list()).single;
    expect(second.resumedRuns, 1);
    expect(second.completedRuns, 1);
    expect(completed.id, pending.id);
    expect(completed.triggeredAt, pending.triggeredAt);
    expect(completed.status, LearningRunStatus.completed);
  });

  test('a crash that leaves running resumes the same run', () async {
    final evaluator = _RetryOnceEvaluator();
    final failingRuns = _FailFirstStatusRepository(
      harness.countingRuns,
      LearningRunStatus.retryableFailure,
    );
    final coordinator = harness.coordinator(
      learningRuns: failingRuns,
      evaluator: evaluator,
    );

    final first = await coordinator.request(
      AutomaticLearningTrigger.settlement,
    );
    final running = (await harness.runs.list()).single;
    expect(first.retryableFailures, 1);
    expect(running.status, LearningRunStatus.running);

    final second = await coordinator.request(AutomaticLearningTrigger.retry);
    final completed = (await harness.runs.list()).single;
    expect(second.resumedRuns, 1);
    expect(second.completedRuns, 1);
    expect(completed.id, running.id);
    expect(completed.triggeredAt, running.triggeredAt);
    expect(completed.status, LearningRunStatus.completed);
  });

  test('wall-clock rollback never writes completion before trigger', () async {
    final coordinator = harness.coordinator(
      evaluator: _ClockRollbackEvaluator(harness.clock),
    );

    final report = await coordinator.request(
      AutomaticLearningTrigger.settlement,
    );
    final completed = (await harness.runs.list()).single;

    expect(report.completedRuns, 1);
    expect(completed.status, LearningRunStatus.completed);
    expect(completed.completedAt, completed.triggeredAt);
  });

  test(
    'completion write failure becomes retryable and later resumes',
    () async {
      final failingRuns = _FailFirstCompletionRepository(harness.countingRuns);
      final coordinator = harness.coordinator(learningRuns: failingRuns);

      final first = await coordinator.request(
        AutomaticLearningTrigger.settlement,
      );
      expect(first.retryableFailures, 1);
      expect(
        (await harness.runs.list()).single.status,
        LearningRunStatus.retryableFailure,
      );

      final second = await coordinator.request(AutomaticLearningTrigger.retry);
      expect(second.completedRuns, 1);
      expect(
        (await harness.runs.list()).single.status,
        LearningRunStatus.completed,
      );
    },
  );

  test(
    'terminal failure is final and never enters a busy retry loop',
    () async {
      final evaluator = _TerminalEvaluator();
      final coordinator = harness.coordinator(evaluator: evaluator);

      final first = await coordinator.request(
        AutomaticLearningTrigger.settlement,
      );
      final second = await coordinator.request(AutomaticLearningTrigger.retry);

      expect(first.terminalFailures, 1);
      expect(
        (await harness.runs.list()).single.status,
        LearningRunStatus.terminalFailure,
      );
      expect(
        second.skipReason,
        LearningCoordinationSkipReason.unchangedEvidence,
      );
      expect(evaluator.calls, 1);
    },
  );

  test(
    'disabled read-only engine records configurationBlocked without candidate',
    () async {
      final coordinator = harness.coordinator(
        config: ShadowLearningConfig.evidenceReadinessV1(engineEnabled: false),
      );

      await coordinator.request(AutomaticLearningTrigger.coldStart);

      final run = (await harness.runs.list()).single;
      expect(run.status, LearningRunStatus.completed);
      expect(run.result, LearningRunResult.configurationBlocked);
      expect(run.candidateValuesJson, isNull);
    },
  );
}

final class _Harness {
  _Harness()
    : database = createTestDatabase(),
      clock = _MutableClock(DateTime.utc(2026, 8, 15, 12)) {
    settings = DriftAppSettingsRepository(database.appSettingsDao);
    models = DriftPersonalizationVersionsRepository(
      database.personalizationVersionsDao,
    );
    mornings = DriftMorningCheckInsRepository(database.morningCheckInsDao);
    observations = DriftEnergyObservationsRepository(
      database.energyObservationsDao,
    );
    summaries = DriftDailySummariesRepository(database.dailySummariesDao);
    runs = DriftLearningRunsRepository(database.learningRunsDao);
    countingRuns = _CountingLearningRunsRepository(runs);
  }

  final AppDatabase database;
  final _MutableClock clock;
  late final DriftAppSettingsRepository settings;
  late final DriftPersonalizationVersionsRepository models;
  late final DriftMorningCheckInsRepository mornings;
  late final DriftEnergyObservationsRepository observations;
  late final DriftDailySummariesRepository summaries;
  late final DriftLearningRunsRepository runs;
  late final _CountingLearningRunsRepository countingRuns;
  final writer = SerialBusinessWriteCoordinator();

  Future<void> close() => database.close();

  AutomaticLearningCoordinator coordinator({
    LearningIntegrityVerifier integrity = const _Integrity(true),
    ShadowLearningEvaluator evaluator = const BaselineShadowLearner(),
    ShadowLearningConfig? config,
    LearningRunsRepository? learningRuns,
  }) {
    return AutomaticLearningCoordinator(
      writeCoordinator: writer,
      transactionRunner: DriftTransactionRunner(database),
      clock: clock,
      integrityVerifier: integrity,
      observations: observations,
      mornings: mornings,
      summaries: summaries,
      learningRuns: learningRuns ?? countingRuns,
      evaluator: evaluator,
      config: config,
    );
  }

  Future<void> seedDay(int offset, {bool settled = true}) async {
    await settings.get();
    final day = _day(offset);
    await mornings.insert(
      MorningCheckIn(
        id: 'morning-$offset',
        lifeDay: day,
        overallState: MorningOverallState.normal,
        freeTimeLevel: FreeTimeLevel.medium,
        pressureSource: PressureSource.low,
        sleepRecovery: SleepRecovery.normal,
        morningAdjustment: 0,
        completedAt: DateTime.utc(day.year, day.month, day.day, 5),
      ),
    );
    await observations.insert(_observation(offset));
    if (settled) await seedSummary(offset);
  }

  Future<void> seedSummary(int offset) async {
    final day = _day(offset);
    await summaries.insertOrGet(
      DailySummary(
        lifeDay: day,
        baseEstimatedEnergy: 100,
        ruleVersion: energyRulesV2MvpAVersion,
        morningAdjustment: 0,
        shortTermAdjustment: 0,
        initialEstimatedEnergy: 100,
        finalEstimatedEnergy: 100,
        totalConsumption: 0,
        totalRecovery: 0,
        categorySummaries: {
          for (final category in ActivityCategory.values)
            category: CategoryEstimatedSummary(
              category: category,
              durationMinutes: 0,
              netDelta: 0,
              grossDelta: 0,
            ),
        },
        isStandardEffectiveDay: false,
        isWeakEffectiveDay: false,
        settledAt: DateTime.utc(day.year, day.month, day.day + 1, 4),
      ),
    );
  }
}

final class _Integrity implements LearningIntegrityVerifier {
  const _Integrity(this.value);

  final bool value;

  @override
  Future<bool> verify() async => value;
}

final class _RetryOnceEvaluator implements ShadowLearningEvaluator {
  var calls = 0;

  @override
  ShadowLearningEvaluation evaluate({
    required ShadowEvidencePackage evidence,
    required ShadowLearningConfig config,
  }) {
    calls++;
    if (calls == 1) throw const RetryableShadowLearningException();
    return const BaselineShadowLearner().evaluate(
      evidence: evidence,
      config: config,
    );
  }
}

final class _TerminalEvaluator implements ShadowLearningEvaluator {
  var calls = 0;

  @override
  ShadowLearningEvaluation evaluate({
    required ShadowEvidencePackage evidence,
    required ShadowLearningConfig config,
  }) {
    calls++;
    throw const TerminalShadowLearningException();
  }
}

final class _ClockRollbackEvaluator implements ShadowLearningEvaluator {
  _ClockRollbackEvaluator(this.clock);

  final _MutableClock clock;

  @override
  ShadowLearningEvaluation evaluate({
    required ShadowEvidencePackage evidence,
    required ShadowLearningConfig config,
  }) {
    clock.value = clock.value.subtract(const Duration(days: 1));
    return const BaselineShadowLearner().evaluate(
      evidence: evidence,
      config: config,
    );
  }
}

final class _CountingLearningRunsRepository implements LearningRunsRepository {
  const _CountingLearningRunsRepository(this.delegate);

  final LearningRunsRepository delegate;
  static final Expando<_WriteCounts> _counts = Expando<_WriteCounts>();
  _WriteCounts get _state => _counts[this] ??= _WriteCounts();
  int get inserts => _state.inserts;
  int get updates => _state.updates;

  @override
  Future<void> insert(LearningRun run) {
    _state.inserts++;
    return delegate.insert(run);
  }

  @override
  Future<void> update(LearningRun run) {
    _state.updates++;
    return delegate.update(run);
  }

  @override
  Future<LearningRun?> find(String id) => delegate.find(id);

  @override
  Future<LearningRun?> findByIdempotency({
    required LearningParameterFamily parameterFamily,
    required String sourceModelIdentity,
    required String algorithmVersion,
    required String configVersion,
    required String evidenceHash,
  }) => delegate.findByIdempotency(
    parameterFamily: parameterFamily,
    sourceModelIdentity: sourceModelIdentity,
    algorithmVersion: algorithmVersion,
    configVersion: configVersion,
    evidenceHash: evidenceHash,
  );

  @override
  Future<List<LearningRun>> list() => delegate.list();
}

final class _WriteCounts {
  var inserts = 0;
  var updates = 0;
}

final class _FailFirstCompletionRepository implements LearningRunsRepository {
  _FailFirstCompletionRepository(this.delegate);

  final LearningRunsRepository delegate;
  var shouldFailCompletion = true;

  @override
  Future<void> insert(LearningRun run) => delegate.insert(run);

  @override
  Future<void> update(LearningRun run) {
    if (shouldFailCompletion && run.status == LearningRunStatus.completed) {
      shouldFailCompletion = false;
      throw StateError('injected completion write failure');
    }
    return delegate.update(run);
  }

  @override
  Future<LearningRun?> find(String id) => delegate.find(id);

  @override
  Future<LearningRun?> findByIdempotency({
    required LearningParameterFamily parameterFamily,
    required String sourceModelIdentity,
    required String algorithmVersion,
    required String configVersion,
    required String evidenceHash,
  }) => delegate.findByIdempotency(
    parameterFamily: parameterFamily,
    sourceModelIdentity: sourceModelIdentity,
    algorithmVersion: algorithmVersion,
    configVersion: configVersion,
    evidenceHash: evidenceHash,
  );

  @override
  Future<List<LearningRun>> list() => delegate.list();
}

final class _FailFirstStatusRepository implements LearningRunsRepository {
  _FailFirstStatusRepository(this.delegate, this.statusToFail);

  final LearningRunsRepository delegate;
  final LearningRunStatus statusToFail;
  var shouldFail = true;

  @override
  Future<void> insert(LearningRun run) => delegate.insert(run);

  @override
  Future<void> update(LearningRun run) {
    if (shouldFail && run.status == statusToFail) {
      shouldFail = false;
      throw StateError('injected ${statusToFail.code} write failure');
    }
    return delegate.update(run);
  }

  @override
  Future<LearningRun?> find(String id) => delegate.find(id);

  @override
  Future<LearningRun?> findByIdempotency({
    required LearningParameterFamily parameterFamily,
    required String sourceModelIdentity,
    required String algorithmVersion,
    required String configVersion,
    required String evidenceHash,
  }) => delegate.findByIdempotency(
    parameterFamily: parameterFamily,
    sourceModelIdentity: sourceModelIdentity,
    algorithmVersion: algorithmVersion,
    configVersion: configVersion,
    evidenceHash: evidenceHash,
  );

  @override
  Future<List<LearningRun>> list() => delegate.list();
}

final class _MutableClock implements Clock {
  _MutableClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

EnergyObservation _observation(int offset) {
  final day = _day(offset);
  return EnergyObservation(
    id: 'observation-$offset',
    lifeDay: day,
    type: EnergyObservationType.dailyAbsolute,
    absoluteState: AbsoluteEnergyState.good,
    relativeState: null,
    estimateAtObservation: 60,
    observedAt: DateTime.utc(day.year, day.month, day.day, 12),
    contractVersion: mvpBObservationContractV1,
    referenceType: ObservationReferenceType.currentMoment,
    initialEstimateAtObservation: 100,
    estimatedOrdinalAtObservation: 3,
    baseEnergyAtObservation: 100,
    ruleVersionAtObservation: energyRulesV2MvpAVersion,
    comparisonBandVersion: mvpBComparisonBandV1,
    personalizationVersionAtObservation: fixedMvpAPersonalizationVersion,
    effectiveModelFingerprintAtObservation: fixedMvpAEffectiveModelFingerprint,
    modelRegimeEpochAtObservation: fixedMvpAInitialModelRegimeEpoch,
    activeActivityCountAtObservation: 0,
    coverageState: ObservationCoverageState.confirmed,
    modelRegimeKey: const ModelRegimeKeyBuilder().build(
      referenceType: ObservationReferenceType.currentMoment,
      baseEnergy: 100,
      ruleVersion: energyRulesV2MvpAVersion,
      comparisonBandVersion: mvpBComparisonBandV1,
      effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
      modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
    ),
  );
}

LifeDay _day(int offset) {
  return LifeDay.fromLocalDateTime(DateTime(2026, 1, 1 + offset));
}
