import 'package:power_manager/application/activity_use_cases.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/settlement_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/db/drift_transaction_runner.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/life_day/life_day_calculator.dart';
import 'package:power_manager/domain/repositories/repositories.dart';
import 'package:test/test.dart';

import '../data/db/test_database.dart';

void main() {
  late AppDatabase database;
  late MutableClock clock;
  late _Harness harness;

  setUp(() {
    database = createTestDatabase();
    clock = MutableClock(DateTime(2026, 7, 26, 3, 50));
    harness = _Harness(database, clock);
  });

  tearDown(() => database.close());

  test(
    'current projection derives every value from persisted sources',
    () async {
      await harness.summaries.insertOrGet(
        _summary(LifeDay(2026, 7, 24), finalEstimate: -8),
      );
      await harness.mornings.insert(_morning(LifeDay(2026, 7, 25)));
      await harness.activities.insert(
        _activity('later', LifeDay(2026, 7, 25), minute: 30),
      );
      await harness.activities.insert(
        _activity('earlier', LifeDay(2026, 7, 25), minute: 10),
      );

      final result = await harness.prepare(PreparationTrigger.coldStart);

      expect(result.current.lifeDay, LifeDay(2026, 7, 25));
      expect(result.current.previousFinalEstimate, -8);
      expect(result.current.shortTermAdjustment, -2);
      expect(result.current.morningAdjustment, 6);
      expect(result.current.projection.initialEstimate, 104);
      expect(
        result.current.projection.activities.map((item) => item.record.id),
        ['earlier', 'later'],
      );
      expect(result.current.projection.currentEstimate, 94);
    },
  );

  test('first write after crossing 04:00 settles the old life day', () async {
    await harness.activities.insert(
      _activity('before-boundary', LifeDay(2026, 7, 25), minute: 10),
    );
    final opened = await harness.prepare(PreparationTrigger.coldStart);
    expect(opened.current.lifeDay, LifeDay(2026, 7, 25));

    clock.value = DateTime(2026, 7, 26, 4, 10);
    final beforeWrite = await harness.prepare(PreparationTrigger.beforeWrite);

    expect(beforeWrite.current.lifeDay, LifeDay(2026, 7, 26));
    expect(beforeWrite.settledSummaries.single.lifeDay, LifeDay(2026, 7, 25));
    expect(await harness.summaries.list(), hasLength(1));
  });

  test(
    'multi-day settlement is oldest-to-newest and skips empty days',
    () async {
      clock.value = DateTime(2026, 7, 29, 10);
      await harness.mornings.insert(_morning(LifeDay(2026, 7, 25)));
      await harness.activities.insert(
        _activity('day-27', LifeDay(2026, 7, 27), minute: 10),
      );

      final result = await harness.prepare(PreparationTrigger.resumed);

      expect(result.settledSummaries.map((summary) => summary.lifeDay), [
        LifeDay(2026, 7, 25),
        LifeDay(2026, 7, 27),
      ]);
      expect(
        (await harness.summaries.list()).map((summary) => summary.lifeDay),
        [LifeDay(2026, 7, 25), LifeDay(2026, 7, 27)],
      );
    },
  );

  test('ten repeated preparations are idempotent', () async {
    clock.value = DateTime(2026, 7, 26, 10);
    await harness.activities.insert(
      _activity('yesterday', LifeDay(2026, 7, 25), minute: 10),
    );

    for (var index = 0; index < 10; index++) {
      await harness.prepare(PreparationTrigger.resumed);
    }

    expect(await harness.summaries.list(), hasLength(1));
  });

  test('transaction failure leaves no half-written summaries', () async {
    clock.value = DateTime(2026, 7, 28, 10);
    await harness.activities.insert(
      _activity('day-25', LifeDay(2026, 7, 25), minute: 10),
    );
    await harness.activities.insert(
      _activity('day-26', LifeDay(2026, 7, 26), minute: 10),
    );
    final failing = harness.withSummaries(
      _FailOnSecondInsertSummaries(harness.summaries),
    );

    await expectLater(
      failing.prepare(PreparationTrigger.resumed),
      throwsStateError,
    );
    expect(await harness.summaries.list(), isEmpty);
  });

  test(
    'pending base and rule activate on the due life day exactly once',
    () async {
      const nextRule = 'energy-rules-next';
      await harness.rules.insert(
        RuleConfigVersion(
          version: nextRule,
          values: const {'ruleVersion': nextRule},
          createdAt: DateTime.utc(2026, 7, 26),
        ),
      );
      final original = await harness.settings.get();
      await harness.settings.save(
        AppSettings(
          baseEstimatedEnergy: original.baseEstimatedEnergy,
          pendingBaseEstimatedEnergy: 112,
          baseEnergyEffectiveLifeDay: LifeDay(2026, 7, 26),
          activeRuleVersion: original.activeRuleVersion,
          pendingRuleVersion: nextRule,
          pendingRuleEffectiveLifeDay: LifeDay(2026, 7, 26),
          onboardingCompleted: original.onboardingCompleted,
          createdAt: original.createdAt,
          updatedAt: original.updatedAt,
        ),
      );

      final beforeDue = await harness.prepare(PreparationTrigger.coldStart);
      expect(beforeDue.current.lifeDay, LifeDay(2026, 7, 25));
      expect(beforeDue.current.baseEstimatedEnergy, 100);
      expect(beforeDue.current.ruleVersion, energyRulesV2MvpAVersion);

      clock.value = DateTime(2026, 7, 26, 4, 1);
      final due = await harness.prepare(PreparationTrigger.beforeWrite);
      final repeated = await harness.prepare(PreparationTrigger.resumed);
      final saved = await harness.settings.get();

      expect(due.appliedPendingBaseEnergy, isTrue);
      expect(due.appliedPendingRuleVersion, isTrue);
      expect(repeated.appliedPendingBaseEnergy, isFalse);
      expect(repeated.appliedPendingRuleVersion, isFalse);
      expect(saved.baseEstimatedEnergy, 112);
      expect(saved.activeRuleVersion, nextRule);
      expect(saved.pendingBaseEstimatedEnergy, isNull);
      expect(saved.pendingRuleVersion, isNull);
    },
  );

  test(
    'late actual-state observation does not mutate an existing summary',
    () async {
      clock.value = DateTime(2026, 7, 26, 10);
      await harness.activities.insert(
        _activity('yesterday', LifeDay(2026, 7, 25), minute: 10),
      );
      await harness.prepare(PreparationTrigger.coldStart);
      final before = await harness.summaries.findByLifeDay(
        LifeDay(2026, 7, 25),
      );

      await harness.observations.insert(
        EnergyObservation(
          id: 'late-observation',
          lifeDay: LifeDay(2026, 7, 25),
          type: EnergyObservationType.dailyAbsolute,
          absoluteState: AbsoluteEnergyState.low,
          relativeState: null,
          estimateAtObservation: null,
          observedAt: DateTime.utc(2026, 7, 26, 3),
        ),
      );
      await harness.prepare(PreparationTrigger.beforeWrite);
      final after = await harness.summaries.findByLifeDay(LifeDay(2026, 7, 25));

      expect(after!.settledAt, before!.settledAt);
      expect(after.finalEstimatedEnergy, before.finalEstimatedEnergy);
    },
  );
  test(
    'all 24 subcategories can be created through the same use case',
    () async {
      clock.value = DateTime(2026, 7, 26, 12);
      final useCases = harness.activityUseCases();
      for (var index = 0; index < ActivitySubcategory.values.length; index++) {
        final subcategory = ActivitySubcategory.values[index];
        await useCases.create(
          ActivityDraft(
            operationId: 'subcategory-${subcategory.code}',
            category: subcategory.category,
            subcategory: subcategory,
            duration: DurationSlot.minutes15,
            completedAt: DateTime(2026, 7, 26, 8, index),
          ),
        );
      }
      expect(
        await harness.activities.listActiveForLifeDay(LifeDay(2026, 7, 26)),
        hasLength(24),
      );
    },
  );

  test(
    'the four other subcategories use their exact configured rules',
    () async {
      clock.value = DateTime(2026, 7, 26, 12);
      final useCases = harness.activityUseCases();
      final others = [
        ActivitySubcategory.otherStudy,
        ActivitySubcategory.otherPractice,
        ActivitySubcategory.otherRecovery,
        ActivitySubcategory.otherLeisure,
      ];
      for (var index = 0; index < others.length; index++) {
        final subcategory = others[index];
        await useCases.create(
          ActivityDraft(
            operationId: 'other-${subcategory.code}',
            category: subcategory.category,
            subcategory: subcategory,
            duration: DurationSlot.minutes15,
            completedAt: DateTime(2026, 7, 26, 9, index),
          ),
        );
      }
      final stored = await harness.activities.listActiveForLifeDay(
        LifeDay(2026, 7, 26),
      );
      expect(stored.map((item) => item.theoreticalDelta), [-5, -5, 5, 0]);
    },
  );

  test(
    'editing the earliest consumption recomputes later recovery cap',
    () async {
      clock.value = DateTime(2026, 7, 26, 12);
      final useCases = harness.activityUseCases();
      await useCases.create(
        ActivityDraft(
          operationId: 'consumption',
          category: ActivityCategory.study,
          subcategory: ActivitySubcategory.classAttendance,
          duration: DurationSlot.minutes60,
          completedAt: DateTime(2026, 7, 26, 8),
        ),
      );
      await useCases.create(
        ActivityDraft(
          operationId: 'recovery',
          category: ActivityCategory.recovery,
          subcategory: ActivitySubcategory.nap,
          duration: DurationSlot.minutes60,
          completedAt: DateTime(2026, 7, 26, 9),
        ),
      );
      expect((await harness.activities.find('recovery'))!.appliedDelta, 12);

      final result = await useCases.edit(
        activityId: 'consumption',
        category: ActivityCategory.study,
        subcategory: ActivitySubcategory.classAttendance,
        duration: DurationSlot.minutes15,
        completedAt: DateTime(2026, 7, 26, 8),
      );
      expect((await harness.activities.find('recovery'))!.appliedDelta, 5);
      expect(result.current.projection.currentEstimate, 100);
    },
  );

  test('duplicate create and repeated delete are idempotent', () async {
    clock.value = DateTime(2026, 7, 26, 12);
    final useCases = harness.activityUseCases();
    final draft = ActivityDraft(
      operationId: 'single-operation',
      category: ActivityCategory.study,
      subcategory: ActivitySubcategory.homework,
      duration: DurationSlot.minutes30,
      completedAt: DateTime(2026, 7, 26, 10),
    );
    final created = await Future.wait([
      useCases.create(draft),
      useCases.create(draft),
    ]);
    final deleted = await Future.wait([
      useCases.delete(draft.operationId),
      useCases.delete(draft.operationId),
    ]);
    expect(created.where((result) => !result.wasAlreadyApplied), hasLength(1));
    expect(deleted.where((result) => !result.wasAlreadyApplied), hasLength(1));
    expect(
      await harness.activities.listActiveForLifeDay(LifeDay(2026, 7, 26)),
      isEmpty,
    );
    expect(
      (await harness.activities.find(draft.operationId))!.status,
      ActivityRecordStatus.deleted,
    );
  });

  test(
    'future, cross-life-day, and settled-history edits are rejected',
    () async {
      clock.value = DateTime(2026, 7, 26, 5);
      final useCases = harness.activityUseCases();
      await expectLater(
        useCases.create(
          ActivityDraft(
            operationId: 'future',
            category: ActivityCategory.study,
            subcategory: ActivitySubcategory.homework,
            duration: DurationSlot.minutes15,
            completedAt: DateTime(2026, 7, 26, 6),
          ),
        ),
        throwsArgumentError,
      );
      await expectLater(
        useCases.create(
          ActivityDraft(
            operationId: 'previous-life-day',
            category: ActivityCategory.study,
            subcategory: ActivitySubcategory.homework,
            duration: DurationSlot.minutes15,
            completedAt: DateTime(2026, 7, 26, 3, 30),
          ),
        ),
        throwsStateError,
      );
      await harness.activities.insert(
        _activity('historical', LifeDay(2026, 7, 25), minute: 10),
      );
      await expectLater(
        useCases.edit(
          activityId: 'historical',
          category: ActivityCategory.study,
          subcategory: ActivitySubcategory.homework,
          duration: DurationSlot.minutes30,
          completedAt: DateTime(2026, 7, 25, 8),
        ),
        throwsStateError,
      );
    },
  );
}

