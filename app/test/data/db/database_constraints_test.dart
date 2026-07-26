import 'package:drift/drift.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

import 'test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  test('morning lifeDay is unique and adjustment must match state', () async {
    final repository = DriftMorningCheckInsRepository(
      MorningCheckInsDao(database),
    );
    await repository.insert(_checkIn(id: 'morning-1'));

    await expectLater(
      repository.insert(_checkIn(id: 'morning-2')),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database
          .into(database.morningCheckInsTable)
          .insert(
            MorningCheckInsTableCompanion.insert(
              id: 'wrong-adjustment',
              lifeDay: LifeDay(2026, 7, 27),
              overallState: MorningOverallState.good,
              freeTimeLevel: FreeTimeLevel.medium,
              pressureSource: PressureSource.low,
              sleepRecovery: SleepRecovery.normal,
              morningAdjustment: -6,
              completedAt: testNow,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('only one daily absolute observation exists per lifeDay', () async {
    final repository = DriftEnergyObservationsRepository(
      EnergyObservationsDao(database),
    );
    await repository.insert(_dailyObservation(id: 'daily-1'));

    await expectLater(
      repository.insert(_dailyObservation(id: 'daily-2')),
      throwsA(isA<Exception>()),
    );
    await repository.insert(_relativeObservation(id: 'relative-1'));
    await repository.insert(_relativeObservation(id: 'relative-2'));

    expect(await repository.listForLifeDay(LifeDay(2026, 7, 26)), hasLength(3));
  });

  test('observation type-specific fields are enforced', () async {
    await expectLater(
      database
          .into(database.energyObservationsTable)
          .insert(
            EnergyObservationsTableCompanion.insert(
              id: 'invalid-relative',
              lifeDay: LifeDay(2026, 7, 26),
              type: EnergyObservationType.relativeCorrection,
              relativeState: const Value(RelativeCorrection.aboutRight),
              estimateAtObservation: const Value.absent(),
              observedAt: testNow,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test(
    'activity duration, status, category pairing, and rule FK are enforced',
    () async {
      final unixSeconds = testNow.millisecondsSinceEpoch ~/ 1000;
      const insertSql = '''
      INSERT INTO activity_records (
        id, life_day, completed_at, created_at, updated_at,
        category, subcategory, duration_minutes,
        theoretical_delta, applied_delta, rule_version, status, deleted_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''';

      Future<void> rawInsert({
        required String id,
        String category = 'study',
        String subcategory = 'classAttendance',
        int duration = 15,
        String ruleVersion = energyRulesV2MvpAVersion,
        String status = 'active',
        int? deletedAt,
      }) {
        return database.customStatement(insertSql, [
          id,
          '2026-07-26',
          unixSeconds,
          unixSeconds,
          unixSeconds,
          category,
          subcategory,
          duration,
          -5,
          -5,
          ruleVersion,
          status,
          deletedAt,
        ]);
      }

      await database.appSettingsDao.getSettings();
      await expectLater(
        rawInsert(id: 'invalid-duration', duration: 20),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        rawInsert(
          id: 'category-mismatch',
          category: 'study',
          subcategory: 'nap',
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        rawInsert(id: 'invalid-status', status: 'removed'),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        rawInsert(id: 'active-with-deleted-at', deletedAt: unixSeconds),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        rawInsert(id: 'deleted-without-time', status: 'deleted'),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        rawInsert(id: 'unknown-rule', ruleVersion: 'missing-rule'),
        throwsA(isA<Exception>()),
      );
    },
  );

  test('daily summaries are unique and reject update or delete', () async {
    final repository = DriftDailySummariesRepository(
      DailySummariesDao(database),
    );
    final first = await repository.insertOrGet(_summary(finalEstimate: 72));
    final second = await repository.insertOrGet(_summary(finalEstimate: 10));

    expect(first.finalEstimatedEnergy, 72);
    expect(second.finalEstimatedEnergy, 72);
    await expectLater(
      (database.update(
        database.dailySummariesTable,
      )..where((row) => row.lifeDay.equalsValue(LifeDay(2026, 7, 26)))).write(
        const DailySummariesTableCompanion(finalEstimatedEnergy: Value(1)),
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      (database.delete(
        database.dailySummariesTable,
      )..where((row) => row.lifeDay.equalsValue(LifeDay(2026, 7, 26)))).go(),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database
          .into(database.dailySummariesTable)
          .insert(
            DailySummariesTableCompanion.insert(
              lifeDay: LifeDay(2026, 7, 27),
              baseEstimatedEnergy: 100,
              ruleVersion: energyRulesV2MvpAVersion,
              morningAdjustment: 0,
              shortTermAdjustment: 0,
              initialEstimatedEnergy: 100,
              finalEstimatedEnergy: 80,
              totalConsumption: 20,
              totalRecovery: 0,
              categorySummaryJson: '{}',
              isStandardEffectiveDay: true,
              isWeakEffectiveDay: true,
              settledAt: testNow,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('referenced rule versions reject every update', () async {
    await database.appSettingsDao.getSettings();

    await expectLater(
      database.ruleConfigVersionsDao.insertVersion(
        RuleConfigVersionsTableCompanion.insert(
          version: 'invalid-json-rule',
          valuesJson: '{not-json',
          createdAt: testNow,
        ),
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      (database.update(
        database.ruleConfigVersionsTable,
      )..where((row) => row.version.equals(energyRulesV2MvpAVersion))).write(
        const RuleConfigVersionsTableCompanion(
          valuesJson: Value('{"changed":true}'),
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('prompt receipt scope is non-empty and triple is unique', () async {
    final repository = DriftPromptReceiptsRepository(
      PromptReceiptsDao(database),
    );
    final receipt = _receipt(id: 'receipt-1');
    await repository.insert(receipt);

    await expectLater(
      repository.insert(_receipt(id: 'receipt-2')),
      throwsA(isA<Exception>()),
    );
    await repository.insert(
      PromptReceipt(
        id: 'receipt-3',
        type: receipt.type,
        scopeKey: receipt.scopeKey,
        action: PromptReceiptAction.dismissed,
        occurredAt: testNow,
      ),
    );
    await expectLater(
      repository.insert(
        PromptReceipt(
          id: 'empty-scope',
          type: PromptReceiptType.morning,
          scopeKey: ' ',
          action: PromptReceiptAction.shown,
          occurredAt: testNow,
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('app settings enforce singleton id and base estimate range', () async {
    await database.appSettingsDao.getSettings();
    await expectLater(
      database
          .into(database.appSettingsTable)
          .insert(
            AppSettingsTableCompanion.insert(
              id: const Value(2),
              activeRuleVersion: energyRulesV2MvpAVersion,
              createdAt: testNow,
              updatedAt: testNow,
            ),
          ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database.appSettingsDao.updateSettings(
        const AppSettingsTableCompanion(baseEstimatedEnergy: Value(141)),
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database.appSettingsDao.updateSettings(
        const AppSettingsTableCompanion(pendingBaseEstimatedEnergy: Value(105)),
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database.appSettingsDao.updateSettings(
        const AppSettingsTableCompanion(
          pendingRuleVersion: Value(energyRulesV2MvpAVersion),
        ),
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database.delete(database.appSettingsTable).go(),
      throwsA(isA<Exception>()),
    );
  });

  test('transaction failures roll back every write', () async {
    final repository = DriftMorningCheckInsRepository(
      MorningCheckInsDao(database),
    );

    await expectLater(
      database.transaction(() async {
        await repository.insert(_checkIn(id: 'rolled-back'));
        throw StateError('force rollback');
      }),
      throwsStateError,
    );

    expect(await repository.list(), isEmpty);
  });
}

MorningCheckIn _checkIn({required String id}) {
  return MorningCheckIn(
    id: id,
    lifeDay: LifeDay(2026, 7, 26),
    overallState: MorningOverallState.good,
    freeTimeLevel: FreeTimeLevel.medium,
    pressureSource: PressureSource.low,
    sleepRecovery: SleepRecovery.normal,
    morningAdjustment: 6,
    completedAt: testNow,
  );
}

EnergyObservation _dailyObservation({required String id}) {
  return EnergyObservation(
    id: id,
    lifeDay: LifeDay(2026, 7, 26),
    type: EnergyObservationType.dailyAbsolute,
    absoluteState: AbsoluteEnergyState.good,
    relativeState: null,
    estimateAtObservation: 72,
    observedAt: testNow,
  );
}

EnergyObservation _relativeObservation({required String id}) {
  return EnergyObservation(
    id: id,
    lifeDay: LifeDay(2026, 7, 26),
    type: EnergyObservationType.relativeCorrection,
    absoluteState: null,
    relativeState: RelativeCorrection.aboutRight,
    estimateAtObservation: 72,
    observedAt: testNow,
  );
}

DailySummary _summary({required int finalEstimate}) {
  return DailySummary(
    lifeDay: LifeDay(2026, 7, 26),
    baseEstimatedEnergy: 100,
    ruleVersion: energyRulesV2MvpAVersion,
    morningAdjustment: 0,
    shortTermAdjustment: 0,
    initialEstimatedEnergy: 100,
    finalEstimatedEnergy: finalEstimate,
    totalConsumption: 28,
    totalRecovery: 0,
    categorySummaries: {
      ActivityCategory.study: const CategoryEstimatedSummary(
        category: ActivityCategory.study,
        durationMinutes: 60,
        netDelta: -28,
        grossDelta: 28,
      ),
    },
    isStandardEffectiveDay: true,
    isWeakEffectiveDay: false,
    settledAt: testNow,
  );
}

PromptReceipt _receipt({required String id}) {
  return PromptReceipt(
    id: id,
    type: PromptReceiptType.energyBand,
    scopeKey: '2026-07-26:estimatedLow',
    action: PromptReceiptAction.shown,
    occurredAt: testNow,
  );
}
