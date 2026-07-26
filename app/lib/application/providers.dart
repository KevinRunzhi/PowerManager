import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/application/activity_use_cases.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/settlement_service.dart';
import 'package:power_manager/application/wellbeing_use_cases.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/db/app_database_connection.dart';
import 'package:power_manager/data/db/drift_transaction_runner.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day_calculator.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

final clockProvider = Provider<Clock>((ref) => const SystemClock());

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

final currentPreparationProvider = FutureProvider<OperationPreparationResult>((
  ref,
) {
  return ref
      .watch(operationPreparerProvider)
      .prepare(PreparationTrigger.resumed);
});

final activityUseCasesProvider = Provider<ActivityMutator>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return ActivityUseCases(
    clock: ref.watch(clockProvider),
    lifeDayCalculator: LifeDayCalculator(),
    transactionRunner: DriftTransactionRunner(database),
    preparer: ref.watch(operationPreparerProvider),
    activities: ref.watch(activitiesRepositoryProvider),
    rules: ref.watch(rulesRepositoryProvider),
    summaries: ref.watch(summariesRepositoryProvider),
    projectionService: ref.watch(projectionServiceProvider),
  );
});

final wellbeingUseCasesProvider = Provider<WellbeingMutator>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return WellbeingUseCases(
    clock: ref.watch(clockProvider),
    transactionRunner: DriftTransactionRunner(database),
    preparer: ref.watch(operationPreparerProvider),
    mornings: ref.watch(morningsRepositoryProvider),
    activities: ref.watch(activitiesRepositoryProvider),
    observations: ref.watch(observationsRepositoryProvider),
    summaries: ref.watch(summariesRepositoryProvider),
    receipts: ref.watch(receiptsRepositoryProvider),
    projectionService: ref.watch(projectionServiceProvider),
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
