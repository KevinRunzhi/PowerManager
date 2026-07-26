import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/application/activity_use_cases.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/settlement_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/db/app_database_connection.dart';
import 'package:power_manager/data/db/drift_transaction_runner.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
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
