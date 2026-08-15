import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

/// B3-0 is deliberately a pre-production contract.  The watermark and the
/// closed production flags are part of the validation surface, not comments.
const activityImpactSamplingAlgorithmV1 = 'activity-impact-sampler-v1';
const activityFeedbackSamplingPolicyV1 = 'activity-impact-sampling-preprod-v1';
const activityImpactPreproductionWatermark =
    'PREPRODUCTION_ONLY_ACTIVITY_IMPACT_V1';
const activityImpactSupportedRuleVersion = 'energy-rules-v2-mvp-a';

enum ActivityImpactFeedbackCollectionSource {
  userInitiated('userInitiated'),
  sampledPrompt('sampledPrompt');

  const ActivityImpactFeedbackCollectionSource(this.code);

  final String code;
}

final class ActivityImpactKey implements Comparable<ActivityImpactKey> {
  const ActivityImpactKey({
    required this.subcategory,
    required this.impactSign,
  });

  final ActivitySubcategory subcategory;
  final ActivityImpactSign impactSign;

  String get value => '${subcategory.code}|${impactSign.code}';

  bool get isFactorEligible => impactSign != ActivityImpactSign.zero;

  @override
  int compareTo(ActivityImpactKey other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityImpactKey &&
          other.subcategory == subcategory &&
          other.impactSign == impactSign;

  @override
  int get hashCode => Object.hash(subcategory, impactSign);

  @override
  String toString() => value;
}

ActivityImpactSign activityImpactContractSign(int theoreticalDelta) {
  if (theoreticalDelta < 0) return ActivityImpactSign.consumption;
  if (theoreticalDelta > 0) return ActivityImpactSign.recovery;
  return ActivityImpactSign.zero;
}

/// A source-neutral snapshot used by the feasibility audit.  v4 feedback is
/// converted with [fromActivityFeedback] and is therefore explicitly marked
/// userInitiated; it can never silently become sampledPrompt evidence.
final class ActivityImpactFeedbackObservation {
  const ActivityImpactFeedbackObservation({
    required this.lifeDay,
    required this.subcategory,
    required this.duration,
    required this.theoreticalDelta,
    required this.appliedDelta,
    required this.impactSign,
    required this.ruleVersion,
    required this.direction,
    required this.status,
    required this.collectionSource,
  });

  factory ActivityImpactFeedbackObservation.fromActivityFeedback(
    ActivityFeedback feedback,
  ) {
    return ActivityImpactFeedbackObservation(
      lifeDay: feedback.lifeDay,
      subcategory: feedback.subcategorySnapshot,
      duration: feedback.durationSnapshot,
      theoreticalDelta: feedback.theoreticalDeltaSnapshot,
      appliedDelta: feedback.appliedDeltaSnapshot,
      impactSign: feedback.impactSignSnapshot,
      ruleVersion: feedback.ruleVersionSnapshot,
      direction: feedback.direction,
      status: feedback.status,
      collectionSource: ActivityImpactFeedbackCollectionSource.userInitiated,
    );
  }

  final LifeDay lifeDay;
  final ActivitySubcategory subcategory;
  final DurationSlot duration;
  final int theoreticalDelta;
  final int appliedDelta;
  final ActivityImpactSign impactSign;
  final String ruleVersion;
  final ActivityFeedbackDirection direction;
  final ActivityFeedbackStatus status;
  final ActivityImpactFeedbackCollectionSource collectionSource;

  ActivityImpactKey get key =>
      ActivityImpactKey(subcategory: subcategory, impactSign: impactSign);

  bool get isRecoveryTruncated =>
      impactSign == ActivityImpactSign.recovery &&
      appliedDelta < theoreticalDelta;

  bool get isNonZero =>
      theoreticalDelta != 0 && impactSign != ActivityImpactSign.zero;

