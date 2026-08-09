import 'package:power_manager/domain/entities/persisted_entities.dart';

/// Canonical schema-v1 transport shape shared by JSON export and restore.
final class PowerManagerExportDto {
  PowerManagerExportDto({
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.appSettings,
    required List<RuleConfigVersion> ruleVersions,
    required List<MorningCheckIn> morningCheckIns,
    required List<StoredEstimatedActivity> activityRecords,
    required List<EnergyObservation> energyObservations,
    required List<DailySummary> dailySummaries,
    required List<PromptReceipt> promptReceipts,
  }) : ruleVersions = List.unmodifiable(ruleVersions),
       morningCheckIns = List.unmodifiable(morningCheckIns),
       activityRecords = List.unmodifiable(activityRecords),
       energyObservations = List.unmodifiable(energyObservations),
       dailySummaries = List.unmodifiable(dailySummaries),
       promptReceipts = List.unmodifiable(promptReceipts);

  final int schemaVersion;
  final DateTime exportedAt;
  final String appVersion;
  final AppSettings appSettings;
  final List<RuleConfigVersion> ruleVersions;
  final List<MorningCheckIn> morningCheckIns;

  /// Must include active and logically deleted rows.
  final List<StoredEstimatedActivity> activityRecords;
  final List<EnergyObservation> energyObservations;
  final List<DailySummary> dailySummaries;
  final List<PromptReceipt> promptReceipts;

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'exportedAt': _utc(exportedAt),
      'appVersion': appVersion,
      'appSettings': _settingsJson(appSettings),
      'ruleConfigVersions': ruleVersions.map(_ruleVersionJson).toList(),
      'morningCheckIns': morningCheckIns.map(_checkInJson).toList(),
      'activityRecords': activityRecords.map(_activityJson).toList(),
      'energyObservations': energyObservations.map(_observationJson).toList(),
      'dailySummaries': dailySummaries.map(_summaryJson).toList(),
      'promptReceipts': promptReceipts.map(_receiptJson).toList(),
    };
  }
}

Map<String, Object?> _settingsJson(AppSettings settings) {
  return {
    'baseEstimatedEnergy': settings.baseEstimatedEnergy,
    'pendingBaseEstimatedEnergy': settings.pendingBaseEstimatedEnergy,
    'baseEnergyEffectiveLifeDay': settings.baseEnergyEffectiveLifeDay
        ?.toString(),
    'activeRuleVersion': settings.activeRuleVersion,
    'pendingRuleVersion': settings.pendingRuleVersion,
    'pendingRuleEffectiveLifeDay': settings.pendingRuleEffectiveLifeDay
        ?.toString(),
    'onboardingCompleted': settings.onboardingCompleted,
    'createdAt': _utc(settings.createdAt),
    'updatedAt': _utc(settings.updatedAt),
  };
}

Map<String, Object?> _ruleVersionJson(RuleConfigVersion version) {
  return {
    'version': version.version,
    'values': version.values,
    'createdAt': _utc(version.createdAt),
  };
}

Map<String, Object?> _checkInJson(MorningCheckIn checkIn) {
  return {
    'id': checkIn.id,
    'lifeDay': checkIn.lifeDay.toString(),
    'overallState': checkIn.overallState.code,
    'freeTimeLevel': checkIn.freeTimeLevel.code,
    'pressureSource': checkIn.pressureSource.code,
    'sleepRecovery': checkIn.sleepRecovery.code,
    'morningAdjustment': checkIn.morningAdjustment,
    'completedAt': _utc(checkIn.completedAt),
  };
}

Map<String, Object?> _activityJson(StoredEstimatedActivity activity) {
  return {
    'id': activity.id,
    'lifeDay': activity.lifeDay.toString(),
    'completedAt': _utc(activity.completedAt),
    'createdAt': _utc(activity.createdAt),
    'updatedAt': _utc(activity.updatedAt),
    'category': activity.category.code,
    'subcategory': activity.subcategory.code,
    'durationMinutes': activity.duration.minutes,
    'theoreticalDelta': activity.theoreticalDelta,
    'appliedDelta': activity.appliedDelta,
    'ruleVersion': activity.ruleVersion,
    'status': activity.status.code,
    'deletedAt': activity.deletedAt == null ? null : _utc(activity.deletedAt!),
  };
}

Map<String, Object?> _observationJson(EnergyObservation observation) {
  return {
    'id': observation.id,
    'lifeDay': observation.lifeDay.toString(),
    'type': observation.type.code,
    'absoluteState': observation.absoluteState?.code,
    'relativeState': observation.relativeState?.code,
    'estimateAtObservation': observation.estimateAtObservation,
    'observedAt': _utc(observation.observedAt),
  };
}

Map<String, Object?> _summaryJson(DailySummary summary) {
  return {
    'lifeDay': summary.lifeDay.toString(),
    'baseEstimatedEnergy': summary.baseEstimatedEnergy,
    'ruleVersion': summary.ruleVersion,
    'morningAdjustment': summary.morningAdjustment,
    'shortTermAdjustment': summary.shortTermAdjustment,
    'initialEstimatedEnergy': summary.initialEstimatedEnergy,
    'finalEstimatedEnergy': summary.finalEstimatedEnergy,
    'totalConsumption': summary.totalConsumption,
    'totalRecovery': summary.totalRecovery,
    'categorySummaries': {
      for (final MapEntry(key: category, value: value)
          in summary.categorySummaries.entries)
        category.code: {
          'durationMinutes': value.durationMinutes,
          'netDelta': value.netDelta,
          'grossDelta': value.grossDelta,
        },
    },
    'isStandardEffectiveDay': summary.isStandardEffectiveDay,
    'isWeakEffectiveDay': summary.isWeakEffectiveDay,
    'settledAt': _utc(summary.settledAt),
  };
}

Map<String, Object?> _receiptJson(PromptReceipt receipt) {
  return {
    'id': receipt.id,
    'type': receipt.type.code,
    'scopeKey': receipt.scopeKey,
    'action': receipt.action.code,
    'occurredAt': _utc(receipt.occurredAt),
  };
}

String _utc(DateTime value) => value.toUtc().toIso8601String();
