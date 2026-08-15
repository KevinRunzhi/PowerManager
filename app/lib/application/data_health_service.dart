import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/application/mvp_b_upgrade_readiness_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/backup/local_backup_store.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

final class DataHealthReport {
  const DataHealthReport({
    required this.checkedAt,
    required this.integrityPassed,
    required this.settledDays,
    required this.standardEffectiveDays,
    required this.weakEffectiveDays,
    required this.effectiveDaysWithActualState,
    required this.morningCheckIns,
    required this.activityRecords,
    required this.deletedActivityRecords,
    required this.dailyActualStates,
    required this.relativeCorrections,
    required this.localBackup,
    required this.mvpBUpgradeReadiness,
  });

  final DateTime checkedAt;
  final bool integrityPassed;
  final int settledDays;
  final int standardEffectiveDays;
  final int weakEffectiveDays;
  final int effectiveDaysWithActualState;
  final int morningCheckIns;
  final int activityRecords;
  final int deletedActivityRecords;
  final int dailyActualStates;
  final int relativeCorrections;
  final LocalBackupMetadata? localBackup;
  final MvpBUpgradeReadinessReport mvpBUpgradeReadiness;

  int get effectiveDays => standardEffectiveDays + weakEffectiveDays;
  int get coveragePercent => effectiveDays == 0
      ? 0
      : (effectiveDaysWithActualState * 100 / effectiveDays).round();
  int get daysUntilLegacyDiscussionCount =>
      math.max(0, 14 - effectiveDaysWithActualState);
  bool get reachedLegacyDiscussionCount => effectiveDaysWithActualState >= 14;
}

final class DataHealthService {
  const DataHealthService({
    required this.exportService,
    required this.codec,
    required this.clock,
    required this.mornings,
    required this.activities,
    required this.observations,
    required this.summaries,
    required this.localBackupStore,
    required this.upgradeReadiness,
  });

  final JsonExporter exportService;
  final JsonBackupCodec codec;
  final Clock clock;
  final MorningCheckInsRepository mornings;
  final ActivityRecordsRepository activities;
  final EnergyObservationsRepository observations;
  final DailySummariesRepository summaries;
  final LocalBackupStore localBackupStore;
  final MvpBUpgradeReadinessChecker upgradeReadiness;

  Future<DataHealthReport> check() async {
    final checkedAt = clock.now();
    final values = await Future.wait<Object?>([
      mornings.list(),
      activities.listAllForExport(),
      observations.list(),
      summaries.list(),
      localBackupStore.metadata(),
      upgradeReadiness.check(),
    ]);
    final morningItems = values[0] as List<MorningCheckIn>;
    final activityItems = values[1] as List<StoredEstimatedActivity>;
    final observationItems = values[2] as List<EnergyObservation>;
    final summaryItems = values[3] as List<DailySummary>;
    final localBackup = values[4] as LocalBackupMetadata?;
    final upgradeReadinessReport = values[5] as MvpBUpgradeReadinessReport;
    var integrityPassed = false;
    try {
      final exported = await exportService.create(exportedAt: checkedAt);
      codec.inspect(
        fileName: exported.fileName,
        bytes: Uint8List.fromList(utf8.encode(exported.contents)),
      );
      integrityPassed = true;
    } on BackupFormatException {
      integrityPassed = false;
    }

    final effectiveLifeDays = {
      for (final summary in summaryItems)
        if (summary.isStandardEffectiveDay || summary.isWeakEffectiveDay)
          summary.lifeDay,
    };
    final actualLifeDays = {
      for (final observation in observationItems)
        if (observation.type == EnergyObservationType.dailyAbsolute)
          observation.lifeDay,
    };
    return DataHealthReport(
      checkedAt: checkedAt,
      integrityPassed: integrityPassed,
      settledDays: summaryItems.length,
      standardEffectiveDays: summaryItems
          .where((item) => item.isStandardEffectiveDay)
          .length,
      weakEffectiveDays: summaryItems
          .where((item) => item.isWeakEffectiveDay)
          .length,
      effectiveDaysWithActualState: effectiveLifeDays
          .intersection(actualLifeDays)
          .length,
      morningCheckIns: morningItems.length,
      activityRecords: activityItems.length,
      deletedActivityRecords: activityItems
          .where((item) => item.status == ActivityRecordStatus.deleted)
          .length,
      dailyActualStates: observationItems
          .where((item) => item.type == EnergyObservationType.dailyAbsolute)
          .length,
      relativeCorrections: observationItems
          .where(
            (item) => item.type == EnergyObservationType.relativeCorrection,
          )
          .length,
      localBackup: localBackup,
      mvpBUpgradeReadiness: upgradeReadinessReport,
    );
  }
}
