import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/domain/repositories/repositories.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';

abstract interface class BackupSafetyStore {
  Future<void> save(String contents);
  Future<String?> existingPath();
}

typedef PostRestorePreparation = Future<void> Function();

final class BackupRestoreResult {
  const BackupRestoreResult({required this.postRestoreChecksPassed});

  final bool postRestoreChecksPassed;
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
    this.activityFactors,
    this.activityFeedbackSamples,
    required this.learningRuns,
    required this.personalizationVersions,
    required this.learningConsents,
    required this.learningNotices,
    required this.summaries,
    required this.receipts,
    required this.postRestorePreparation,
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
  final PersonalizationActivityFactorsRepository? activityFactors;
  final ActivityFeedbackSamplesRepository? activityFeedbackSamples;
  final LearningRunsRepository learningRuns;
  final PersonalizationVersionsRepository personalizationVersions;
  final LearningConsentsRepository learningConsents;
  final LearningNoticesRepository learningNotices;
  final DailySummariesRepository summaries;
  final PromptReceiptsRepository receipts;
  final PostRestorePreparation postRestorePreparation;

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
      final activityFactorItems = activityFactors == null
          ? const <PersonalizationActivityFactor>[]
          : await activityFactors!.list();
      final activityFeedbackSampleItems = activityFeedbackSamples == null
          ? const <ActivityFeedbackSample>[]
          : await activityFeedbackSamples!.list();
      final learningRunItems = await learningRuns.list();
      final personalizationVersionItems = await personalizationVersions.list();
      final learningConsentItems = await learningConsents.list();
      final learningNoticeItems = await learningNotices.list();
      final dailySummaries = await summaries.list();
      final promptReceipts = await receipts.list();
      return BackupDataCounts(
        ruleVersions: ruleVersions.length,
        morningCheckIns: morningCheckIns.length,
        activityRecords: activityRecords.length,
        energyObservations: energyObservations.length,
        activityFeedback: activityFeedback.length,
        activityFactors: activityFactorItems.length,
        activityFeedbackSamples: activityFeedbackSampleItems.length,
        learningRuns: learningRunItems.length,
        personalizationVersions: personalizationVersionItems.length,
        learningConsents: learningConsentItems.length,
        learningNotices: learningNoticeItems.length,
        dailySummaries: dailySummaries.length,
        promptReceipts: promptReceipts.length,
      );
    });
  }

  Future<BackupRestoreResult> restore(BackupInspection inspection) async {
    await database.transaction(() async {
      final safety = await exportService.create(exportedAt: clock.now());
      await safetyStore.save(safety.contents);
      await database.replaceWithBackup(inspection.backup);
    });
    try {
      await postRestorePreparation();
      final verified = await exportService.create(exportedAt: clock.now());
      codec.inspect(
        fileName: verified.fileName,
        bytes: Uint8List.fromList(utf8.encode(verified.contents)),
      );
      return const BackupRestoreResult(postRestoreChecksPassed: true);
    } on Object {
      return const BackupRestoreResult(postRestoreChecksPassed: false);
    }
  }
}
