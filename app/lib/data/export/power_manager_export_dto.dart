import 'package:power_manager/domain/entities/persisted_entities.dart';

final class LegacyBaseSettingsBridge {
  const LegacyBaseSettingsBridge({
    required this.baseEstimatedEnergy,
    required this.pendingBaseEstimatedEnergy,
    required this.baseEnergyEffectiveLifeDay,
  });

  final int baseEstimatedEnergy;
  final int? pendingBaseEstimatedEnergy;
  final String? baseEnergyEffectiveLifeDay;
}

/// Canonical schema-v1/v2/v3/v4 transport shared by JSON export and restore.
final class PowerManagerExportDto {
  PowerManagerExportDto({
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.appSettings,
    this.legacyBaseSettings,
    required List<RuleConfigVersion> ruleVersions,
    required List<MorningCheckIn> morningCheckIns,
    required List<StoredEstimatedActivity> activityRecords,
    required List<EnergyObservation> energyObservations,
    List<ActivityFeedback> activityFeedback = const [],
    List<LearningRun> learningRuns = const [],
    List<PersonalizationVersion> personalizationVersions = const [],
    List<LearningConsent> learningConsents = const [],
    List<LearningNotice> learningNotices = const [],
    required List<DailySummary> dailySummaries,
    required List<PromptReceipt> promptReceipts,
  }) : ruleVersions = List.unmodifiable(ruleVersions),
       morningCheckIns = List.unmodifiable(morningCheckIns),
       activityRecords = List.unmodifiable(activityRecords),
       energyObservations = List.unmodifiable(energyObservations),
       activityFeedback = List.unmodifiable(activityFeedback),
       learningRuns = List.unmodifiable(learningRuns),
       personalizationVersions = List.unmodifiable(personalizationVersions),
       learningConsents = List.unmodifiable(learningConsents),
       learningNotices = List.unmodifiable(learningNotices),
       dailySummaries = List.unmodifiable(dailySummaries),
       promptReceipts = List.unmodifiable(promptReceipts);

  final int schemaVersion;
  final DateTime exportedAt;
  final String appVersion;
  final AppSettings appSettings;
  final LegacyBaseSettingsBridge? legacyBaseSettings;
  final List<RuleConfigVersion> ruleVersions;
  final List<MorningCheckIn> morningCheckIns;

  /// Must include active and logically deleted rows.
  final List<StoredEstimatedActivity> activityRecords;
  final List<EnergyObservation> energyObservations;
  final List<ActivityFeedback> activityFeedback;
  final List<LearningRun> learningRuns;
  final List<PersonalizationVersion> personalizationVersions;
  final List<LearningConsent> learningConsents;
  final List<LearningNotice> learningNotices;
  final List<DailySummary> dailySummaries;
  final List<PromptReceipt> promptReceipts;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'exportedAt': _utc(exportedAt),
      'appVersion': appVersion,
      'appSettings': schemaVersion >= 4
          ? _settingsJson(appSettings)
          : _legacySettingsJson(appSettings, legacyBaseSettings!),
      'ruleConfigVersions': ruleVersions.map(_ruleVersionJson).toList(),
      'morningCheckIns': morningCheckIns.map(_checkInJson).toList(),
      'activityRecords': activityRecords.map(_activityJson).toList(),
      'energyObservations': energyObservations
          .map((item) => _observationJson(item, schemaVersion: schemaVersion))
          .toList(),
      if (schemaVersion >= 2)
        'activityFeedback': activityFeedback.map(_feedbackJson).toList(),
      if (schemaVersion >= 3)
        'learningRuns': learningRuns.map(_learningRunJson).toList(),
      if (schemaVersion >= 4) ...{
        'personalizationVersions': personalizationVersions
            .map(_personalizationVersionJson)
            .toList(),
        'learningConsents': learningConsents.map(_learningConsentJson).toList(),
        'learningNotices': learningNotices.map(_learningNoticeJson).toList(),
      },
      'dailySummaries': dailySummaries
          .map((item) => _summaryJson(item, schemaVersion: schemaVersion))
          .toList(),
      'promptReceipts': promptReceipts.map(_receiptJson).toList(),
    };
  }
}

