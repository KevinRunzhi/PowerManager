import 'dart:convert';
import 'dart:isolate';

import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/data/export/power_manager_export_dto.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

typedef AppVersionLoader = Future<String> Function();

final class JsonExportResult {
  const JsonExportResult({required this.fileName, required this.contents});

  final String fileName;
  final String contents;
}

abstract interface class JsonExporter {
  Future<JsonExportResult> create({required DateTime exportedAt});
}

final class JsonExportService implements JsonExporter {
  const JsonExportService({
    required this.settings,
    required this.rules,
    required this.mornings,
    required this.activities,
    required this.observations,
    required this.summaries,
    required this.receipts,
    required this.appVersionLoader,
    required this.transactionRunner,
  });

  static const schemaVersion = 1;

  final AppSettingsRepository settings;
  final RuleConfigVersionsRepository rules;
  final MorningCheckInsRepository mornings;
  final ActivityRecordsRepository activities;
  final EnergyObservationsRepository observations;
  final DailySummariesRepository summaries;
  final PromptReceiptsRepository receipts;
  final AppVersionLoader appVersionLoader;
  final TransactionRunner transactionRunner;

  @override
  Future<JsonExportResult> create({required DateTime exportedAt}) async {
    final appVersion = await appVersionLoader();
    final snapshot = await transactionRunner.run(() async {
      final appSettings = await settings.get();
      final ruleVersions = await rules.list();
      final morningCheckIns = await mornings.list();
      final activityRecords = await activities.listAllForExport();
      final energyObservations = await observations.list();
      final dailySummaries = await summaries.list();
      final promptReceipts = await receipts.list();
      return _ExportSnapshot(
        appSettings: appSettings,
        ruleVersions: ruleVersions,
        morningCheckIns: morningCheckIns,
        activityRecords: activityRecords,
        energyObservations: energyObservations,
        dailySummaries: dailySummaries,
        promptReceipts: promptReceipts,
      );
    });
    final dto = PowerManagerExportDto(
      schemaVersion: schemaVersion,
      exportedAt: exportedAt.toUtc(),
      appVersion: appVersion,
      appSettings: snapshot.appSettings,
      ruleVersions: snapshot.ruleVersions,
      morningCheckIns: snapshot.morningCheckIns,
      activityRecords: snapshot.activityRecords,
      energyObservations: snapshot.energyObservations,
      dailySummaries: snapshot.dailySummaries,
      promptReceipts: snapshot.promptReceipts,
    );
    final json = await Isolate.run(_JsonEncodingTask(dto.toJson()).call);
    return JsonExportResult(
      fileName: 'powermanager-${_fileTimestamp(exportedAt.toUtc())}.json',
      contents: json,
    );
  }
}

final class _JsonEncodingTask {
  const _JsonEncodingTask(this.value);

  final Map<String, Object?> value;

  String call() => const JsonEncoder.withIndent('  ').convert(value);
}

final class _ExportSnapshot {
  const _ExportSnapshot({
    required this.appSettings,
    required this.ruleVersions,
    required this.morningCheckIns,
    required this.activityRecords,
    required this.energyObservations,
    required this.dailySummaries,
    required this.promptReceipts,
  });

  final AppSettings appSettings;
  final List<RuleConfigVersion> ruleVersions;
  final List<MorningCheckIn> morningCheckIns;
  final List<StoredEstimatedActivity> activityRecords;
  final List<EnergyObservation> energyObservations;
  final List<DailySummary> dailySummaries;
  final List<PromptReceipt> promptReceipts;
}

String _fileTimestamp(DateTime value) {
  String two(int part) => part.toString().padLeft(2, '0');
  return '${value.year}${two(value.month)}${two(value.day)}'
      '-${two(value.hour)}${two(value.minute)}${two(value.second)}Z';
}