  bool get isComparable =>
      status == ActivityFeedbackStatus.active &&
      isNonZero &&
      !isRecoveryTruncated &&
      appliedDelta == theoreticalDelta;
}

final class ActivityImpactKeyAudit {
  ActivityImpactKeyAudit({
    required this.key,
    required this.totalCount,
    required this.activeCount,
    required this.invalidatedCount,
    required Set<LifeDay> lifeDays,
    required Set<LifeDay> sampledLifeDays,
    required Map<ActivityFeedbackDirection, int> directionCounts,
    required Map<ActivityFeedbackDirection, int> sampledDirectionCounts,
    required Set<DurationSlot> durationSlots,
    required Set<String> ruleVersions,
    required this.zeroTheoreticalCount,
    required this.recoveryTruncatedCount,
    required this.comparableCount,
    required this.sampledComparableCount,
    required this.sampledFactorEligibleCount,
  }) : lifeDays = UnmodifiableSetView({...lifeDays}),
       sampledLifeDays = UnmodifiableSetView({...sampledLifeDays}),
       directionCounts = UnmodifiableMapView({...directionCounts}),
       sampledDirectionCounts = UnmodifiableMapView({
         ...sampledDirectionCounts,
       }),
       durationSlots = UnmodifiableSetView({...durationSlots}),
       ruleVersions = UnmodifiableSetView({...ruleVersions});

  final ActivityImpactKey key;
  final int totalCount;
  final int activeCount;
  final int invalidatedCount;
  final Set<LifeDay> lifeDays;
  final Set<LifeDay> sampledLifeDays;
  final Map<ActivityFeedbackDirection, int> directionCounts;
  final Map<ActivityFeedbackDirection, int> sampledDirectionCounts;
  final Set<DurationSlot> durationSlots;
  final Set<String> ruleVersions;
  final int zeroTheoreticalCount;
  final int recoveryTruncatedCount;
  final int comparableCount;
  final int sampledComparableCount;
  final int sampledFactorEligibleCount;

  int count(ActivityFeedbackDirection direction) =>
      directionCounts[direction] ?? 0;

  int get strongerCount => count(ActivityFeedbackDirection.strongerImpact);
  int get aboutRightCount => count(ActivityFeedbackDirection.aboutRight);
  int get weakerCount => count(ActivityFeedbackDirection.weakerImpact);
  int get directionMismatchCount =>
      count(ActivityFeedbackDirection.directionMismatch);

  int get sampledDirectionMismatchCount =>
      sampledDirectionCounts[ActivityFeedbackDirection.directionMismatch] ?? 0;

  double get directionMismatchRatio => sampledComparableCount == 0
      ? 0
      : sampledDirectionMismatchCount / sampledComparableCount;

  int get durationMinMinutes => durationSlots.isEmpty
      ? 0
      : durationSlots
            .map((slot) => slot.minutes)
            .reduce((a, b) => a < b ? a : b);

  int get durationMaxMinutes => durationSlots.isEmpty
      ? 0
      : durationSlots
            .map((slot) => slot.minutes)
            .reduce((a, b) => a > b ? a : b);

  int get durationSpanMinutes => durationMaxMinutes - durationMinMinutes;

  bool get hasSingleRuleVersion => ruleVersions.length == 1;
}

final class ActivityImpactFeasibilityAudit {
  const ActivityImpactFeasibilityAudit();

  Map<ActivityImpactKey, ActivityImpactKeyAudit> audit(
    Iterable<ActivityImpactFeedbackObservation> observations,
  ) {
    final grouped =
        <ActivityImpactKey, List<ActivityImpactFeedbackObservation>>{};
    for (final observation in observations) {
      grouped.putIfAbsent(observation.key, () => []).add(observation);
    }
    final keys = grouped.keys.toList()..sort();
    return {for (final key in keys) key: _auditKey(key, grouped[key]!)};
  }

