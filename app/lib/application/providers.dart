import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/settlement_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/db/app_database_connection.dart';
import 'package:power_manager/data/db/drift_transaction_runner.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/life_day/life_day_calculator.dart';

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = openAppDatabase(clock: ref.watch(clockProvider));
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final operationPreparerProvider = Provider<OperationPreparer>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final settings = DriftAppSettingsRepository(database.appSettingsDao);
  final mornings = DriftMorningCheckInsRepository(database.morningCheckInsDao);
  final activities = DriftActivityRecordsRepository(
    database.activityRecordsDao,
  );
  final observations = DriftEnergyObservationsRepository(
    database.energyObservationsDao,
  );
  final summaries = DriftDailySummariesRepository(database.dailySummariesDao);
  final projectionService = CurrentDayProjectionService(
    morningCheckIns: mornings,
    activities: activities,
    summaries: summaries,
  );

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
