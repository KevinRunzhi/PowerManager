import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/application/activity_feedback_use_cases.dart';
import 'package:power_manager/application/activity_impact_preview_service.dart';
import 'package:power_manager/application/activity_use_cases.dart';
import 'package:power_manager/application/automatic_learning_coordinator.dart';
import 'package:power_manager/application/baseline_monitoring_coordinator.dart';
import 'package:power_manager/application/backup_content_digest.dart';
import 'package:power_manager/application/business_write_coordinator.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/data_health_service.dart';
import 'package:power_manager/application/energy_reminder_service.dart';
import 'package:power_manager/application/energy_rule_config_loader.dart';
import 'package:power_manager/application/history_review_service.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/application/local_backup_service.dart';
import 'package:power_manager/application/model_activation_service.dart';
import 'package:power_manager/application/mvp_b_upgrade_readiness_service.dart';
import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_backup_restore_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/settlement_service.dart';
import 'package:power_manager/application/settings_service.dart';
import 'package:power_manager/application/wellbeing_use_cases.dart';
import 'package:power_manager/core/ids/record_id_generator.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/db/app_database_connection.dart';
import 'package:power_manager/data/db/drift_transaction_runner.dart';
import 'package:power_manager/data/backup/local_backup_safety_store.dart';
import 'package:power_manager/data/backup/local_backup_store.dart';
import 'package:power_manager/data/backup/mvp_b_upgrade_readiness_store.dart';
import 'package:power_manager/data/export/temporary_export_file_store.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/baseline_production_learner.dart';
import 'package:power_manager/domain/learning/baseline_monitoring.dart';
import 'package:power_manager/domain/life_day/life_day_calculator.dart';
import 'package:power_manager/domain/repositories/repositories.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

final clockProvider = Provider<Clock>((ref) {
  const fixedNow = String.fromEnvironment('POWER_MANAGER_FIXED_NOW');
  return createAppClock(allowFixedOverride: !kReleaseMode, fixedNow: fixedNow);
});

final recordIdGeneratorProvider = Provider<RecordIdGenerator>((ref) {
  return RecordIdGenerator();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = openAppDatabase(clock: ref.watch(clockProvider));
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final settingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return DriftAppSettingsRepository(
    ref.watch(appDatabaseProvider).appSettingsDao,
  );
});

final rulesRepositoryProvider = Provider<RuleConfigVersionsRepository>((ref) {
  return DriftRuleConfigVersionsRepository(
    ref.watch(appDatabaseProvider).ruleConfigVersionsDao,
  );
});

final morningsRepositoryProvider = Provider<MorningCheckInsRepository>((ref) {
  return DriftMorningCheckInsRepository(
    ref.watch(appDatabaseProvider).morningCheckInsDao,
  );
});

final activitiesRepositoryProvider = Provider<ActivityRecordsRepository>((ref) {
  return DriftActivityRecordsRepository(
    ref.watch(appDatabaseProvider).activityRecordsDao,
  );
});

final observationsRepositoryProvider = Provider<EnergyObservationsRepository>((
  ref,
) {
  return DriftEnergyObservationsRepository(
    ref.watch(appDatabaseProvider).energyObservationsDao,
  );
});

final activityFeedbackRepositoryProvider = Provider<ActivityFeedbackRepository>(
  (ref) {
    return DriftActivityFeedbackRepository(
      ref.watch(appDatabaseProvider).activityFeedbackDao,
    );
  },
);

final learningRunsRepositoryProvider = Provider<LearningRunsRepository>((ref) {
  return DriftLearningRunsRepository(
    ref.watch(appDatabaseProvider).learningRunsDao,
  );
});

final personalizationVersionsRepositoryProvider =
    Provider<PersonalizationVersionsRepository>((ref) {
      return DriftPersonalizationVersionsRepository(
        ref.watch(appDatabaseProvider).personalizationVersionsDao,
      );
    });

final learningConsentsRepositoryProvider = Provider<LearningConsentsRepository>(
  (ref) {
    return DriftLearningConsentsRepository(
      ref.watch(appDatabaseProvider).learningConsentsDao,
    );
  },
);

final learningNoticesRepositoryProvider = Provider<LearningNoticesRepository>((
  ref,
) {
  return DriftLearningNoticesRepository(
    ref.watch(appDatabaseProvider).learningNoticesDao,
  );
});

final learningProductionGateProvider = Provider<LearningProductionGate>((ref) {
  return const LearningProductionGate.closed();
});