  ActivityImpactKeyAudit _auditKey(
    ActivityImpactKey key,
    List<ActivityImpactFeedbackObservation> values,
  ) {
    final lifeDays = <LifeDay>{};
    final sampledLifeDays = <LifeDay>{};
    final directionCounts = <ActivityFeedbackDirection, int>{};
    final sampledDirectionCounts = <ActivityFeedbackDirection, int>{};
    final durationSlots = <DurationSlot>{};
    final ruleVersions = <String>{};
    var active = 0;
    var invalidated = 0;
    var zero = 0;
    var truncated = 0;
    var comparable = 0;
    var sampledComparable = 0;
    var sampledFactorEligible = 0;
    for (final value in values) {
      lifeDays.add(value.lifeDay);
      durationSlots.add(value.duration);
      ruleVersions.add(value.ruleVersion);
      directionCounts.update(
        value.direction,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (value.status == ActivityFeedbackStatus.active) {
        active++;
      } else {
        invalidated++;
      }
      if (!value.isNonZero) zero++;
      if (value.isRecoveryTruncated) truncated++;
      if (value.isComparable) {
        comparable++;
        if (value.collectionSource ==
            ActivityImpactFeedbackCollectionSource.sampledPrompt) {
          sampledDirectionCounts.update(
            value.direction,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
        if (value.collectionSource ==
            ActivityImpactFeedbackCollectionSource.sampledPrompt) {
          sampledLifeDays.add(value.lifeDay);
          sampledComparable++;
          if (value.direction != ActivityFeedbackDirection.directionMismatch) {
            sampledFactorEligible++;
          }
        }
      }
    }
    return ActivityImpactKeyAudit(
      key: key,
      totalCount: values.length,
      activeCount: active,
      invalidatedCount: invalidated,
      lifeDays: lifeDays,
      sampledLifeDays: sampledLifeDays,
      directionCounts: directionCounts,
      sampledDirectionCounts: sampledDirectionCounts,
      durationSlots: durationSlots,
      ruleVersions: ruleVersions,
      zeroTheoreticalCount: zero,
      recoveryTruncatedCount: truncated,
      comparableCount: comparable,
      sampledComparableCount: sampledComparable,
      sampledFactorEligibleCount: sampledFactorEligible,
    );
  }
}

final class ActivityImpactSamplingPolicyV1 {
  const ActivityImpactSamplingPolicyV1({
    this.algorithmVersion = activityImpactSamplingAlgorithmV1,
    this.policyVersion = activityFeedbackSamplingPolicyV1,
    this.watermark = activityImpactPreproductionWatermark,
    this.supportedRuleVersion = activityImpactSupportedRuleVersion,
    this.productionLearningEnabled = false,
    this.autoApplyEnabled = false,
    this.dailyPromptCap = 1,
    this.skipCooldownLifeDays = 1,
    this.noResponseCooldownLifeDays = 3,
    this.minimumSamplesPerKey = 8,
    this.minimumCoverageDays = 4,
    this.minimumDirectionMismatchCount = 2,
    this.directionMismatchVetoRatio = 0.25,
    this.maximumDurationSpanMinutes = 60,
    this.minimumFactor = 0.50,
    this.maximumFactor = 1.50,
    this.factorStep = 0.05,
  });

  final String algorithmVersion;
  final String policyVersion;
  final String watermark;
  final String supportedRuleVersion;
  final bool productionLearningEnabled;
  final bool autoApplyEnabled;
  final int dailyPromptCap;
  final int skipCooldownLifeDays;
  final int noResponseCooldownLifeDays;
  final int minimumSamplesPerKey;
  final int minimumCoverageDays;
  final int minimumDirectionMismatchCount;
  final double directionMismatchVetoRatio;
  final int maximumDurationSpanMinutes;
  final double minimumFactor;
  final double maximumFactor;
  final double factorStep;

  bool get isValid =>
      algorithmVersion == activityImpactSamplingAlgorithmV1 &&
      policyVersion == activityFeedbackSamplingPolicyV1 &&
      watermark == activityImpactPreproductionWatermark &&
      supportedRuleVersion.trim().isNotEmpty &&
      !productionLearningEnabled &&
      !autoApplyEnabled &&
      dailyPromptCap == 1 &&
      skipCooldownLifeDays == 1 &&
      noResponseCooldownLifeDays == 3 &&
      minimumSamplesPerKey == 8 &&
      minimumCoverageDays == 4 &&
      minimumDirectionMismatchCount == 2 &&
      directionMismatchVetoRatio == 0.25 &&
      maximumDurationSpanMinutes == 60 &&
      minimumFactor > 0 &&
      maximumFactor > minimumFactor &&
      factorStep > 0 &&
      _isStepAligned(minimumFactor) &&
      _isStepAligned(maximumFactor);

  bool isFactorInRange(double factor) =>
      factor >= minimumFactor &&
      factor <= maximumFactor &&
      _isStepAligned(factor);

  bool _isStepAligned(double factor) {
    final steps = (factor / factorStep).roundToDouble();
    return (factor - steps * factorStep).abs() < 0.0000001;
  }
}

enum ActivityImpactRoundingMode {
  nearestIntegerHalfAwayFromZero('nearestIntegerHalfAwayFromZero');

  const ActivityImpactRoundingMode(this.code);

  final String code;
}

final class ActivityImpactFactorCalculation {
  const ActivityImpactFactorCalculation({
    required this.factor,
    required this.personalizedTheoreticalDelta,
    required this.appliedDelta,
  });

  final double factor;
  final int personalizedTheoreticalDelta;
  final int appliedDelta;
}

/// Shared calculation contract for B3-1.  It keeps the fixed-rule sign and
/// applies the existing recovery ceiling only after deterministic rounding.
final class ActivityImpactFactorCalculator {
  const ActivityImpactFactorCalculator({
    this.roundingMode =
        ActivityImpactRoundingMode.nearestIntegerHalfAwayFromZero,
  });

  final ActivityImpactRoundingMode roundingMode;

  ActivityImpactFactorCalculation calculate({
    required int theoreticalDelta,
    required double factor,
    required int currentEstimate,
    required int initialEstimate,
    ActivityImpactSamplingPolicyV1 policy =
        const ActivityImpactSamplingPolicyV1(),
  }) {
    if (!policy.isValid ||
        roundingMode !=
            ActivityImpactRoundingMode.nearestIntegerHalfAwayFromZero ||
        !policy.isFactorInRange(factor)) {
      throw ArgumentError.value(
        factor,
        'factor',
        'Unsupported activity factor',
      );
    }
    if (theoreticalDelta == 0) {
      throw ArgumentError.value(
        theoreticalDelta,
        'theoreticalDelta',
        'Zero theoretical activity cannot receive a factor',
      );
    }
    final personalized = (theoreticalDelta * factor).round();
    final applied = personalized <= 0
        ? personalized
        : personalized.clamp(
            0,
            (initialEstimate - currentEstimate).clamp(0, 1 << 30),
          );
    return ActivityImpactFactorCalculation(
      factor: factor,
      personalizedTheoreticalDelta: personalized,
      appliedDelta: applied,
    );
  }
}

enum ActivityImpactSampleStatus {
  selected('selected'),
  prompted('prompted'),
  responded('responded'),
  skipped('skipped'),
  expired('expired'),
  invalidated('invalidated');

  const ActivityImpactSampleStatus(this.code);

  final String code;
}

final class ActivityImpactSampleState {
  const ActivityImpactSampleState({
    required this.activityRecordId,
    required this.lifeDay,
    required this.policyVersion,
    required this.status,
  });

  final String activityRecordId;
  final LifeDay lifeDay;
  final String policyVersion;
  final ActivityImpactSampleStatus status;

  bool get isInvalidated => status == ActivityImpactSampleStatus.invalidated;

  bool canTransitionTo(ActivityImpactSampleStatus next) {
    if (status == ActivityImpactSampleStatus.invalidated) return false;
    return switch (status) {
      ActivityImpactSampleStatus.selected =>
        next == ActivityImpactSampleStatus.prompted ||
            next == ActivityImpactSampleStatus.skipped ||
            next == ActivityImpactSampleStatus.expired ||
            next == ActivityImpactSampleStatus.invalidated,
      ActivityImpactSampleStatus.prompted =>
        next == ActivityImpactSampleStatus.responded ||
            next == ActivityImpactSampleStatus.skipped ||
            next == ActivityImpactSampleStatus.expired ||
            next == ActivityImpactSampleStatus.invalidated,
      ActivityImpactSampleStatus.responded ||
      ActivityImpactSampleStatus.skipped ||
      ActivityImpactSampleStatus.expired =>
        next == ActivityImpactSampleStatus.invalidated,
      ActivityImpactSampleStatus.invalidated => false,
    };
  }
}

final class ActivityImpactSamplingActivity {
  const ActivityImpactSamplingActivity({
    required this.id,
    required this.lifeDay,
    required this.subcategory,
    required this.duration,
    required this.theoreticalDelta,
    required this.appliedDelta,
    required this.ruleVersion,
    required this.status,
  });

  factory ActivityImpactSamplingActivity.fromStored(
    StoredEstimatedActivity activity,
  ) {
    return ActivityImpactSamplingActivity(
      id: activity.id,
      lifeDay: activity.lifeDay,
      subcategory: activity.subcategory,
      duration: activity.duration,
      theoreticalDelta: activity.theoreticalDelta,
      appliedDelta: activity.appliedDelta,
      ruleVersion: activity.ruleVersion,
      status: activity.status,
    );
  }

  final String id;
  final LifeDay lifeDay;
  final ActivitySubcategory subcategory;
  final DurationSlot duration;
  final int theoreticalDelta;
  final int appliedDelta;
  final String ruleVersion;
  final ActivityRecordStatus status;

  ActivityImpactSign get impactSign =>
      activityImpactContractSign(theoreticalDelta);

  bool get isRecoveryTruncated =>
      impactSign == ActivityImpactSign.recovery &&
      appliedDelta < theoreticalDelta;

  bool isEligible(ActivityImpactSamplingPolicyV1 policy, LifeDay currentDay) =>
      policy.isValid &&
      id.trim().isNotEmpty &&
      lifeDay == currentDay &&
      status == ActivityRecordStatus.active &&
      ruleVersion == policy.supportedRuleVersion &&
      theoreticalDelta != 0 &&
      impactSign != ActivityImpactSign.zero &&
      !isRecoveryTruncated &&
      appliedDelta == theoreticalDelta;
}

enum ActivityImpactNoPromptReason {
  invalidConfiguration,
  modeOff,
  dailyCap,
  skipCooldown,
  noResponseCooldown,
  noEligibleActivity,
}

final class ActivityImpactSampleSelection {
  const ActivityImpactSampleSelection({
    required this.activity,
    required this.reason,
  });

  final ActivityImpactSamplingActivity? activity;
  final ActivityImpactNoPromptReason? reason;

  bool get hasPrompt => activity != null;
}

/// Deterministic, result-blind sampler.  Its input intentionally has no
/// feedback direction or prediction-error field, preventing post-outcome
/// selection bias at the type boundary.
final class ActivityImpactSampler {
  const ActivityImpactSampler();

  ActivityImpactSampleSelection select({
    required LearningMode mode,
    required LifeDay currentLifeDay,
    required Iterable<ActivityImpactSamplingActivity> activities,
    required Iterable<ActivityImpactSampleState> samples,
    ActivityImpactSamplingPolicyV1 policy =
        const ActivityImpactSamplingPolicyV1(),
  }) {
    if (!policy.isValid) {
      return const ActivityImpactSampleSelection(
        activity: null,
        reason: ActivityImpactNoPromptReason.invalidConfiguration,
      );
    }
    if (mode == LearningMode.off) {
      return const ActivityImpactSampleSelection(
        activity: null,
        reason: ActivityImpactNoPromptReason.modeOff,
      );
    }
    final sampleList = samples.toList(growable: false);
    final activeSamples = sampleList.where((item) => !item.isInvalidated);
    final currentDayCount = activeSamples
        .where(
          (item) =>
              item.policyVersion == policy.policyVersion &&
              item.lifeDay == currentLifeDay,
        )
        .length;
    if (currentDayCount >= policy.dailyPromptCap) {
      return const ActivityImpactSampleSelection(
        activity: null,
        reason: ActivityImpactNoPromptReason.dailyCap,
      );
    }
    final lastSkipped = _latestDay(
      activeSamples.where(
        (item) =>
            item.policyVersion == policy.policyVersion &&
            item.status == ActivityImpactSampleStatus.skipped,
      ),
    );
    if (lastSkipped != null &&
        _daysBetween(lastSkipped, currentLifeDay) <=
            policy.skipCooldownLifeDays) {
      return const ActivityImpactSampleSelection(
        activity: null,
        reason: ActivityImpactNoPromptReason.skipCooldown,
      );
    }
    final lastNoResponse = _latestDay(
      activeSamples.where(
        (item) =>
            item.policyVersion == policy.policyVersion &&
            (item.status == ActivityImpactSampleStatus.prompted ||
                item.status == ActivityImpactSampleStatus.expired),
      ),
    );
    if (lastNoResponse != null &&
        _daysBetween(lastNoResponse, currentLifeDay) <=
            policy.noResponseCooldownLifeDays) {
      return const ActivityImpactSampleSelection(
        activity: null,
        reason: ActivityImpactNoPromptReason.noResponseCooldown,
      );
    }
    final existingActivityIds = activeSamples
        .where((item) => item.policyVersion == policy.policyVersion)
        .map((item) => item.activityRecordId)
        .toSet();
    final eligible = activities
        .where((activity) => activity.isEligible(policy, currentLifeDay))
        .where((activity) => !existingActivityIds.contains(activity.id))
        .toList();
    if (eligible.isEmpty) {
      return const ActivityImpactSampleSelection(
        activity: null,
        reason: ActivityImpactNoPromptReason.noEligibleActivity,
      );
    }
    eligible.sort((a, b) {
      final aHash = _stableHash(policy.policyVersion, currentLifeDay, a.id);
      final bHash = _stableHash(policy.policyVersion, currentLifeDay, b.id);
      final byHash = aHash.compareTo(bHash);
      return byHash == 0 ? a.id.compareTo(b.id) : byHash;
    });
    return ActivityImpactSampleSelection(
      activity: eligible.first,
      reason: null,
    );
  }

  String _stableHash(String policyVersion, LifeDay day, String activityId) =>
      sha256.convert(utf8.encode('$policyVersion|$day|$activityId')).toString();

  LifeDay? _latestDay(Iterable<ActivityImpactSampleState> values) {
    LifeDay? latest;
    for (final value in values) {
      if (latest == null || value.lifeDay.compareTo(latest) > 0) {
        latest = value.lifeDay;
      }
    }
    return latest;
  }

  int _daysBetween(LifeDay earlier, LifeDay later) {
    final first = DateTime(earlier.year, earlier.month, earlier.day);
    final second = DateTime(later.year, later.month, later.day);
    return (second.difference(first).inHours / 24).round().abs();
  }
}

enum ActivityImpactFactorGateResult {
  eligible,
  configurationBlocked,
  zeroOrTruncated,
  unsupportedRuleVersion,
  insufficientEvidence,
  directionMismatchVeto,
  unstableDuration,
}

final class ActivityImpactFactorGateDecision {
  const ActivityImpactFactorGateDecision({
    required this.key,
    required this.result,
    required this.reasonCodes,
  });

  final ActivityImpactKey key;
  final ActivityImpactFactorGateResult result;
  final List<String> reasonCodes;

  bool get eligibleForShadow =>
      result == ActivityImpactFactorGateResult.eligible;
}

/// B3-0 feasibility gate.  It can approve a pre-production shadow fixture,
/// never a production activation, because the policy itself is watermarked
/// and has both production flags closed.
final class ActivityImpactFactorGate {
  const ActivityImpactFactorGate();

  ActivityImpactFactorGateDecision evaluate(
    ActivityImpactKeyAudit audit, {
    ActivityImpactSamplingPolicyV1 policy =
        const ActivityImpactSamplingPolicyV1(),
  }) {
    if (!policy.isValid) {
      return _decision(
        audit,
        ActivityImpactFactorGateResult.configurationBlocked,
        'invalidActivityImpactConfiguration',
      );
    }
    if (!audit.key.isFactorEligible ||
        audit.zeroTheoreticalCount > 0 ||
        audit.recoveryTruncatedCount > 0) {
      return _decision(
        audit,
        ActivityImpactFactorGateResult.zeroOrTruncated,
        'zeroOrTruncatedEvidence',
      );
    }
    if (audit.ruleVersions.any(
      (version) => version != policy.supportedRuleVersion,
    )) {
      return _decision(
        audit,
        ActivityImpactFactorGateResult.unsupportedRuleVersion,
        'unsupportedRuleVersion',
      );
    }
    if (audit.sampledDirectionMismatchCount >=
            policy.minimumDirectionMismatchCount &&
        audit.directionMismatchRatio >= policy.directionMismatchVetoRatio) {
      return _decision(
        audit,
        ActivityImpactFactorGateResult.directionMismatchVeto,
        'directionMismatchVeto',
      );
    }
    if (audit.durationSpanMinutes > policy.maximumDurationSpanMinutes) {
      return _decision(
        audit,
        ActivityImpactFactorGateResult.unstableDuration,
        'durationHeterogeneity',
      );
    }
    if (audit.sampledFactorEligibleCount < policy.minimumSamplesPerKey ||
        _sampledCoverageDays(audit) < policy.minimumCoverageDays) {
      return _decision(
        audit,
        ActivityImpactFactorGateResult.insufficientEvidence,
        'minimumSampleOrDayNotMet',
      );
    }
    return _decision(
      audit,
      ActivityImpactFactorGateResult.eligible,
      'preproductionShadowEligible',
    );
  }

  int _sampledCoverageDays(ActivityImpactKeyAudit audit) {
    return audit.sampledLifeDays.length;
  }

  ActivityImpactFactorGateDecision _decision(
    ActivityImpactKeyAudit audit,
    ActivityImpactFactorGateResult result,
    String reason,
  ) => ActivityImpactFactorGateDecision(
    key: audit.key,
    result: result,
    reasonCodes: [reason],
  );
}
