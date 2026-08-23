import 'dart:collection';

import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/estimated_activity.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

final class AppSettings {
  const AppSettings({
    required this.activeRuleVersion,
    required this.pendingRuleVersion,
    required this.pendingRuleEffectiveLifeDay,
    required this.onboardingCompleted,
    this.baselineLearningMode = LearningMode.off,
    this.activityImpactLearningMode = LearningMode.off,
    this.baselineLearningSuspended = false,
    this.baselineLearningSuspendedAt,
    this.baselineLearningSuspensionReason,
    this.activityImpactLearningSuspended = false,
    this.activityImpactLearningSuspendedAt,
    this.activityImpactLearningSuspensionReason,
    this.baselineLearningCooldownUntil,
    this.activityImpactLearningCooldownUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  final String activeRuleVersion;
  final String? pendingRuleVersion;
  final LifeDay? pendingRuleEffectiveLifeDay;
  final bool onboardingCompleted;
  final LearningMode baselineLearningMode;
  final LearningMode activityImpactLearningMode;
  final bool baselineLearningSuspended;
  final DateTime? baselineLearningSuspendedAt;
  final String? baselineLearningSuspensionReason;
  final bool activityImpactLearningSuspended;
  final DateTime? activityImpactLearningSuspendedAt;
  final String? activityImpactLearningSuspensionReason;
  final DateTime? baselineLearningCooldownUntil;
  final DateTime? activityImpactLearningCooldownUntil;
  final DateTime createdAt;
  final DateTime updatedAt;
}

final class PersonalizationVersion {
  const PersonalizationVersion({
    required this.id,
    required this.parentVersionId,
    required this.effectiveModelFingerprint,
    required this.modelRegimeEpoch,
    required this.creationSource,
    required this.scheduleSource,
    required this.sourceLearningRunId,
    required this.algorithmVersion,
    required this.configVersion,
    required this.changedParameterFamily,
    required this.baseEnergy,
    required this.baselineAnchorEnergy,
    required this.status,
    required this.effectiveLifeDay,
    required this.createdAt,
    required this.activatedAt,
    required this.endedAt,
    required this.transitionReason,
  });

  final String id;
  final String? parentVersionId;
  final String effectiveModelFingerprint;
  final String modelRegimeEpoch;
  final PersonalizationCreationSource creationSource;
  final PersonalizationScheduleSource? scheduleSource;
  final String? sourceLearningRunId;
  final String algorithmVersion;
  final String configVersion;
  final PersonalizationChangedParameterFamily changedParameterFamily;
  final int baseEnergy;
  final int baselineAnchorEnergy;
  final PersonalizationVersionStatus status;
  final LifeDay? effectiveLifeDay;
  final DateTime createdAt;
  final DateTime? activatedAt;
  final DateTime? endedAt;
  final String transitionReason;
}

final class LearningConsent {
  const LearningConsent({
    required this.parameterFamily,
    required this.disclosureVersion,
    required this.acceptedAt,
  });

  final LearningParameterFamily parameterFamily;
  final String disclosureVersion;
  final DateTime acceptedAt;
}

final class LearningNotice {
  const LearningNotice({
    required this.id,
    required this.parameterFamily,
    required this.type,
    required this.personalizationVersionId,
    required this.learningRunId,
    required this.dedupKey,
    required this.status,
    required this.reasonCode,
    required this.createdAt,
    required this.seenAt,
    required this.dismissedAt,
  });

  final String id;
  final LearningParameterFamily parameterFamily;
  final LearningNoticeType type;
  final String? personalizationVersionId;
  final String? learningRunId;
  final String dedupKey;
  final LearningNoticeStatus status;
  final String reasonCode;
  final DateTime createdAt;
  final DateTime? seenAt;
  final DateTime? dismissedAt;
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
    this.personalizationVersionId,
    this.factorRegimeStartedLifeDay,
    int? defaultTheoreticalDelta,
    this.factor = 1,
    int? personalizedTheoreticalDelta,
  }) : defaultTheoreticalDelta = defaultTheoreticalDelta ?? theoreticalDelta,
       personalizedTheoreticalDelta =
           personalizedTheoreticalDelta ?? theoreticalDelta;

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
  final String? personalizationVersionId;
  final LifeDay? factorRegimeStartedLifeDay;
  final int defaultTheoreticalDelta;
  final double factor;
  final int personalizedTheoreticalDelta;

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
    this.contractVersion,
    this.referenceType,
    this.initialEstimateAtObservation,
    this.estimatedOrdinalAtObservation,
    this.baseEnergyAtObservation,
    this.ruleVersionAtObservation,
    this.comparisonBandVersion,
    this.personalizationVersionAtObservation,
    this.effectiveModelFingerprintAtObservation,
    this.modelRegimeEpochAtObservation,
    this.activeActivityCountAtObservation,
    this.coverageState,
    this.modelRegimeKey,
  });

  final String id;
  final LifeDay lifeDay;
  final EnergyObservationType type;
  final AbsoluteEnergyState? absoluteState;
  final RelativeCorrection? relativeState;
  final int? estimateAtObservation;
  final DateTime observedAt;
  final String? contractVersion;
  final ObservationReferenceType? referenceType;
  final int? initialEstimateAtObservation;
  final int? estimatedOrdinalAtObservation;
  final int? baseEnergyAtObservation;
  final String? ruleVersionAtObservation;
  final String? comparisonBandVersion;
  final String? personalizationVersionAtObservation;
  final String? effectiveModelFingerprintAtObservation;
  final String? modelRegimeEpochAtObservation;
  final int? activeActivityCountAtObservation;
  final ObservationCoverageState? coverageState;
  final String? modelRegimeKey;
}