/// No production configuration is constructed by the formal app provider.
/// Pre-production lifecycle tests override this provider with the explicitly
/// watermarked configuration and an isolated database.
final baselineProductionConfigProvider = Provider<BaselineProductionConfig?>(
  (ref) => null,
);

/// Formal providers keep post-activation monitoring disabled. A pre-production
/// harness must override this with the explicitly watermarked configuration.
final baselineMonitoringConfigProvider = Provider<BaselineMonitoringConfig?>(
  (ref) => null,
);

final modelActivationServiceProvider = Provider<ModelActivationService>((ref) {
  return ModelActivationService(
    transactionRunner: DriftTransactionRunner(ref.watch(appDatabaseProvider)),
    settings: ref.watch(settingsRepositoryProvider),
    versions: ref.watch(personalizationVersionsRepositoryProvider),
    learningRuns: ref.watch(learningRunsRepositoryProvider),
    consents: ref.watch(learningConsentsRepositoryProvider),
    notices: ref.watch(learningNoticesRepositoryProvider),
    productionGate: ref.watch(learningProductionGateProvider),
  );
});

final businessWriteCoordinatorProvider = Provider<BusinessWriteCoordinator>((
  ref,
) {
  return SerialBusinessWriteCoordinator();
});

final activityFeedbackMaintenanceProvider =
    Provider<ActivityFeedbackMaintenance>((ref) {
      return ActivityFeedbackMaintenance(
        ref.watch(activityFeedbackRepositoryProvider),
      );
    });

final summariesRepositoryProvider = Provider<DailySummariesRepository>((ref) {
  return DriftDailySummariesRepository(
    ref.watch(appDatabaseProvider).dailySummariesDao,
  );
});

final receiptsRepositoryProvider = Provider<PromptReceiptsRepository>((ref) {
  return DriftPromptReceiptsRepository(
    ref.watch(appDatabaseProvider).promptReceiptsDao,
  );
});

final projectionServiceProvider = Provider<CurrentDayProjectionService>((ref) {
  return CurrentDayProjectionService(
    morningCheckIns: ref.watch(morningsRepositoryProvider),
    activities: ref.watch(activitiesRepositoryProvider),
    summaries: ref.watch(summariesRepositoryProvider),
  );
});

final operationPreparerProvider = Provider<OperationPreparer>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  final mornings = ref.watch(morningsRepositoryProvider);
  final activities = ref.watch(activitiesRepositoryProvider);
  final observations = ref.watch(observationsRepositoryProvider);
  final summaries = ref.watch(summariesRepositoryProvider);
  final projectionService = ref.watch(projectionServiceProvider);

  return OperationPreparationService(
    clock: ref.watch(clockProvider),
    lifeDayCalculator: LifeDayCalculator(),
    transactionRunner: DriftTransactionRunner(database),
    settings: settings,
    personalizationVersions: ref.watch(
      personalizationVersionsRepositoryProvider,
    ),
    modelActivationService: ref.watch(modelActivationServiceProvider),
    settlementService: SettlementService(
      morningCheckIns: mornings,
      activities: activities,
      observations: observations,
      summaries: summaries,
      projectionService: projectionService,
    ),
    projectionService: projectionService,
  );
});

final currentPreparationRefreshProvider =
    NotifierProvider<
      CurrentPreparationRefreshNotifier,
      PreparationRefreshRequest
    >(CurrentPreparationRefreshNotifier.new);

final preparationLearningRequestGateProvider =
    Provider<PreparationLearningRequestGate>((ref) {
      return PreparationLearningRequestGate();
    });

final class PreparationLearningRequestGate {
  var _lastClaimedRevision = -1;

  bool claim(int revision) {
    if (revision <= _lastClaimedRevision) return false;
    _lastClaimedRevision = revision;
    return true;
  }
}

final class PreparationRefreshRequest {
  const PreparationRefreshRequest({
    required this.revision,
    required this.trigger,
  });

  final int revision;
  final PreparationTrigger trigger;
}

final class CurrentPreparationRefreshNotifier
    extends Notifier<PreparationRefreshRequest> {
  @override
  PreparationRefreshRequest build() => const PreparationRefreshRequest(
    revision: 0,
    trigger: PreparationTrigger.coldStart,
  );

  void refresh(PreparationTrigger trigger) {
    state = PreparationRefreshRequest(
      revision: state.revision + 1,
      trigger: trigger,
    );
  }
}

