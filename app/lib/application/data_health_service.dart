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
import 'package:power_manager/domain/learning/shadow_learning.dart';
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
    this.learningRuns = 0,
    this.retryableLearningRuns = 0,
    this.terminalLearningRuns = 0,
    this.automaticLearningProgress = const [],
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
  final int learningRuns;
  final int retryableLearningRuns;
  final int terminalLearningRuns;
  final List<AutomaticLearningProgress> automaticLearningProgress;
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

final class AutomaticLearningProgress {
  AutomaticLearningProgress({
    required this.referenceType,
    required this.sourceModelIdentity,
    required this.eligibleTotal,
    required this.selectedEligible,
    required this.excludedTotal,
    required this.missingToMinimum,
    required this.spanCalendarDays,
    required this.earliestLifeDay,
    required this.latestLifeDay,
    required this.directionCounts,
    required List<DirectionCounts> windowDirectionCounts,
    required List<int> windowSizes,
    required Map<LearningIneligibilityReason, int> exclusionCounts,
    required this.ready,
    required this.latestRunStatus,
    required this.latestRunResult,
    required this.latestRunAt,
    required this.latestRunMatchesCurrentEvidence,
  }) : windowDirectionCounts = List.unmodifiable(windowDirectionCounts),
       windowSizes = List.unmodifiable(windowSizes),
       exclusionCounts = Map.unmodifiable(exclusionCounts);

  final ObservationReferenceType referenceType;
  final String sourceModelIdentity;
  final int eligibleTotal;
  final int selectedEligible;
  final int excludedTotal;
  final int missingToMinimum;
  final int spanCalendarDays;
  final LifeDay? earliestLifeDay;
  final LifeDay? latestLifeDay;
  final DirectionCounts directionCounts;
  final List<DirectionCounts> windowDirectionCounts;
  final List<int> windowSizes;
  final Map<LearningIneligibilityReason, int> exclusionCounts;
  final bool ready;
  final LearningRunStatus? latestRunStatus;
  final LearningRunResult? latestRunResult;
  final DateTime? latestRunAt;
  final bool latestRunMatchesCurrentEvidence;