final class ActivityFeedback {
  const ActivityFeedback({
    required this.id,
    required this.activityRecordId,
    required this.lifeDay,
    required this.subcategorySnapshot,
    required this.durationSnapshot,
    required this.theoreticalDeltaSnapshot,
    required this.appliedDeltaSnapshot,
    required this.impactSignSnapshot,
    required this.ruleVersionSnapshot,
    required this.activityUpdatedAtSnapshot,
    required this.direction,
    required this.status,
    required this.invalidationReason,
    required this.observedAt,
    int? defaultTheoreticalDeltaSnapshot,
    this.factorSnapshot = 1,
    int? personalizedTheoreticalDeltaSnapshot,
    this.personalizationVersionId,
    this.factorRegimeStartedLifeDay,
    this.collectionSource = ActivityFeedbackCollectionSource.userInitiated,
    this.samplingPolicyVersion,
    this.sampledAt,
    this.sampleId,
  }) : defaultTheoreticalDeltaSnapshot =
           defaultTheoreticalDeltaSnapshot ?? theoreticalDeltaSnapshot,
       personalizedTheoreticalDeltaSnapshot =
           personalizedTheoreticalDeltaSnapshot ?? theoreticalDeltaSnapshot;

  final String id;
  final String activityRecordId;
  final LifeDay lifeDay;
  final ActivitySubcategory subcategorySnapshot;
  final DurationSlot durationSnapshot;
  final int theoreticalDeltaSnapshot;
  final int appliedDeltaSnapshot;
  final ActivityImpactSign impactSignSnapshot;
  final String ruleVersionSnapshot;
  final DateTime activityUpdatedAtSnapshot;
  final ActivityFeedbackDirection direction;
  final ActivityFeedbackStatus status;
  final ActivityFeedbackInvalidationReason? invalidationReason;
  final DateTime observedAt;
  final int defaultTheoreticalDeltaSnapshot;
  final double factorSnapshot;
  final int personalizedTheoreticalDeltaSnapshot;
  final String? personalizationVersionId;
  final LifeDay? factorRegimeStartedLifeDay;
  final ActivityFeedbackCollectionSource collectionSource;
  final String? samplingPolicyVersion;
  final DateTime? sampledAt;
  final String? sampleId;
}