final baselineMonitoringRequesterProvider =
    Provider<BaselineMonitoringRequester>((ref) {
      final config = ref.watch(baselineMonitoringConfigProvider);
      if (config == null) return const NoopBaselineMonitoringRequester();
      final database = ref.watch(appDatabaseProvider);
      return BaselineMonitoringCoordinator(
        transactionRunner: DriftTransactionRunner(database),
        clock: ref.watch(clockProvider),
        observations: ref.watch(observationsRepositoryProvider),
        mornings: ref.watch(morningsRepositoryProvider),
        summaries: ref.watch(summariesRepositoryProvider),
        learningRuns: ref.watch(learningRunsRepositoryProvider),
        versions: ref.watch(personalizationVersionsRepositoryProvider),
        settings: ref.watch(settingsRepositoryProvider),
        modelActivationService: ref.watch(modelActivationServiceProvider),
        config: config,
      );
    });

final currentPreparationProvider = FutureProvider<OperationPreparationResult>((
  ref,
) async {
  final request = ref.watch(currentPreparationRefreshProvider);
  final preparer = ref.watch(operationPreparerProvider);
  final learning = ref.watch(automaticLearningRequesterProvider);
  final monitoring = ref.watch(baselineMonitoringRequesterProvider);
  final learningGate = ref.watch(preparationLearningRequestGateProvider);
  final result = await preparer.prepare(request.trigger);
  if (request.trigger != PreparationTrigger.beforeWrite &&
      learningGate.claim(request.revision)) {
    try {
      await learning.request(_automaticLearningTrigger(request.trigger));
      await monitoring.request(_monitoringTrigger(request.trigger));
    } on Object {
      // Shadow learning must never make the core preparation flow unavailable.
    }
  }
  return result;
});

AutomaticLearningTrigger _automaticLearningTrigger(
  PreparationTrigger trigger,
) => switch (trigger) {
  PreparationTrigger.coldStart => AutomaticLearningTrigger.coldStart,
  PreparationTrigger.resumed => AutomaticLearningTrigger.resumed,
  PreparationTrigger.lifeDayBoundary => AutomaticLearningTrigger.settlement,
  PreparationTrigger.safeRestore => AutomaticLearningTrigger.safeRestore,
  PreparationTrigger.beforeWrite => AutomaticLearningTrigger.retry,
};

BaselineMonitoringTrigger _monitoringTrigger(PreparationTrigger trigger) =>
    switch (trigger) {
      PreparationTrigger.coldStart => BaselineMonitoringTrigger.coldStart,
      PreparationTrigger.resumed => BaselineMonitoringTrigger.resumed,
      PreparationTrigger.lifeDayBoundary =>
        BaselineMonitoringTrigger.settlement,
      PreparationTrigger.safeRestore => BaselineMonitoringTrigger.resumed,
      PreparationTrigger.beforeWrite => BaselineMonitoringTrigger.retry,
    };

final activityUseCasesProvider = Provider<ActivityMutator>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return ActivityUseCases(
    lifeDayCalculator: LifeDayCalculator(),
    writeCoordinator: ref.watch(businessWriteCoordinatorProvider),
    transactionRunner: DriftTransactionRunner(database),
    preparer: ref.watch(operationPreparerProvider),
    activities: ref.watch(activitiesRepositoryProvider),
    rules: ref.watch(rulesRepositoryProvider),
    summaries: ref.watch(summariesRepositoryProvider),
    projectionService: ref.watch(projectionServiceProvider),
    feedbackMaintenance: ref.watch(activityFeedbackMaintenanceProvider),
  );
});

final activityFeedbackUseCasesProvider = Provider<ActivityFeedbackMutator>((
  ref,
) {
  return ActivityFeedbackUseCases(
    writeCoordinator: ref.watch(businessWriteCoordinatorProvider),
    transactionRunner: DriftTransactionRunner(ref.watch(appDatabaseProvider)),
    preparer: ref.watch(operationPreparerProvider),
    activities: ref.watch(activitiesRepositoryProvider),
    feedback: ref.watch(activityFeedbackRepositoryProvider),
    rules: ref.watch(rulesRepositoryProvider),
    summaries: ref.watch(summariesRepositoryProvider),
  );
});

final activityImpactPreviewServiceProvider = Provider<ActivityImpactPreviewer>((
  ref,
) {
  return ActivityImpactPreviewService(
    activities: ref.watch(activitiesRepositoryProvider),
    ruleLoader: EnergyRuleConfigLoader(ref.watch(rulesRepositoryProvider)),
  );
});