final class MutableClock implements Clock {
  MutableClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

final class _Harness {
  _Harness(
    this.database,
    this.clock, [
    DailySummariesRepository? summaryOverride,
  ]) : settings = DriftAppSettingsRepository(database.appSettingsDao),
       rules = DriftRuleConfigVersionsRepository(
         database.ruleConfigVersionsDao,
       ),
       mornings = DriftMorningCheckInsRepository(database.morningCheckInsDao),
       activities = DriftActivityRecordsRepository(database.activityRecordsDao),
       observations = DriftEnergyObservationsRepository(
         database.energyObservationsDao,
       ),
       summaries =
           summaryOverride ??
           DriftDailySummariesRepository(database.dailySummariesDao);

  final AppDatabase database;
  final MutableClock clock;
  final DriftAppSettingsRepository settings;
  final DriftRuleConfigVersionsRepository rules;
  final DriftMorningCheckInsRepository mornings;
  final DriftActivityRecordsRepository activities;
  final DriftEnergyObservationsRepository observations;
  final DailySummariesRepository summaries;

  _Harness withSummaries(DailySummariesRepository replacement) {
    return _Harness(database, clock, replacement);
  }

  Future<OperationPreparationResult> prepare(PreparationTrigger trigger) {
    final projection = CurrentDayProjectionService(
      morningCheckIns: mornings,
      activities: activities,
      summaries: summaries,
    );
    return OperationPreparationService(
      clock: clock,
      lifeDayCalculator: LifeDayCalculator(),
      transactionRunner: DriftTransactionRunner(database),
      settings: settings,
      settlementService: SettlementService(
        morningCheckIns: mornings,
        activities: activities,
        observations: observations,
        summaries: summaries,
        projectionService: projection,
      ),
      projectionService: projection,
    ).prepare(trigger);
  }

