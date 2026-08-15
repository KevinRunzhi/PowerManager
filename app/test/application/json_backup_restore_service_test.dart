import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_backup_restore_service.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/db/drift_transaction_runner.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:test/test.dart';

import '../data/db/test_database.dart';
import '../support/backup_fixture.dart';

void main() {
  late AppDatabase database;
  late JsonBackupRestoreService service;
  late _RecordingSafetyStore safetyStore;

  setUp(() {
    database = createTestDatabase();
    safetyStore = _RecordingSafetyStore(fail: true);
    final settings = DriftAppSettingsRepository(database.appSettingsDao);
    final rules = DriftRuleConfigVersionsRepository(
      database.ruleConfigVersionsDao,
    );
    final mornings = DriftMorningCheckInsRepository(
      database.morningCheckInsDao,
    );
    final activities = DriftActivityRecordsRepository(
      database.activityRecordsDao,
    );
    final observations = DriftEnergyObservationsRepository(
      database.energyObservationsDao,
    );
    final feedback = DriftActivityFeedbackRepository(
      database.activityFeedbackDao,
    );
    final learningRuns = DriftLearningRunsRepository(database.learningRunsDao);
    final summaries = DriftDailySummariesRepository(database.dailySummariesDao);
    final receipts = DriftPromptReceiptsRepository(database.promptReceiptsDao);
    final export = JsonExportService(
      settings: settings,
      rules: rules,
      mornings: mornings,
      activities: activities,
      observations: observations,
      feedback: feedback,
      learningRuns: learningRuns,
      summaries: summaries,
      receipts: receipts,
      transactionRunner: DriftTransactionRunner(database),
      appVersionLoader: () async => 'test',
    );
    service = JsonBackupRestoreService(
      codec: const JsonBackupCodec(),
      exportService: export,
      database: database,
      safetyStore: safetyStore,
      clock: _FixedClock(backupFixtureNow),
      rules: rules,
      mornings: mornings,
      activities: activities,
      observations: observations,
      feedback: feedback,
      learningRuns: learningRuns,
      summaries: summaries,
      receipts: receipts,
    );
  });

  tearDown(() => database.close());

  test('safety snapshot failure prevents every restore write', () async {
    final backup = backupFixture(baseEnergy: 120);
    final inspection = service.inspect(
      fileName: 'backup.json',
      bytes: Uint8List.fromList(utf8.encode(jsonEncode(backup.toJson()))),
    );

    await expectLater(service.restore(inspection), throwsStateError);

    expect(safetyStore.calls, 1);
    expect(
      (await database.appSettingsDao.getSettings()).baseEstimatedEnergy,
      100,
    );
  });

  test('current preview counts include settings and the seeded rule', () async {
    final counts = await service.currentCounts();

    expect(counts.ruleVersions, 1);
    expect(counts.total, 2);
    expect(counts.activityFeedback, 0);
    expect(counts.learningRuns, 0);
  });

  test(
    'successful restore saves the old snapshot and replaces atomically',
    () async {
      safetyStore.fail = false;
      final backup = backupFixture(baseEnergy: 120);
      final inspection = service.inspect(
        fileName: 'backup.json',
        bytes: Uint8List.fromList(utf8.encode(jsonEncode(backup.toJson()))),
      );

      await service.restore(inspection);

      expect(safetyStore.calls, 1);
      expect(safetyStore.contents, contains('"baseEstimatedEnergy": 100'));
      expect(
        (await database.appSettingsDao.getSettings()).baseEstimatedEnergy,
        120,
      );
      final exported = await service.exportService.create(
        exportedAt: backupFixtureNow,
      );
      final reparsed = service.inspect(
        fileName: exported.fileName,
        bytes: Uint8List.fromList(utf8.encode(exported.contents)),
      );
      expect(reparsed.backup.schemaVersion, 3);
      expect(reparsed.backup.learningRuns, isEmpty);
      expect(reparsed.backup.energyObservations, isEmpty);
    },
  );

  test('schema v2 service restore round-trips invalidated feedback', () async {
    safetyStore.fail = false;
    final inspection = service.inspect(
      fileName: 'backup-v2.json',
      bytes: Uint8List.fromList(
        utf8.encode(jsonEncode(backupFixtureV2().toJson())),
      ),
    );

    await service.restore(inspection);

    final counts = await service.currentCounts();
    expect(counts.activityFeedback, 2);
    final exported = await service.exportService.create(
      exportedAt: backupFixtureNow,
    );
    final reparsed = service.inspect(
      fileName: exported.fileName,
      bytes: Uint8List.fromList(utf8.encode(exported.contents)),
    );
    expect(reparsed.backup.activityFeedback, hasLength(2));
    expect(
      reparsed.backup.activityFeedback.last.status,
      ActivityFeedbackStatus.invalidated,
    );
  });

  test('schema v3 service restore round-trips shadow learning runs', () async {
    safetyStore.fail = false;
    final inspection = service.inspect(
      fileName: 'backup-v3.json',
      bytes: Uint8List.fromList(
        utf8.encode(jsonEncode(backupFixtureV3().toJson())),
      ),
    );

    await service.restore(inspection);

    final counts = await service.currentCounts();
    expect(counts.learningRuns, 1);
    final exported = await service.exportService.create(
      exportedAt: backupFixtureNow,
    );
    final reparsed = service.inspect(
      fileName: exported.fileName,
      bytes: Uint8List.fromList(utf8.encode(exported.contents)),
    );
    expect(reparsed.backup.learningRuns, hasLength(1));
    expect(
      reparsed.backup.learningRuns.single.evidenceHash,
      backupFixtureV3().learningRuns.single.evidenceHash,
    );
  });
}

final class _RecordingSafetyStore implements BackupSafetyStore {
  _RecordingSafetyStore({required this.fail});

  bool fail;
  var calls = 0;
  String? contents;

  @override
  Future<String?> existingPath() async => null;

  @override
  Future<void> save(String contents) async {
    calls++;
    if (fail) {
      throw StateError('injected safety failure');
    }
    this.contents = contents;
  }
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