final currentActivityImpactCatalogProvider =
    FutureProvider<ActivityImpactCatalog>((ref) async {
      final prepared = await ref.watch(currentPreparationProvider.future);
      return ref
          .watch(activityImpactPreviewServiceProvider)
          .previewCatalog(
            current: prepared.current,
            completedAt: ref.watch(clockProvider).now(),
          );
    });

final wellbeingUseCasesProvider = Provider<WellbeingMutator>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return WellbeingUseCases(
    writeCoordinator: ref.watch(businessWriteCoordinatorProvider),
    transactionRunner: DriftTransactionRunner(database),
    preparer: ref.watch(operationPreparerProvider),
    mornings: ref.watch(morningsRepositoryProvider),
    activities: ref.watch(activitiesRepositoryProvider),
    observations: ref.watch(observationsRepositoryProvider),
    summaries: ref.watch(summariesRepositoryProvider),
    personalizationVersions: ref.watch(
      personalizationVersionsRepositoryProvider,
    ),
    receipts: ref.watch(receiptsRepositoryProvider),
    projectionService: ref.watch(projectionServiceProvider),
    feedbackMaintenance: ref.watch(activityFeedbackMaintenanceProvider),
  );
});

final morningCompletionStatusProvider = FutureProvider<MorningCompletionStatus>(
  (ref) async {
    final prepared = await ref.watch(currentPreparationProvider.future);
    if (prepared.current.morningCheckInCompleted) {
      return MorningCompletionStatus.completed;
    }
    final skipped = await ref
        .watch(receiptsRepositoryProvider)
        .exists(
          type: PromptReceiptType.morning,
          scopeKey: prepared.current.lifeDay.toString(),
          action: PromptReceiptAction.skipped,
        );
    return skipped
        ? MorningCompletionStatus.skipped
        : MorningCompletionStatus.notAnswered;
  },
);

final currentMorningCheckInProvider = FutureProvider<MorningCheckIn?>((
  ref,
) async {
  final prepared = await ref.watch(currentPreparationProvider.future);
  return ref
      .watch(morningsRepositoryProvider)
      .findByLifeDay(prepared.current.lifeDay);
});

final currentDailyObservationProvider = FutureProvider<EnergyObservation?>((
  ref,
) async {
  final prepared = await ref.watch(currentPreparationProvider.future);
  return (await ref
          .watch(observationsRepositoryProvider)
          .listForLifeDay(prepared.current.lifeDay))
      .where((item) => item.type == EnergyObservationType.dailyAbsolute)
      .firstOrNull;
});

final currentActivityFeedbackProvider =
    FutureProvider<Map<String, ActivityFeedback>>((ref) async {
      final prepared = await ref.watch(currentPreparationProvider.future);
      final items = await ref.watch(activityFeedbackRepositoryProvider).list();
      return {
        for (final item in items)
          if (item.lifeDay == prepared.current.lifeDay &&
              item.status == ActivityFeedbackStatus.active)
            item.activityRecordId: item,
      };
    });

final canSupplementYesterdayProvider = FutureProvider<bool>((ref) async {
  final prepared = await ref.watch(currentPreparationProvider.future);
  final yesterday = prepared.current.lifeDay.previous;
  final summary = await ref
      .watch(summariesRepositoryProvider)
      .findByLifeDay(yesterday);
  if (summary == null) {
    return false;
  }
  final observations = await ref
      .watch(observationsRepositoryProvider)
      .listForLifeDay(yesterday);
  return !observations.any(
    (item) => item.type == EnergyObservationType.dailyAbsolute,
  );
});

final energyReminderServiceProvider = Provider<EnergyReminderService>((ref) {
  return EnergyReminderService(
    clock: ref.watch(clockProvider),
    recordIdGenerator: ref.watch(recordIdGeneratorProvider),
    receipts: ref.watch(receiptsRepositoryProvider),
  );
});

final historyReviewServiceProvider = Provider<HistoryReviewService>((ref) {
  return HistoryReviewService(
    summaries: ref.watch(summariesRepositoryProvider),
    observations: ref.watch(observationsRepositoryProvider),
  );
});

final historyReviewProvider = FutureProvider<HistoryReview>((ref) async {
  final prepared = await ref.watch(currentPreparationProvider.future);
  return ref
      .watch(historyReviewServiceProvider)
      .load(currentLifeDay: prepared.current.lifeDay);
});

final appSettingsProvider = FutureProvider<AppSettings>((ref) {
  ref.watch(currentPreparationRefreshProvider);
  return ref.watch(settingsRepositoryProvider).get();
});

