import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_backup_restore_service.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:test/test.dart';

import '../data/db/test_database.dart';
import '../support/backup_fixture.dart';

void main() {
  late AppDatabase database;
  late JsonBackupRestoreService service;
  late _FailingSafetyStore safetyStore;

  setUp(() {
    database = createTestDatabase();
    safetyStore = _FailingSafetyStore();
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
    final summaries = DriftDailySummariesRepository(database.dailySummariesDao);
    final receipts = DriftPromptReceiptsRepository(database.promptReceiptsDao);
    final export = JsonExportService(
      settings: settings,
      rules: rules,
      mornings: mornings,
      activities: activities,
      observations: observations,
      summaries: summaries,
      receipts: receipts,
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
  });
}

final class _FailingSafetyStore implements BackupSafetyStore {
  var calls = 0;

  @override
  Future<String?> existingPath() async => null;

  @override
  Future<void> save(String contents) async {
    calls++;
    throw StateError('injected safety failure');
  }
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
