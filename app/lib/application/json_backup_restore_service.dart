import 'dart:typed_data';

import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

abstract interface class BackupSafetyStore {
  Future<void> save(String contents);
  Future<String?> existingPath();
}

final class JsonBackupRestoreService {
  const JsonBackupRestoreService({
    required this.codec,
    required this.exportService,
    required this.database,
    required this.safetyStore,
    required this.clock,
    required this.rules,
    required this.mornings,
    required this.activities,
    required this.observations,
    required this.summaries,
    required this.receipts,
  });

  final JsonBackupCodec codec;
  final JsonExportService exportService;
  final AppDatabase database;
  final BackupSafetyStore safetyStore;
  final Clock clock;
  final RuleConfigVersionsRepository rules;
  final MorningCheckInsRepository mornings;
  final ActivityRecordsRepository activities;
  final EnergyObservationsRepository observations;
  final DailySummariesRepository summaries;
  final PromptReceiptsRepository receipts;

  BackupInspection inspect({
    required String fileName,
    required Uint8List bytes,
  }) => codec.inspect(fileName: fileName, bytes: bytes);

  Future<BackupDataCounts> currentCounts() async {
    final values = await Future.wait<List<Object>>([
      rules.list(),
      mornings.list(),
      activities.listAllForExport(),
      observations.list(),
      summaries.list(),
      receipts.list(),
    ]);
    return BackupDataCounts(
      ruleVersions: values[0].length,
      morningCheckIns: values[1].length,
      activityRecords: values[2].length,
      energyObservations: values[3].length,
      dailySummaries: values[4].length,
      promptReceipts: values[5].length,
    );
  }

  Future<void> restore(BackupInspection inspection) async {
    final safety = await exportService.create(exportedAt: clock.now());
    await safetyStore.save(safety.contents);
    await database.replaceWithBackup(inspection.backup);
  }
}