Map<String, Object?> _learningRunJson(LearningRun run) {
  return {
    'id': run.id,
    'parameterFamily': run.parameterFamily.code,
    'sourceModelIdentity': run.sourceModelIdentity,
    'sourcePersonalizationVersionId': run.sourcePersonalizationVersionId,
    'status': run.status.code,
    'result': run.result?.code,
    'evidenceSnapshotJson': run.evidenceSnapshotJson,
    'evidenceHash': run.evidenceHash,
    'evidenceHashVersion': run.evidenceHashVersion,
    'algorithmVersion': run.algorithmVersion,
    'configVersion': run.configVersion,
    'currentValuesJson': run.currentValuesJson,
    'candidateValuesJson': run.candidateValuesJson,
    'reasonCodesJson': run.reasonCodesJson,
    'triggeredAt': _utc(run.triggeredAt),
    'completedAt': run.completedAt == null ? null : _utc(run.completedAt!),
  };
}

Map<String, Object?> _settingsJson(AppSettings settings) {
  return {
    'activeRuleVersion': settings.activeRuleVersion,
    'pendingRuleVersion': settings.pendingRuleVersion,
    'pendingRuleEffectiveLifeDay': settings.pendingRuleEffectiveLifeDay
        ?.toString(),
    'onboardingCompleted': settings.onboardingCompleted,
    'baselineLearningMode': settings.baselineLearningMode.code,
    'activityImpactLearningMode': settings.activityImpactLearningMode.code,
    'baselineLearningSuspended': settings.baselineLearningSuspended,
    'baselineLearningSuspendedAt': settings.baselineLearningSuspendedAt == null
        ? null
        : _utc(settings.baselineLearningSuspendedAt!),
    'baselineLearningSuspensionReason':
        settings.baselineLearningSuspensionReason,
    'activityImpactLearningSuspended':
        settings.activityImpactLearningSuspended,
    'activityImpactLearningSuspendedAt':
        settings.activityImpactLearningSuspendedAt == null
        ? null
        : _utc(settings.activityImpactLearningSuspendedAt!),
    'activityImpactLearningSuspensionReason':
        settings.activityImpactLearningSuspensionReason,
    'baselineLearningCooldownUntil':
        settings.baselineLearningCooldownUntil == null
        ? null
        : _utc(settings.baselineLearningCooldownUntil!),
    'activityImpactLearningCooldownUntil':
        settings.activityImpactLearningCooldownUntil == null
        ? null
        : _utc(settings.activityImpactLearningCooldownUntil!),
    'createdAt': _utc(settings.createdAt),
    'updatedAt': _utc(settings.updatedAt),
  };
}

Map<String, Object?> _legacySettingsJson(
  AppSettings settings,
  LegacyBaseSettingsBridge bridge,
) {
  return {
    'baseEstimatedEnergy': bridge.baseEstimatedEnergy,
    'pendingBaseEstimatedEnergy': bridge.pendingBaseEstimatedEnergy,
    'baseEnergyEffectiveLifeDay': bridge.baseEnergyEffectiveLifeDay,
    'activeRuleVersion': settings.activeRuleVersion,
    'pendingRuleVersion': settings.pendingRuleVersion,
    'pendingRuleEffectiveLifeDay': settings.pendingRuleEffectiveLifeDay
        ?.toString(),
    'onboardingCompleted': settings.onboardingCompleted,
    'createdAt': _utc(settings.createdAt),
    'updatedAt': _utc(settings.updatedAt),
  };
}

Map<String, Object?> _personalizationVersionJson(
  PersonalizationVersion version,
) {
  return {
    'id': version.id,
    'parentVersionId': version.parentVersionId,
    'effectiveModelFingerprint': version.effectiveModelFingerprint,
    'modelRegimeEpoch': version.modelRegimeEpoch,
    'creationSource': version.creationSource.code,
    'scheduleSource': version.scheduleSource?.code,
    'sourceLearningRunId': version.sourceLearningRunId,
    'algorithmVersion': version.algorithmVersion,
    'configVersion': version.configVersion,
    'changedParameterFamily': version.changedParameterFamily.code,
    'baseEnergy': version.baseEnergy,
    'baselineAnchorEnergy': version.baselineAnchorEnergy,
    'status': version.status.code,
    'effectiveLifeDay': version.effectiveLifeDay?.toString(),
    'createdAt': _utc(version.createdAt),
    'activatedAt': version.activatedAt == null
        ? null
        : _utc(version.activatedAt!),
    'endedAt': version.endedAt == null ? null : _utc(version.endedAt!),
    'transitionReason': version.transitionReason,
  };
}

