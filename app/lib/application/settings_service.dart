import 'dart:async';

import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/model_activation_service.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

abstract interface class SettingsMutator {
  Future<AppSettings> scheduleBaseEstimate(int value);
  Future<AppSettings> completeOnboarding();
  Future<AppSettings> setLearningMode({
    required LearningParameterFamily parameterFamily,
    required LearningMode mode,
    required bool acceptCurrentDisclosure,
  });
}

final class SettingsService implements SettingsMutator {
  SettingsService({
    required this.transactionRunner,
    required this.preparer,
    required this.settings,
    required this.modelActivationService,
  });

  final TransactionRunner transactionRunner;
  final OperationPreparer preparer;
  final AppSettingsRepository settings;
  final ModelActivationService modelActivationService;

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
        await modelActivationService.scheduleManualBaseline(
          baseEnergy: value,
          currentLifeDay: prepared.current.lifeDay,
          effectiveLifeDay: prepared.current.lifeDay.next,
          at: prepared.nowUtc,
          ruleVersion: current.activeRuleVersion,
        );
        return settings.get();
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

  @override
  Future<AppSettings> setLearningMode({
    required LearningParameterFamily parameterFamily,
    required LearningMode mode,
    required bool acceptCurrentDisclosure,
  }) {
    return _serialized(() {
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        return modelActivationService.changeLearningMode(
          parameterFamily: parameterFamily,
          mode: mode,
          acceptCurrentDisclosure: acceptCurrentDisclosure,
          at: prepared.nowUtc,
        );
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
    bool? onboardingCompleted,
    required DateTime updatedAt,
  }) {
    return AppSettings(
      activeRuleVersion: value.activeRuleVersion,
      pendingRuleVersion: value.pendingRuleVersion,
      pendingRuleEffectiveLifeDay: value.pendingRuleEffectiveLifeDay,
      onboardingCompleted: onboardingCompleted ?? value.onboardingCompleted,
      baselineLearningMode: value.baselineLearningMode,
      activityImpactLearningMode: value.activityImpactLearningMode,
      baselineLearningSuspended: value.baselineLearningSuspended,
      baselineLearningSuspendedAt: value.baselineLearningSuspendedAt,
      baselineLearningSuspensionReason: value.baselineLearningSuspensionReason,
      activityImpactLearningSuspended: value.activityImpactLearningSuspended,
      activityImpactLearningSuspendedAt:
          value.activityImpactLearningSuspendedAt,
      activityImpactLearningSuspensionReason:
          value.activityImpactLearningSuspensionReason,
      baselineLearningCooldownUntil: value.baselineLearningCooldownUntil,
      activityImpactLearningCooldownUntil:
          value.activityImpactLearningCooldownUntil,
      createdAt: value.createdAt,
      updatedAt: updatedAt,
    );
  }
}
