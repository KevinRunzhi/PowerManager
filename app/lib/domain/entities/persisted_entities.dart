import 'dart:collection';

import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/estimated_activity.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

final class AppSettings {
  const AppSettings({
    required this.baseEstimatedEnergy,
    required this.pendingBaseEstimatedEnergy,
    required this.baseEnergyEffectiveLifeDay,
    required this.activeRuleVersion,
    required this.pendingRuleVersion,
    required this.pendingRuleEffectiveLifeDay,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final int baseEstimatedEnergy;
  final int? pendingBaseEstimatedEnergy;
  final LifeDay? baseEnergyEffectiveLifeDay;
  final String activeRuleVersion;
  final String? pendingRuleVersion;
  final LifeDay? pendingRuleEffectiveLifeDay;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
}

final class RuleConfigVersion {
  RuleConfigVersion({
    required this.version,
    required Map<String, Object?> values,
    required this.createdAt,
  }) : values = UnmodifiableMapView(Map.of(values));

  final String version;
  final Map<String, Object?> values;
  final DateTime createdAt;
}

final class MorningCheckIn {
  const MorningCheckIn({
    required this.id,
    required this.lifeDay,
    required this.overallState,
    required this.freeTimeLevel,
    required this.pressureSource,
    required this.sleepRecovery,
    required this.morningAdjustment,
    required this.completedAt,
  });

  final String id;
  final LifeDay lifeDay;
  final MorningOverallState overallState;
  final FreeTimeLevel freeTimeLevel;
  final PressureSource pressureSource;
  final SleepRecovery sleepRecovery;
  final int morningAdjustment;
  final DateTime completedAt;
}

final class StoredEstimatedActivity {
  const StoredEstimatedActivity({
    required this.id,
    required this.lifeDay,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    required this.subcategory,
    required this.duration,
    required this.theoreticalDelta,
    required this.appliedDelta,
    required this.ruleVersion,
    required this.status,
    required this.deletedAt,
  });

  final String id;
  final LifeDay lifeDay;
  final DateTime completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ActivityCategory category;
  final ActivitySubcategory subcategory;
  final DurationSlot duration;
  final int theoreticalDelta;
  final int appliedDelta;
  final String ruleVersion;
  final ActivityRecordStatus status;
  final DateTime? deletedAt;

  EstimatedActivityRecord toReplayRecord() {
    return EstimatedActivityRecord(
      id: id,
      completedAt: completedAt,
      createdAt: createdAt,
      subcategory: subcategory,
      duration: duration,
      ruleVersion: ruleVersion,
      theoreticalDelta: theoreticalDelta,
      status: status,
    );
  }
}

final class EnergyObservation {
  const EnergyObservation({
    required this.id,
    required this.lifeDay,
    required this.type,
    required this.absoluteState,
    required this.relativeState,
    required this.estimateAtObservation,
    required this.observedAt,
  });

  final String id;
  final LifeDay lifeDay;
  final EnergyObservationType type;
  final AbsoluteEnergyState? absoluteState;
  final RelativeCorrection? relativeState;
  final int? estimateAtObservation;
  final DateTime observedAt;
}

final class DailySummary {
  DailySummary({
    required this.lifeDay,
    required this.baseEstimatedEnergy,
    required this.ruleVersion,
    required this.morningAdjustment,
    required this.shortTermAdjustment,
    required this.initialEstimatedEnergy,
    required this.finalEstimatedEnergy,
    required this.totalConsumption,
    required this.totalRecovery,
    required Map<ActivityCategory, CategoryEstimatedSummary> categorySummaries,
    required this.isStandardEffectiveDay,
    required this.isWeakEffectiveDay,
    required this.settledAt,
  }) : categorySummaries = UnmodifiableMapView(Map.of(categorySummaries));

  final LifeDay lifeDay;
  final int baseEstimatedEnergy;
  final String ruleVersion;
  final int morningAdjustment;
  final int shortTermAdjustment;
  final int initialEstimatedEnergy;
  final int finalEstimatedEnergy;
  final int totalConsumption;
  final int totalRecovery;
  final Map<ActivityCategory, CategoryEstimatedSummary> categorySummaries;
  final bool isStandardEffectiveDay;
  final bool isWeakEffectiveDay;
  final DateTime settledAt;
}

final class PromptReceipt {
  const PromptReceipt({
    required this.id,
    required this.type,
    required this.scopeKey,
    required this.action,
    required this.occurredAt,
  });

  final String id;
  final PromptReceiptType type;
  final String scopeKey;
  final PromptReceiptAction action;
  final DateTime occurredAt;
}