  int get firstWindowSize => windowSizes.firstOrNull ?? 0;
  int get secondWindowSize => windowSizes.length < 2 ? 0 : windowSizes[1];
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
    required this.learningRuns,
    required this.personalizationVersions,
    required this.summaries,
    required this.localBackupStore,
    required this.upgradeReadiness,
    this.eligibilityService = const LearningEligibilityService(),
    this.regimeKeyBuilder = const ModelRegimeKeyBuilder(),
    this.evidenceBuilder = const ShadowEvidenceBuilder(),
  });

  final JsonExporter exportService;
  final JsonBackupCodec codec;
  final Clock clock;
  final AppSettingsRepository settings;
  final MorningCheckInsRepository mornings;
  final ActivityRecordsRepository activities;
  final EnergyObservationsRepository observations;
  final ActivityFeedbackRepository feedback;
  final LearningRunsRepository learningRuns;
  final PersonalizationVersionsRepository personalizationVersions;
  final DailySummariesRepository summaries;
  final LocalBackupStore localBackupStore;
  final MvpBUpgradeReadinessChecker upgradeReadiness;
  final LearningEligibilityService eligibilityService;
  final ModelRegimeKeyBuilder regimeKeyBuilder;
  final ShadowEvidenceBuilder evidenceBuilder;

  Future<DataHealthReport> check() async {
    final checkedAt = clock.now();
    final values = await Future.wait<Object?>([
      mornings.list(),
      activities.listAllForExport(),
      observations.list(),
      feedback.list(),
      learningRuns.list(),
      summaries.list(),
      localBackupStore.metadata(),
      upgradeReadiness.check(),
      settings.get(),
      personalizationVersions.getActive(),
    ]);
    final morningItems = values[0] as List<MorningCheckIn>;
    final activityItems = values[1] as List<StoredEstimatedActivity>;
    final observationItems = values[2] as List<EnergyObservation>;
    final feedbackItems = values[3] as List<ActivityFeedback>;
    final learningRunItems = values[4] as List<LearningRun>;
    final summaryItems = values[5] as List<DailySummary>;
    final localBackup = values[6] as LocalBackupMetadata?;
    final upgradeReadinessReport = values[7] as MvpBUpgradeReadinessReport;
    final appSettings = values[8] as AppSettings;
    final activeModel = values[9] as PersonalizationVersion;
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
              baseEnergy: activeModel.baseEnergy,
              ruleVersion: appSettings.activeRuleVersion,
              comparisonBandVersion: mvpBComparisonBandV1,
              effectiveModelFingerprint: activeModel.effectiveModelFingerprint,
              modelRegimeEpoch: activeModel.modelRegimeEpoch,
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
    final shadowConfig = ShadowLearningConfig.evidenceReadinessV1();
    final evidenceBySource = {
      for (final evidence in evidenceBuilder.buildAll(
        observations: observationItems,
        morningLifeDays: morningLifeDays,
        settledLifeDays: summaryByLifeDay.keys.toSet(),
        config: shadowConfig,
      ))
        evidence.sourceModelIdentity: evidence,
    };
    final currentRegimeByReference = {
      for (final referenceType in ObservationReferenceType.values)
        referenceType: regimeKeyBuilder.build(
          referenceType: referenceType,
          baseEnergy: activeModel.baseEnergy,
          ruleVersion: appSettings.activeRuleVersion,
          comparisonBandVersion: mvpBComparisonBandV1,
          effectiveModelFingerprint: activeModel.effectiveModelFingerprint,
          modelRegimeEpoch: activeModel.modelRegimeEpoch,
        ),
    };
    final latestRunBySource = <String, LearningRun>{};
    for (final run in learningRunItems) {
      if (run.parameterFamily != LearningParameterFamily.baseline) continue;
      final previous = latestRunBySource[run.sourceModelIdentity];
      if (previous == null ||
          run.triggeredAt.isAfter(previous.triggeredAt) ||
          (run.triggeredAt == previous.triggeredAt &&
              run.id.compareTo(previous.id) > 0)) {
        latestRunBySource[run.sourceModelIdentity] = run;
      }
    }
    final automaticProgress = <AutomaticLearningProgress>[];
    for (final referenceType in ObservationReferenceType.values) {
      final sourceModelIdentity = currentRegimeByReference[referenceType]!;
      final evidence = evidenceBySource[sourceModelIdentity];
      final latestRun = latestRunBySource[sourceModelIdentity];
      automaticProgress.add(
        AutomaticLearningProgress(
          referenceType: referenceType,
          sourceModelIdentity: sourceModelIdentity,
          eligibleTotal: evidence?.eligibleTotal ?? 0,
          selectedEligible: evidence?.selectedEligible ?? 0,
          excludedTotal: evidence?.excludedTotal ?? 0,
          missingToMinimum:
              evidence?.missingToMinimum ??
              shadowConfig.minimumEligibleObservationPairs,
          spanCalendarDays: evidence?.readiness.spanCalendarDays ?? 0,
          earliestLifeDay: evidence?.earliestLifeDay,
          latestLifeDay: evidence?.latestLifeDay,
          directionCounts:
              evidence?.directionCounts ?? const DirectionCounts.empty(),
          windowDirectionCounts:
              evidence?.windowDirectionCounts ?? const <DirectionCounts>[],
          windowSizes: evidence?.windowSizes ?? const <int>[],
          exclusionCounts:
              evidence?.exclusionCounts ??
              const <LearningIneligibilityReason, int>{},
          ready: evidence?.readiness.ready ?? false,
          latestRunStatus: latestRun?.status,
          latestRunResult: latestRun?.result,
          latestRunAt: latestRun?.completedAt ?? latestRun?.triggeredAt,
          latestRunMatchesCurrentEvidence:
              evidence != null &&
              latestRun?.evidenceHash == evidence.evidenceHash,
        ),
      );
    }
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
      learningRuns: learningRunItems.length,
      retryableLearningRuns: learningRunItems
          .where((item) => item.status == LearningRunStatus.retryableFailure)
          .length,
      terminalLearningRuns: learningRunItems
          .where((item) => item.status == LearningRunStatus.terminalFailure)
          .length,
      automaticLearningProgress: List.unmodifiable(automaticProgress),
      localBackup: localBackup,
      mvpBUpgradeReadiness: upgradeReadinessReport,
    );
  }
}