Map<String, Object?> _learningConsentJson(LearningConsent consent) {
  return {
    'parameterFamily': consent.parameterFamily.code,
    'disclosureVersion': consent.disclosureVersion,
    'acceptedAt': _utc(consent.acceptedAt),
  };
}

Map<String, Object?> _learningNoticeJson(LearningNotice notice) {
  return {
    'id': notice.id,
    'parameterFamily': notice.parameterFamily.code,
    'type': notice.type.code,
    'personalizationVersionId': notice.personalizationVersionId,
    'learningRunId': notice.learningRunId,
    'dedupKey': notice.dedupKey,
    'status': notice.status.code,
    'reasonCode': notice.reasonCode,
    'createdAt': _utc(notice.createdAt),
    'seenAt': notice.seenAt == null ? null : _utc(notice.seenAt!),
    'dismissedAt': notice.dismissedAt == null
        ? null
        : _utc(notice.dismissedAt!),
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

Map<String, Object?> _observationJson(
  EnergyObservation observation, {
  required int schemaVersion,
}) {
  return {
    'id': observation.id,
    'lifeDay': observation.lifeDay.toString(),
    'type': observation.type.code,
    'absoluteState': observation.absoluteState?.code,
    'relativeState': observation.relativeState?.code,
    'estimateAtObservation': observation.estimateAtObservation,
    if (schemaVersion >= 2) ...{
      'contractVersion': observation.contractVersion,
      'referenceType': observation.referenceType?.code,
      'initialEstimateAtObservation': observation.initialEstimateAtObservation,
      'estimatedOrdinalAtObservation':
          observation.estimatedOrdinalAtObservation,
      'baseEnergyAtObservation': observation.baseEnergyAtObservation,
      'ruleVersionAtObservation': observation.ruleVersionAtObservation,
      'comparisonBandVersion': observation.comparisonBandVersion,
      'personalizationVersionAtObservation':
          observation.personalizationVersionAtObservation,
      'effectiveModelFingerprintAtObservation':
          observation.effectiveModelFingerprintAtObservation,
      'modelRegimeEpochAtObservation':
          observation.modelRegimeEpochAtObservation,
      'activeActivityCountAtObservation':
          observation.activeActivityCountAtObservation,
      'coverageState': observation.coverageState?.code,
      'modelRegimeKey': observation.modelRegimeKey,
    },
    'observedAt': _utc(observation.observedAt),
  };
}

Map<String, Object?> _feedbackJson(ActivityFeedback feedback) {
  return {
    'id': feedback.id,
    'activityRecordId': feedback.activityRecordId,
    'lifeDay': feedback.lifeDay.toString(),
    'subcategorySnapshot': feedback.subcategorySnapshot.code,
    'durationMinutesSnapshot': feedback.durationSnapshot.minutes,
    'theoreticalDeltaSnapshot': feedback.theoreticalDeltaSnapshot,
    'appliedDeltaSnapshot': feedback.appliedDeltaSnapshot,
    'impactSignSnapshot': feedback.impactSignSnapshot.code,
    'ruleVersionSnapshot': feedback.ruleVersionSnapshot,
    'activityUpdatedAtSnapshot': _utc(feedback.activityUpdatedAtSnapshot),
    'direction': feedback.direction.code,
    'status': feedback.status.code,
    'invalidationReason': feedback.invalidationReason?.code,
    'observedAt': _utc(feedback.observedAt),
  };
}

Map<String, Object?> _summaryJson(
  DailySummary summary, {
  required int schemaVersion,
}) {
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
    if (schemaVersion >= 4) ...{
      'modelSnapshotSource': summary.modelSnapshotSource.code,
      'personalizationVersionId': summary.personalizationVersionId,
    },
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