final class PersonalizationActivityFactor {
  const PersonalizationActivityFactor({
    required this.personalizationVersionId,
    required this.subcategory,
    required this.impactSign,
    required this.factor,
    required this.baseActivityRuleVersion,
    required this.sourceLearningRunId,
    required this.factorRegimeStartedLifeDay,
  });

  final String personalizationVersionId;
  final ActivitySubcategory subcategory;
  final ActivityImpactSign impactSign;
  final double factor;
  final String baseActivityRuleVersion;
  final String? sourceLearningRunId;
  final LifeDay factorRegimeStartedLifeDay;
}

final class ActivityFeedbackSample {
  const ActivityFeedbackSample({
    required this.id,
    required this.activityRecordId,
    required this.lifeDay,
    required this.samplingPolicyVersion,
    required this.status,
    required this.selectedAt,
    required this.promptedAt,
    required this.respondedAt,
    required this.feedbackId,
    required this.invalidatedAt,
    required this.invalidationReason,
  });

  final String id;
  final String activityRecordId;
  final LifeDay lifeDay;
  final String samplingPolicyVersion;
  final ActivityFeedbackSampleStatus status;
  final DateTime selectedAt;
  final DateTime? promptedAt;
  final DateTime? respondedAt;
  final String? feedbackId;
  final DateTime? invalidatedAt;
  final ActivityFeedbackInvalidationReason? invalidationReason;

  bool get isInvalidated => status == ActivityFeedbackSampleStatus.invalidated;

  bool canTransitionTo(ActivityFeedbackSampleStatus next) {
    if (isInvalidated) return false;
    return switch (status) {
      ActivityFeedbackSampleStatus.selected =>
        next == ActivityFeedbackSampleStatus.prompted ||
            next == ActivityFeedbackSampleStatus.responded ||
            next == ActivityFeedbackSampleStatus.skipped ||
            next == ActivityFeedbackSampleStatus.expired ||
            next == ActivityFeedbackSampleStatus.invalidated,
      ActivityFeedbackSampleStatus.prompted =>
        next == ActivityFeedbackSampleStatus.responded ||
            next == ActivityFeedbackSampleStatus.skipped ||
            next == ActivityFeedbackSampleStatus.expired ||
            next == ActivityFeedbackSampleStatus.invalidated,
      ActivityFeedbackSampleStatus.responded ||
      ActivityFeedbackSampleStatus.skipped ||
      ActivityFeedbackSampleStatus.expired =>
        next == ActivityFeedbackSampleStatus.invalidated,
      ActivityFeedbackSampleStatus.invalidated => false,
    };
  }
}

final class LearningRun {
  const LearningRun({
    required this.id,
    required this.parameterFamily,
    required this.sourceModelIdentity,
    required this.sourcePersonalizationVersionId,
    required this.status,
    required this.result,
    required this.evidenceSnapshotJson,
    required this.evidenceHash,
    required this.evidenceHashVersion,
    required this.algorithmVersion,
    required this.configVersion,
    required this.currentValuesJson,
    required this.candidateValuesJson,
    required this.reasonCodesJson,
    required this.triggeredAt,
    required this.completedAt,
  });

  final String id;
  final LearningParameterFamily parameterFamily;
  final String sourceModelIdentity;
  final String? sourcePersonalizationVersionId;
  final LearningRunStatus status;
  final LearningRunResult? result;
  final String evidenceSnapshotJson;
  final String evidenceHash;
  final String evidenceHashVersion;
  final String algorithmVersion;
  final String configVersion;
  final String currentValuesJson;
  final String? candidateValuesJson;
  final String reasonCodesJson;
  final DateTime triggeredAt;
  final DateTime? completedAt;
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
    this.modelSnapshotSource = DailySummaryModelSnapshotSource.legacyInline,
    this.personalizationVersionId,
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
  final DailySummaryModelSnapshotSource modelSnapshotSource;
  final String? personalizationVersionId;
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
