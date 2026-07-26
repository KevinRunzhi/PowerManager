import 'dart:async';

import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

abstract interface class SettingsMutator {
  Future<AppSettings> scheduleBaseEstimate(int value);
  Future<AppSettings> completeOnboarding();
}

final class SettingsService implements SettingsMutator {
  SettingsService({
    required this.transactionRunner,
    required this.preparer,
    required this.settings,
  });

  final TransactionRunner transactionRunner;
  final OperationPreparer preparer;
  final AppSettingsRepository settings;

  Future<void> _tail = Future.value();

  @override
  Future<AppSettings> scheduleBaseEstimate(int value) {
    if (value < 60 || value > 140) {
      throw RangeError.range(value, 60, 140, 'value');
    }
    return _serialized(() {
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        final current = await settings.get();
        final updated = _copy(
          current,
          pendingBaseEstimatedEnergy: value,
          baseEnergyEffectiveLifeDay: prepared.current.lifeDay.next,
          updatedAt: prepared.nowUtc,
        );
        await settings.save(updated);
        return updated;
      });
    });
  }

  @override
  Future<AppSettings> completeOnboarding() {
    return _serialized(() {
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        final current = await settings.get();
        if (current.onboardingCompleted) {
          return current;
        }
        final updated = _copy(
          current,
          onboardingCompleted: true,
          updatedAt: prepared.nowUtc,
        );
        await settings.save(updated);
        return updated;
      });
    });
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail
        .then((_) => action())
        .then(completer.complete, onError: completer.completeError);
    return completer.future;
  }

  static AppSettings _copy(
    AppSettings value, {
    int? pendingBaseEstimatedEnergy,
    Object? baseEnergyEffectiveLifeDay = _unchanged,
    bool? onboardingCompleted,
    required DateTime updatedAt,
  }) {
    return AppSettings(
      baseEstimatedEnergy: value.baseEstimatedEnergy,
      pendingBaseEstimatedEnergy:
          pendingBaseEstimatedEnergy ?? value.pendingBaseEstimatedEnergy,
      baseEnergyEffectiveLifeDay:
          identical(baseEnergyEffectiveLifeDay, _unchanged)
          ? value.baseEnergyEffectiveLifeDay
          : baseEnergyEffectiveLifeDay as LifeDay?,
      activeRuleVersion: value.activeRuleVersion,
      pendingRuleVersion: value.pendingRuleVersion,
      pendingRuleEffectiveLifeDay: value.pendingRuleEffectiveLifeDay,
      onboardingCompleted: onboardingCompleted ?? value.onboardingCompleted,
      createdAt: value.createdAt,
      updatedAt: updatedAt,
    );
  }
}

const _unchanged = Object();
