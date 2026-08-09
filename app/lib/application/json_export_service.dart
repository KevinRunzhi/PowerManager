import 'dart:convert';
import 'dart:isolate';

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

  @override
  Future<JsonExportResult> create({required DateTime exportedAt}) async {
    final values = await Future.wait<Object>([
      settings.get(),
      rules.list(),
      mornings.list(),
      activities.listAllForExport(),
      observations.list(),
      summaries.list(),
      receipts.list(),
      appVersionLoader(),
    ]);
    final dto = PowerManagerExportDto(
      schemaVersion: schemaVersion,
      exportedAt: exportedAt.toUtc(),
      appVersion: values[7] as String,
      appSettings: values[0] as AppSettings,
      ruleVersions: values[1] as List<RuleConfigVersion>,
      morningCheckIns: values[2] as List<MorningCheckIn>,
      activityRecords: values[3] as List<StoredEstimatedActivity>,
      energyObservations: values[4] as List<EnergyObservation>,
      dailySummaries: values[5] as List<DailySummary>,
      promptReceipts: values[6] as List<PromptReceipt>,
    );
    final json = await Isolate.run(
      () => const JsonEncoder.withIndent('  ').convert(dto.toJson()),
    );
    return JsonExportResult(
      fileName: 'powermanager-${_fileTimestamp(exportedAt.toUtc())}.json',
      contents: json,
    );
  }
}

String _fileTimestamp(DateTime value) {
  String two(int part) => part.toString().padLeft(2, '0');
  return '${value.year}${two(value.month)}${two(value.day)}'
      '-${two(value.hour)}${two(value.minute)}${two(value.second)}Z';
}
