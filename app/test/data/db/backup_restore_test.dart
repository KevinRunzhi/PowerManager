import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/export/power_manager_export_dto.dart';
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

    await database.replaceWithBackup(
      _normalized(backupFixture(baseEnergy: 120)),
    );

    expect(
      (await database.personalizationVersionsDao.getActive()).baseEnergy,
      120,
    );
    expect(await database.morningCheckInsDao.listAll(), isEmpty);
    expect(await database.ruleConfigVersionsDao.listVersions(), hasLength(1));
    expect(
      await database.customSelect('PRAGMA foreign_key_check').get(),
      isEmpty,
    );
  });

  test('schema v2 restore preserves active and invalidated feedback', () async {
    final backup = _normalized(backupFixtureV2(baseEnergy: 120));

    await database.replaceWithBackup(backup);

    expect(
      (await database.personalizationVersionsDao.getActive()).baseEnergy,
      120,
    );
    expect(await database.activityRecordsDao.listAllForExport(), hasLength(2));
    final feedback = await database.activityFeedbackDao.listAll();
    expect(feedback, hasLength(2));
    expect(
      feedback.where((item) => item.status == ActivityFeedbackStatus.active),
      hasLength(1),
    );
    expect(
      feedback
          .where((item) => item.status == ActivityFeedbackStatus.invalidated)
          .single
          .invalidationReason,
      ActivityFeedbackInvalidationReason.activityDeleted,
    );
    final observations = await database.energyObservationsDao.listAll();
    expect(observations, hasLength(2));
    expect(observations.first.contractVersion, mvpBObservationContractV1);
  });

  test(
    'schema v3 restore preserves and protects shadow learning runs',
    () async {
      final source = backupFixtureV3(baseEnergy: 120);
      final backup = _normalized(source);

      await database.replaceWithBackup(backup);

      final runs = await database.learningRunsDao.listAll();
      expect(runs, hasLength(1));
      expect(runs.single.evidenceHash, source.learningRuns.single.evidenceHash);
      await expectLater(
        database.learningRunsDao.updateById(
          runs.single.id,
          const LearningRunsTableCompanion(
            status: Value(LearningRunStatus.running),
          ),
        ),
        throwsA(anything),
      );
    },
  );

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
              modelSnapshotSource: DailySummaryModelSnapshotSource.legacyInline,
              settledAt: backupFixtureNow,
            ),
          );

      await expectLater(
        database.replaceWithBackup(
          _normalized(backupFixture(baseEnergy: 120)),
          failureHook: (checkpoint) async {
            if (checkpoint == 'after-clear') throw StateError('injected');
          },
        ),
        throwsStateError,
      );

      expect(
        (await database.personalizationVersionsDao.getActive()).baseEnergy,
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
        _normalized(backupFixture(baseEnergy: 120)),
        failureHook: (checkpoint) async {
          if (checkpoint == 'after-settings') throw StateError('injected');
        },
      ),
      throwsStateError,
    );

    expect(
      (await database.personalizationVersionsDao.getActive()).baseEnergy,
      100,
    );
    expect(await database.ruleConfigVersionsDao.listVersions(), hasLength(1));
  });

  test(
    'failure after feedback rolls back rows and restores triggers',
    () async {
      await expectLater(
        database.replaceWithBackup(
          _normalized(backupFixtureV2(baseEnergy: 120)),
          failureHook: (checkpoint) async {
            if (checkpoint == 'after-feedback') throw StateError('injected');
          },
        ),
        throwsStateError,
      );

      expect(
        (await database.personalizationVersionsDao.getActive()).baseEnergy,
        100,
      );
      expect(await database.activityFeedbackDao.listAll(), isEmpty);
      await expectLater(
        database.customStatement('DELETE FROM app_settings'),
        throwsA(anything),
      );
    },
  );

  test(
    'failure after learning runs rolls back and restores protection',
    () async {
      await expectLater(
        database.replaceWithBackup(
          _normalized(backupFixtureV3(baseEnergy: 120)),
          failureHook: (checkpoint) async {
            if (checkpoint == 'after-learning-runs') {
              throw StateError('injected');
            }
          },
        ),
        throwsStateError,
      );

      expect(await database.learningRunsDao.listAll(), isEmpty);
      expect(
        (await database.personalizationVersionsDao.getActive()).baseEnergy,
        100,
      );
    },
  );
}

PowerManagerExportDto _normalized(PowerManagerExportDto backup) {
  return const JsonBackupCodec()
      .inspect(
        fileName: 'backup.json',
        bytes: Uint8List.fromList(utf8.encode(jsonEncode(backup.toJson()))),
      )
      .backup;
}

String _emptyCategories() {
  return '{'
      '"study":{"durationMinutes":0,"netDelta":0,"grossDelta":0},'
      '"practice":{"durationMinutes":0,"netDelta":0,"grossDelta":0},'
      '"recovery":{"durationMinutes":0,"netDelta":0,"grossDelta":0},'
      '"leisure":{"durationMinutes":0,"netDelta":0,"grossDelta":0}'
      '}';
}
