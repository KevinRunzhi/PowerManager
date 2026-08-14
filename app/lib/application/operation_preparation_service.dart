import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/settlement_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/life_day/life_day_calculator.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

enum PreparationTrigger { coldStart, resumed, lifeDayBoundary, beforeWrite }

abstract interface class TransactionRunner {
  Future<T> run<T>(Future<T> Function() action);
}

abstract interface class OperationPreparer {
  Future<OperationPreparationResult> prepare(PreparationTrigger trigger);
}

final class OperationPreparationResult {
  const OperationPreparationResult({
    required this.trigger,
    required this.nowLocal,
    required this.nowUtc,
    required this.current,
    required this.settledSummaries,
    required this.appliedPendingBaseEnergy,
    required this.appliedPendingRuleVersion,
  });

  final PreparationTrigger trigger;
  final DateTime nowLocal;
  final DateTime nowUtc;
  final CurrentDayProjection current;
  final List<DailySummary> settledSummaries;
  final bool appliedPendingBaseEnergy;
  final bool appliedPendingRuleVersion;
}

final class OperationPreparationService implements OperationPreparer {
  const OperationPreparationService({
    required this.clock,
    required this.lifeDayCalculator,
    required this.transactionRunner,
    required this.settings,
    required this.settlementService,
    required this.projectionService,
  });

  final Clock clock;
  final LifeDayCalculator lifeDayCalculator;
  final TransactionRunner transactionRunner;
  final AppSettingsRepository settings;
  final SettlementService settlementService;
  final CurrentDayProjectionService projectionService;

  @override
  Future<OperationPreparationResult> prepare(PreparationTrigger trigger) {
    final now = clock.now();
    final nowLocal = now.isUtc ? now.toLocal() : now;
    final nowUtc = now.toUtc();
    final currentLifeDay = lifeDayCalculator.lifeDayFor(nowLocal);

    return transactionRunner.run(() async {
      var currentSettings = await settings.get();
      final settled = await settlementService.settleBefore(
        currentLifeDay: currentLifeDay,
        baseEstimatedEnergy: currentSettings.baseEstimatedEnergy,
        ruleVersion: currentSettings.activeRuleVersion,
        settledAt: nowUtc,
      );

      final applyBase = _isDue(
        currentSettings.pendingBaseEstimatedEnergy,
        currentSettings.baseEnergyEffectiveLifeDay,
        currentLifeDay,
      );
      final applyRule = _isDue(
        currentSettings.pendingRuleVersion,
        currentSettings.pendingRuleEffectiveLifeDay,
        currentLifeDay,
      );
      if (applyBase || applyRule) {
        currentSettings = AppSettings(
          baseEstimatedEnergy: applyBase
              ? currentSettings.pendingBaseEstimatedEnergy!
              : currentSettings.baseEstimatedEnergy,
          pendingBaseEstimatedEnergy: applyBase
              ? null
              : currentSettings.pendingBaseEstimatedEnergy,
          baseEnergyEffectiveLifeDay: applyBase
              ? null
              : currentSettings.baseEnergyEffectiveLifeDay,
          activeRuleVersion: applyRule
              ? currentSettings.pendingRuleVersion!
              : currentSettings.activeRuleVersion,
          pendingRuleVersion: applyRule
              ? null
              : currentSettings.pendingRuleVersion,
          pendingRuleEffectiveLifeDay: applyRule
              ? null
              : currentSettings.pendingRuleEffectiveLifeDay,
          onboardingCompleted: currentSettings.onboardingCompleted,
          createdAt: currentSettings.createdAt,
          updatedAt: nowUtc,
        );
        await settings.save(currentSettings);
      }

      final current = await projectionService.project(
        lifeDay: currentLifeDay,
        baseEstimatedEnergy: currentSettings.baseEstimatedEnergy,
        ruleVersion: currentSettings.activeRuleVersion,
      );
      return OperationPreparationResult(
        trigger: trigger,
        nowLocal: nowLocal,
        nowUtc: nowUtc,
        current: current,
        settledSummaries: List.unmodifiable(settled),
        appliedPendingBaseEnergy: applyBase,
        appliedPendingRuleVersion: applyRule,
      );
    });
  }
}

bool _isDue<T>(T? pending, LifeDay? effectiveDay, LifeDay currentLifeDay) {
  if ((pending == null) != (effectiveDay == null)) {
    throw StateError('Pending value and effective life day must be paired');
  }
  return pending != null && effectiveDay!.compareTo(currentLifeDay) <= 0;
}
