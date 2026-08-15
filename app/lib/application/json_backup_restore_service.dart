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
    required this.feedback,
    required this.learningRuns,
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
  final ActivityFeedbackRepository feedback;
  final LearningRunsRepository learningRuns;
  final DailySummariesRepository summaries;
  final PromptReceiptsRepository receipts;

  BackupInspection inspect({
    required String fileName,
    required Uint8List bytes,
  }) => codec.inspect(fileName: fileName, bytes: bytes);

  Future<BackupDataCounts> currentCounts() async {
    return database.transaction(() async {
      final ruleVersions = await rules.list();
      final morningCheckIns = await mornings.list();
      final activityRecords = await activities.listAllForExport();
      final energyObservations = await observations.list();
      final activityFeedback = await feedback.list();
      final learningRunItems = await learningRuns.list();
      final dailySummaries = await summaries.list();
      final promptReceipts = await receipts.list();
      return BackupDataCounts(
        ruleVersions: ruleVersions.length,
        morningCheckIns: morningCheckIns.length,
        activityRecords: activityRecords.length,
        energyObservations: energyObservations.length,
        activityFeedback: activityFeedback.length,
        learningRuns: learningRunItems.length,
        dailySummaries: dailySummaries.length,
        promptReceipts: promptReceipts.length,
      );
    });
  }

  Future<void> restore(BackupInspection inspection) async {
    await database.transaction(() async {
      final safety = await exportService.create(exportedAt: clock.now());
      await safetyStore.save(safety.contents);
      await database.replaceWithBackup(inspection.backup);
    });
  }
}