final activePersonalizationVersionProvider =
    FutureProvider<PersonalizationVersion>((ref) {
      ref.watch(currentPreparationRefreshProvider);
      return ref.watch(personalizationVersionsRepositoryProvider).getActive();
    });

final pendingPersonalizationVersionProvider =
    FutureProvider<PersonalizationVersion?>((ref) {
      ref.watch(currentPreparationRefreshProvider);
      return ref.watch(personalizationVersionsRepositoryProvider).findPending();
    });

final learningRunProvider = FutureProvider.autoDispose
    .family<LearningRun?, String>((ref, id) {
      ref.watch(currentPreparationRefreshProvider);
      return ref.watch(learningRunsRepositoryProvider).find(id);
    });

final settingsServiceProvider = Provider<SettingsMutator>((ref) {
  return SettingsService(
    transactionRunner: DriftTransactionRunner(ref.watch(appDatabaseProvider)),
    preparer: ref.watch(operationPreparerProvider),
    settings: ref.watch(settingsRepositoryProvider),
    modelActivationService: ref.watch(modelActivationServiceProvider),
  );
});

final jsonExportServiceProvider = Provider<JsonExportService>((ref) {
  return JsonExportService(
    settings: ref.watch(settingsRepositoryProvider),
    rules: ref.watch(rulesRepositoryProvider),
    mornings: ref.watch(morningsRepositoryProvider),
    activities: ref.watch(activitiesRepositoryProvider),
    observations: ref.watch(observationsRepositoryProvider),
    feedback: ref.watch(activityFeedbackRepositoryProvider),
    learningRuns: ref.watch(learningRunsRepositoryProvider),
    personalizationVersions: ref.watch(
      personalizationVersionsRepositoryProvider,
    ),
    learningConsents: ref.watch(learningConsentsRepositoryProvider),
    learningNotices: ref.watch(learningNoticesRepositoryProvider),
    summaries: ref.watch(summariesRepositoryProvider),
    receipts: ref.watch(receiptsRepositoryProvider),
    transactionRunner: DriftTransactionRunner(ref.watch(appDatabaseProvider)),
    appVersionLoader: () async {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    },
  );
});

final learningIntegrityVerifierProvider = Provider<LearningIntegrityVerifier>((
  ref,
) {
  return BackupRoundTripLearningIntegrityVerifier(
    exportService: ref.watch(jsonExportServiceProvider),
    codec: const JsonBackupCodec(),
    clock: ref.watch(clockProvider),
  );
});

final automaticLearningRequesterProvider = Provider<AutomaticLearningRequester>(
  (ref) {
    final database = ref.watch(appDatabaseProvider);
    return AutomaticLearningCoordinator(
      writeCoordinator: ref.watch(businessWriteCoordinatorProvider),
      transactionRunner: DriftTransactionRunner(database),
      clock: ref.watch(clockProvider),
      integrityVerifier: ref.watch(learningIntegrityVerifierProvider),
      observations: ref.watch(observationsRepositoryProvider),
      mornings: ref.watch(morningsRepositoryProvider),
      summaries: ref.watch(summariesRepositoryProvider),
      learningRuns: ref.watch(learningRunsRepositoryProvider),
      productionGate: ref.watch(learningProductionGateProvider),
      productionConfig: ref.watch(baselineProductionConfigProvider),
      modelActivationService: ref.watch(modelActivationServiceProvider),
      personalizationVersions: ref.watch(
        personalizationVersionsRepositoryProvider,
      ),
      appSettings: ref.watch(settingsRepositoryProvider),
    );
  },
);

final temporaryExportFileStoreProvider = Provider<TemporaryExportFileStore>((
  ref,
) {
  return TemporaryExportFileStore(directoryLoader: getTemporaryDirectory);
});

final backupSafetyStoreProvider = Provider<BackupSafetyStore>((ref) {
  return LocalBackupSafetyStore();
});

final localBackupStoreProvider = Provider<LocalBackupStore>((ref) {
  return FileLocalBackupStore();
});

final localBackupServiceProvider = Provider<LocalBackupSaver>((ref) {
  return LocalBackupService(
    exportService: ref.watch(jsonExportServiceProvider),
    codec: const JsonBackupCodec(),
    store: ref.watch(localBackupStoreProvider),
    clock: ref.watch(clockProvider),
  );
});

final localBackupMetadataProvider = FutureProvider<LocalBackupMetadata?>((ref) {
  return ref.watch(localBackupStoreProvider).metadata();
});

