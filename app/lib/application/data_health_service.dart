import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/application/mvp_b_upgrade_readiness_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/backup/local_backup_store.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/learning_eligibility_service.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

final class DataHealthReport {
  const DataHealthReport({
    required this.checkedAt,
    required this.schemaVersion,
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
    this.legacyObservations = 0,
    this.contractObservations = 0,
    this.activityFeedback = 0,
    this.activeActivityFeedback = 0,
    this.invalidatedActivityFeedback = 0,
    this.currentMomentContractObservations = 0,
    this.previousLifeDayEndContractObservations = 0,
    this.eligibleCurrentRegimeObservations = 0,
    this.earliestEligibleLifeDay,
    this.latestEligibleLifeDay,
    this.learningExclusionCounts = const {},
    required this.localBackup,
    required this.mvpBUpgradeReadiness,
  });

  final DateTime checkedAt;
  final int schemaVersion;
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
  final int legacyObservations;
  final int contractObservations;
  final int activityFeedback;
  final int activeActivityFeedback;
  final int invalidatedActivityFeedback;
  final int currentMomentContractObservations;
  final int previousLifeDayEndContractObservations;
  final int eligibleCurrentRegimeObservations;
  final LifeDay? earliestEligibleLifeDay;
  final LifeDay? latestEligibleLifeDay;
  final Map<LearningIneligibilityReason, int> learningExclusionCounts;
  final LocalBackupMetadata? localBackup;
  final MvpBUpgradeReadinessReport mvpBUpgradeReadiness;

  int get effectiveDays => standardEffectiveDays + weakEffectiveDays;
  int get coveragePercent => effectiveDays == 0
      ? 0
      : (effectiveDaysWithActualState * 100 / effectiveDays).round();
  int get daysUntilLegacyDiscussionCount =>
      math.max(0, 14 - effectiveDaysWithActualState);
  bool get reachedLegacyDiscussionCount => effectiveDaysWithActualState >= 14;
  int exclusionCount(LearningIneligibilityReason reason) =>
      learningExclusionCounts[reason] ?? 0;
  int get unsettledContractObservations =>
      exclusionCount(LearningIneligibilityReason.unsettledLifeDay);
}

final class DataHealthService {
  const DataHealthService({
    required this.exportService,
    required this.codec,
    required this.clock,
    required this.settings,
    required this.mornings,
    required this.activities,
    required this.observations,
    required this.feedback,
    required this.summaries,
    required this.localBackupStore,
    required this.upgradeReadiness,
    this.eligibilityService = const LearningEligibilityService(),
    this.regimeKeyBuilder = const ModelRegimeKeyBuilder(),
  });

  final JsonExporter exportService;
  final JsonBackupCodec codec;
  final Clock clock;
  final AppSettingsRepository settings;
  final MorningCheckInsRepository mornings;
  final ActivityRecordsRepository activities;
  final EnergyObservationsRepository observations;
  final ActivityFeedbackRepository feedback;
  final DailySummariesRepository summaries;
  final LocalBackupStore localBackupStore;
  final MvpBUpgradeReadinessChecker upgradeReadiness;
  final LearningEligibilityService eligibilityService;
  final ModelRegimeKeyBuilder regimeKeyBuilder;

  Future<DataHealthReport> check() async {
    final checkedAt = clock.now();
    final values = await Future.wait<Object?>([
      mornings.list(),
      activities.listAllForExport(),
      observations.list(),
      feedback.list(),
      summaries.list(),
      localBackupStore.metadata(),
      upgradeReadiness.check(),
      settings.get(),
    ]);
    final morningItems = values[0] as List<MorningCheckIn>;
    final activityItems = values[1] as List<StoredEstimatedActivity>;
    final observationItems = values[2] as List<EnergyObservation>;
    final feedbackItems = values[3] as List<ActivityFeedback>;
    final summaryItems = values[4] as List<DailySummary>;
    final localBackup = values[5] as LocalBackupMetadata?;
    final upgradeReadinessReport = values[6] as MvpBUpgradeReadinessReport;
    final appSettings = values[7] as AppSettings;
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
    final summaryByLifeDay = {
      for (final summary in summaryItems) summary.lifeDay: summary,
    };
    final morningLifeDays = {
      for (final morning in morningItems) morning.lifeDay,
    };
    final dailyObservations = observationItems
        .where((item) => item.type == EnergyObservationType.dailyAbsolute)
        .toList();
    final exclusionCounts = <LearningIneligibilityReason, int>{};
    final eligibleLifeDays = <LifeDay>[];
    for (final observation in dailyObservations) {
      final referenceType = observation.referenceType;
      final expectedModelRegimeKey = referenceType == null
          ? null
          : regimeKeyBuilder.build(
              referenceType: referenceType,
              baseEnergy: appSettings.baseEstimatedEnergy,
              ruleVersion: appSettings.activeRuleVersion,
              comparisonBandVersion: mvpBComparisonBandV1,
              effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
              modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
            );
      final eligibility = eligibilityService.evaluate(
        observation: observation,
        hasMorningCheckIn: morningLifeDays.contains(observation.lifeDay),
        settled: summaryByLifeDay.containsKey(observation.lifeDay),
        expectedModelRegimeKey: expectedModelRegimeKey,
      );
      if (eligibility.eligible) {
        eligibleLifeDays.add(observation.lifeDay);
      }
      for (final reason in eligibility.reasonCodes) {
        exclusionCounts.update(reason, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    eligibleLifeDays.sort();
    final currentMomentContractObservations = dailyObservations
        .where(
          (item) =>
              item.contractVersion == mvpBObservationContractV1 &&
              item.referenceType == ObservationReferenceType.currentMoment,
        )
        .length;
    final previousLifeDayEndContractObservations = dailyObservations
        .where(
          (item) =>
              item.contractVersion == mvpBObservationContractV1 &&
              item.referenceType == ObservationReferenceType.previousLifeDayEnd,
        )
        .length;
    return DataHealthReport(
      checkedAt: checkedAt,
      schemaVersion: JsonExportService.schemaVersion,
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
      legacyObservations: observationItems
          .where((item) => item.contractVersion == null)
          .length,
      contractObservations:
          currentMomentContractObservations +
          previousLifeDayEndContractObservations,
      activityFeedback: feedbackItems.length,
      activeActivityFeedback: feedbackItems
          .where((item) => item.status == ActivityFeedbackStatus.active)
          .length,
      invalidatedActivityFeedback: feedbackItems
          .where((item) => item.status == ActivityFeedbackStatus.invalidated)
          .length,
      currentMomentContractObservations: currentMomentContractObservations,
      previousLifeDayEndContractObservations:
          previousLifeDayEndContractObservations,
      eligibleCurrentRegimeObservations: eligibleLifeDays.length,
      earliestEligibleLifeDay: eligibleLifeDays.firstOrNull,
      latestEligibleLifeDay: eligibleLifeDays.lastOrNull,
      learningExclusionCounts: Map.unmodifiable(exclusionCounts),
      localBackup: localBackup,
      mvpBUpgradeReadiness: upgradeReadinessReport,
    );
  }
}
