import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

import '../../support/backup_fixture.dart';
import 'test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = createTestDatabase();
  });

  tearDown(() => database.close());

  test('restore fully replaces existing rows and settings', () async {
    await database
        .into(database.morningCheckInsTable)
        .insert(
          MorningCheckInsTableCompanion.insert(
            id: 'old-morning',
            lifeDay: LifeDay(2026, 8, 8),
            overallState: MorningOverallState.normal,
            freeTimeLevel: FreeTimeLevel.medium,
            pressureSource: PressureSource.low,
            sleepRecovery: SleepRecovery.normal,
            morningAdjustment: 0,
            completedAt: backupFixtureNow,
          ),
        );

    await database.replaceWithBackup(backupFixture(baseEnergy: 120));

    final settings = await database.appSettingsDao.getSettings();
    expect(settings.baseEstimatedEnergy, 120);
    expect(await database.morningCheckInsDao.listAll(), isEmpty);
    expect(await database.ruleConfigVersionsDao.listVersions(), hasLength(1));
    expect(
      await database.customSelect('PRAGMA foreign_key_check').get(),
      isEmpty,
    );
  });

  test(
    'failure after clear rolls back old data and protection triggers',
    () async {
      final day = LifeDay(2026, 8, 8);
      await database
          .into(database.dailySummariesTable)
          .insert(
            DailySummariesTableCompanion.insert(
              lifeDay: day,
              baseEstimatedEnergy: 100,
              ruleVersion: energyRulesV2MvpAVersion,
              morningAdjustment: 0,
              shortTermAdjustment: 0,
              initialEstimatedEnergy: 100,
              finalEstimatedEnergy: 100,
              totalConsumption: 0,
              totalRecovery: 0,
              categorySummaryJson: _emptyCategories(),
              isStandardEffectiveDay: false,
              isWeakEffectiveDay: false,
              settledAt: backupFixtureNow,
            ),
          );

      await expectLater(
        database.replaceWithBackup(
          backupFixture(baseEnergy: 120),
          failureHook: (checkpoint) async {
            if (checkpoint == 'after-clear') throw StateError('injected');
          },
        ),
        throwsStateError,
      );

      expect(
        (await database.appSettingsDao.getSettings()).baseEstimatedEnergy,
        100,
      );
      expect(
        await database.dailySummariesDao.findByLifeDay(day),
        isA<DailySummaryRow>(),
      );
      await expectLater(
        database.delete(database.dailySummariesTable).go(),
        throwsA(anything),
      );
    },
  );

  test('failure after partial insert leaves no new rows', () async {
    await expectLater(
      database.replaceWithBackup(
        backupFixture(baseEnergy: 120),
        failureHook: (checkpoint) async {
          if (checkpoint == 'after-settings') throw StateError('injected');
        },
      ),
      throwsStateError,
    );

    expect(
      (await database.appSettingsDao.getSettings()).baseEstimatedEnergy,
      100,
    );
    expect(await database.ruleConfigVersionsDao.listVersions(), hasLength(1));
  });
}

String _emptyCategories() {
  return '{'
      '"study":{"durationMinutes":0,"netDelta":0,"grossDelta":0},'
      '"practice":{"durationMinutes":0,"netDelta":0,"grossDelta":0},'
      '"recovery":{"durationMinutes":0,"netDelta":0,"grossDelta":0},'
      '"leisure":{"durationMinutes":0,"netDelta":0,"grossDelta":0}'
      '}';
}