final mvpBUpgradeReadinessStoreProvider = Provider<MvpBUpgradeReadinessStore>((
  ref,
) {
  return FileMvpBUpgradeReadinessStore();
});

final mvpBUpgradeReadinessServiceProvider =
    Provider<MvpBUpgradeReadinessPreparer>((ref) {
      return MvpBUpgradeReadinessService(
        preparer: ref.watch(operationPreparerProvider),
        localBackupSaver: ref.watch(localBackupServiceProvider),
        localBackupStore: ref.watch(localBackupStoreProvider),
        readinessStore: ref.watch(mvpBUpgradeReadinessStoreProvider),
        exportService: ref.watch(jsonExportServiceProvider),
        codec: const JsonBackupCodec(),
        digester: const BackupContentDigester(),
        clock: ref.watch(clockProvider),
      );
    });

final mvpBUpgradeReadinessProvider =
    FutureProvider.autoDispose<MvpBUpgradeReadinessReport>((ref) {
      ref.watch(currentPreparationRefreshProvider);
      return ref.watch(mvpBUpgradeReadinessServiceProvider).check();
    });

final dataHealthServiceProvider = Provider<DataHealthService>((ref) {
  return DataHealthService(
    exportService: ref.watch(jsonExportServiceProvider),
    codec: const JsonBackupCodec(),
    clock: ref.watch(clockProvider),
    settings: ref.watch(settingsRepositoryProvider),
    mornings: ref.watch(morningsRepositoryProvider),
    activities: ref.watch(activitiesRepositoryProvider),
    observations: ref.watch(observationsRepositoryProvider),
    feedback: ref.watch(activityFeedbackRepositoryProvider),
    learningRuns: ref.watch(learningRunsRepositoryProvider),
    personalizationVersions: ref.watch(
      personalizationVersionsRepositoryProvider,
    ),
    summaries: ref.watch(summariesRepositoryProvider),
    localBackupStore: ref.watch(localBackupStoreProvider),
    upgradeReadiness: ref.watch(mvpBUpgradeReadinessServiceProvider),
  );
});

final dataHealthReportProvider = FutureProvider.autoDispose<DataHealthReport>((
  ref,
) {
  ref.watch(currentPreparationRefreshProvider);
  return ref.watch(dataHealthServiceProvider).check();
});

final jsonBackupRestoreServiceProvider = Provider<JsonBackupRestoreService>((
  ref,
) {
  return JsonBackupRestoreService(
    codec: const JsonBackupCodec(),
    exportService: ref.watch(jsonExportServiceProvider),
    database: ref.watch(appDatabaseProvider),
    safetyStore: ref.watch(backupSafetyStoreProvider),
    clock: ref.watch(clockProvider),
    rules: ref.watch(rulesRepositoryProvider),
    mornings: ref.watch(morningsRepositoryProvider),
    activities: ref.watch(activitiesRepositoryProvider),
    observations: ref.watch(observationsRepositoryProvider),
    feedback: ref.watch(activityFeedbackRepositoryProvider),
    learningRuns: ref.watch(learningRunsRepositoryProvider),
    personalizationVersions: ref.watch(
      personalizationVersionsRepositoryProvider,
    ),
    learningConsents: ref.watch(learningConsentsRepositoryProvider),
    learningNotices: ref.watch(learningNoticesRepositoryProvider),
    summaries: ref.watch(summariesRepositoryProvider),
    receipts: ref.watch(receiptsRepositoryProvider),
    postRestorePreparation: () async {
      await ref
          .read(operationPreparerProvider)
          .prepare(PreparationTrigger.safeRestore);
    },
  );
});

final backupSafetyPathProvider = FutureProvider<String?>((ref) {
  return ref.watch(backupSafetyStoreProvider).existingPath();
});

final energyReminderMessageProvider =
    NotifierProvider<EnergyReminderNotifier, String?>(
      EnergyReminderNotifier.new,
    );

final undoWindowActiveProvider = NotifierProvider<UndoWindowNotifier, bool>(
  UndoWindowNotifier.new,
);

final class EnergyReminderNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) => state = message;
  void dismiss() => state = null;
}

final class UndoWindowNotifier extends Notifier<bool> {
  var _activeCount = 0;

  @override
  bool build() {
    _activeCount = 0;
    return false;
  }

  void begin() {
    _activeCount++;
    state = true;
  }

  void end() {
    if (_activeCount > 0) {
      _activeCount--;
    }
    state = _activeCount > 0;
  }
}