  ActivityUseCases activityUseCases() {
    final projection = CurrentDayProjectionService(
      morningCheckIns: mornings,
      activities: activities,
      summaries: summaries,
    );
    final preparer = OperationPreparationService(
      clock: clock,
      lifeDayCalculator: LifeDayCalculator(),
      transactionRunner: DriftTransactionRunner(database),
      settings: settings,
      settlementService: SettlementService(
        morningCheckIns: mornings,
        activities: activities,
        observations: observations,
        summaries: summaries,
        projectionService: projection,
      ),
      projectionService: projection,
    );
    return ActivityUseCases(
      clock: clock,
      lifeDayCalculator: LifeDayCalculator(),
      transactionRunner: DriftTransactionRunner(database),
      preparer: preparer,
      activities: activities,
      rules: rules,
      summaries: summaries,
      projectionService: projection,
    );
  }
}

final class _FailOnSecondInsertSummaries implements DailySummariesRepository {
  _FailOnSecondInsertSummaries(this.delegate);

  final DailySummariesRepository delegate;
  var insertCount = 0;

  @override
  Future<DailySummary?> findByLifeDay(LifeDay lifeDay) {
    return delegate.findByLifeDay(lifeDay);
  }

  @override
  Future<DailySummary> insertOrGet(DailySummary summary) {
    insertCount++;
    if (insertCount == 2) {
      throw StateError('simulated settlement failure');
    }
    return delegate.insertOrGet(summary);
  }

  @override
  Future<List<DailySummary>> list() => delegate.list();
}

MorningCheckIn _morning(LifeDay day) {
  return MorningCheckIn(
    id: 'morning-$day',
    lifeDay: day,
    overallState: MorningOverallState.good,
    freeTimeLevel: FreeTimeLevel.medium,
    pressureSource: PressureSource.low,
    sleepRecovery: SleepRecovery.good,
    morningAdjustment: 6,
    completedAt: DateTime.utc(day.year, day.month, day.day, 5),
  );
}

StoredEstimatedActivity _activity(
  String id,
  LifeDay day, {
  required int minute,
}) {
  final completedAt = DateTime.utc(day.year, day.month, day.day, 8, minute);
  return StoredEstimatedActivity(
    id: id,
    lifeDay: day,
    completedAt: completedAt,
    createdAt: completedAt.add(const Duration(minutes: 1)),
    updatedAt: completedAt.add(const Duration(minutes: 1)),
    category: ActivityCategory.study,
    subcategory: ActivitySubcategory.classAttendance,
    duration: DurationSlot.minutes15,
    theoreticalDelta: -5,
    appliedDelta: -5,
    ruleVersion: energyRulesV2MvpAVersion,
    status: ActivityRecordStatus.active,
    deletedAt: null,
  );
}

DailySummary _summary(LifeDay day, {required int finalEstimate}) {
  return DailySummary(
    lifeDay: day,
    baseEstimatedEnergy: 100,
    ruleVersion: energyRulesV2MvpAVersion,
    morningAdjustment: 0,
    shortTermAdjustment: 0,
    initialEstimatedEnergy: 100,
    finalEstimatedEnergy: finalEstimate,
    totalConsumption: finalEstimate < 100 ? 100 - finalEstimate : 0,
    totalRecovery: finalEstimate > 100 ? finalEstimate - 100 : 0,
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
  );
}
