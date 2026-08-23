import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/observation_comparison_service.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';

enum BaselineReplayMode { review, automatic }

enum BaselineReplayOutcome {
  insufficientEvidence,
  unstable,
  noChange,
  candidate,
  configurationBlocked,
}

enum BaselineReplayDirection { decrease, increase }

enum BaselineReplayReason {
  evidenceNotReady('evidenceNotReady'),
  unsupportedReferenceType('unsupportedReferenceType'),
  invalidShadowOnlyConfiguration('invalidShadowOnlyConfiguration'),
  malformedFrozenEvidence('malformedFrozenEvidence'),
  stableAlignment('stableAlignment'),
  directionUnstable('directionUnstable'),
  hardRangeBoundary('hardRangeBoundary'),
  anchorBoundary('anchorBoundary'),
  counterfactualInvalidInitialEstimate('counterfactualInvalidInitialEstimate'),
  counterfactualAlignedCountDecreased('counterfactualAlignedCountDecreased'),
  counterfactualOppositeCountIncreased('counterfactualOppositeCountIncreased'),
  counterfactualOrdinalErrorIncreased('counterfactualOrdinalErrorIncreased'),
  minimumUsefulImprovementNotMet('minimumUsefulImprovementNotMet'),
  shadowCandidateOnly('shadowCandidateOnly');

  const BaselineReplayReason(this.code);
  final String code;
}

final class BaselineDirectionThresholds {
  const BaselineDirectionThresholds({
    required this.minimumSameDirectionPerWindow,
    required this.minimumSameDirectionTotal,
    required this.maximumOppositePerWindow,
  });

  final int minimumSameDirectionPerWindow;
  final int minimumSameDirectionTotal;
  final int maximumOppositePerWindow;

  bool get isValid =>
      minimumSameDirectionPerWindow > 0 &&
      minimumSameDirectionPerWindow <= 7 &&
      minimumSameDirectionTotal > 0 &&
      minimumSameDirectionTotal <= 14 &&
      maximumOppositePerWindow >= 0 &&
      maximumOppositePerWindow <= 7;
}

/// Configuration for an offline, non-persisted candidate replay.
///
/// This type deliberately has no production defaults. A caller must provide an
/// explicitly watermarked configuration, and this engine rejects any config
/// that claims candidates may be activated.
final class BaselineShadowReplayConfig {
  BaselineShadowReplayConfig({
    required this.algorithmVersion,
    required this.configVersion,
    required this.watermark,
    required this.activationAllowed,
    required List<ObservationReferenceType> referencePriority,
    required this.reviewThresholds,
    required this.automaticThresholds,
    required this.step,
    required this.anchorCumulativeLimit,
    required this.hardMinimum,
    required this.hardMaximum,
    required this.minimumCounterfactualAlignedGain,
    required this.minimumCounterfactualOrdinalErrorReduction,
  }) : referencePriority = List.unmodifiable(referencePriority);

  final String algorithmVersion;
  final String configVersion;
  final String watermark;
  final bool activationAllowed;
  final List<ObservationReferenceType> referencePriority;
  final BaselineDirectionThresholds reviewThresholds;
  final BaselineDirectionThresholds automaticThresholds;
  final int step;
  final int anchorCumulativeLimit;
  final int hardMinimum;
  final int hardMaximum;
  final int minimumCounterfactualAlignedGain;
  final int minimumCounterfactualOrdinalErrorReduction;

  bool get isValidShadowOnly {
    return algorithmVersion.trim().isNotEmpty &&
        configVersion.trim().isNotEmpty &&
        watermark == preproductionOnlyWatermark &&
        !activationAllowed &&
        referencePriority.isNotEmpty &&
        referencePriority.toSet().length == referencePriority.length &&
        reviewThresholds.isValid &&
        automaticThresholds.isValid &&
        automaticThresholds.minimumSameDirectionPerWindow >=
            reviewThresholds.minimumSameDirectionPerWindow &&
        automaticThresholds.minimumSameDirectionTotal >=
            reviewThresholds.minimumSameDirectionTotal &&
        automaticThresholds.maximumOppositePerWindow <=
            reviewThresholds.maximumOppositePerWindow &&
        step > 0 &&
        anchorCumulativeLimit >= step &&
        hardMinimum == 60 &&
        hardMaximum == 140 &&
        minimumCounterfactualAlignedGain > 0 &&
        minimumCounterfactualOrdinalErrorReduction > 0;
  }
}

const preproductionOnlyWatermark = 'PREPRODUCTION_ONLY_DO_NOT_ACTIVATE_OR_SHIP';

final class BaselineCounterfactualMetrics {
  const BaselineCounterfactualMetrics({
    required this.lower,
    required this.aligned,
    required this.higher,
    required this.opposite,
    required this.totalAbsoluteOrdinalError,
  });

  final int lower;
  final int aligned;
  final int higher;
  final int opposite;
  final int totalAbsoluteOrdinalError;

  Map<String, Object?> toJson() => {
    'aligned': aligned,
    'higher': higher,
    'lower': lower,
    'opposite': opposite,
    'totalAbsoluteOrdinalError': totalAbsoluteOrdinalError,
  };
}

final class BaselineShadowReplayResult {
  BaselineShadowReplayResult({
    required this.outcome,
    required this.mode,
    required this.currentBaseEnergy,
    required this.baselineAnchorEnergy,
    required this.direction,
    required this.candidateBaseEnergy,
    required this.candidateValuesJson,
    required this.before,
    required this.after,
    required List<BaselineReplayReason> reasons,
  }) : reasons = List.unmodifiable(reasons);

  final BaselineReplayOutcome outcome;
  final BaselineReplayMode mode;
  final int currentBaseEnergy;
  final int baselineAnchorEnergy;
  final BaselineReplayDirection? direction;
  final int? candidateBaseEnergy;
  final String? candidateValuesJson;
  final BaselineCounterfactualMetrics? before;
  final BaselineCounterfactualMetrics? after;
  final List<BaselineReplayReason> reasons;
}

/// Runs the B1-1 engineering counterfactual without persistence or activation.
///
/// It consumes the canonical B1-0 evidence snapshot and intentionally exposes
/// no repository, coordinator, settings, or model-lifecycle dependency.
final class BaselineShadowReplayEngine {
  const BaselineShadowReplayEngine({
    this.comparisonService = const ObservationComparisonService(),
    this.canonicalEncoder = const CanonicalJsonEncoder(),
  });

  final ObservationComparisonService comparisonService;
  final CanonicalJsonEncoder canonicalEncoder;

  BaselineShadowReplayResult replay({
    required ShadowEvidencePackage evidence,
    required int baselineAnchorEnergy,
    required BaselineReplayMode mode,
    required BaselineShadowReplayConfig config,
  }) {
    if (!config.isValidShadowOnly) {
      return _result(
        evidence: evidence,
        baselineAnchorEnergy: baselineAnchorEnergy,
        mode: mode,
        outcome: BaselineReplayOutcome.configurationBlocked,
        reasons: const [BaselineReplayReason.invalidShadowOnlyConfiguration],
      );
    }
    if (!config.referencePriority.contains(evidence.referenceType)) {
      return _result(
        evidence: evidence,
        baselineAnchorEnergy: baselineAnchorEnergy,
        mode: mode,
        outcome: BaselineReplayOutcome.configurationBlocked,
        reasons: const [BaselineReplayReason.unsupportedReferenceType],
      );
    }
    if (evidence.baseEnergy < config.hardMinimum ||
        evidence.baseEnergy > config.hardMaximum ||
        baselineAnchorEnergy < config.hardMinimum ||
        baselineAnchorEnergy > config.hardMaximum) {
      return _result(
        evidence: evidence,
        baselineAnchorEnergy: baselineAnchorEnergy,
        mode: mode,
        outcome: BaselineReplayOutcome.configurationBlocked,
        reasons: const [BaselineReplayReason.malformedFrozenEvidence],
      );
    }
    if (!evidence.readiness.ready ||
        evidence.selectedEligible != 14 ||
        evidence.windowSizes.length != 2 ||
        evidence.windowSizes.any((size) => size != 7)) {
      return _result(
        evidence: evidence,
        baselineAnchorEnergy: baselineAnchorEnergy,
        mode: mode,
        outcome: BaselineReplayOutcome.insufficientEvidence,
        reasons: const [BaselineReplayReason.evidenceNotReady],
      );
    }

    final frozen = _decodeFrozenEvidence(evidence, config);
    if (frozen == null || frozen.length != evidence.selectedEligible) {
      return _result(
        evidence: evidence,
        baselineAnchorEnergy: baselineAnchorEnergy,
        mode: mode,
        outcome: BaselineReplayOutcome.configurationBlocked,
        reasons: const [BaselineReplayReason.malformedFrozenEvidence],
      );
    }
    final beforeComparisons = <ObservationComparisonResult>[];
    for (final item in frozen) {
      final before = comparisonService.compare(
        actualState: item.actualState,
        estimate: item.estimate,
        initialEstimate: item.initialEstimate,
      );
      if (!before.isValid) {
        return _result(
          evidence: evidence,
          baselineAnchorEnergy: baselineAnchorEnergy,
          mode: mode,
          outcome: BaselineReplayOutcome.configurationBlocked,
          reasons: const [BaselineReplayReason.malformedFrozenEvidence],
        );
      }
      beforeComparisons.add(before);
    }
    if (!_matchesFrozenDirectionCounts(beforeComparisons, evidence)) {
      return _result(
        evidence: evidence,
        baselineAnchorEnergy: baselineAnchorEnergy,
        mode: mode,
        outcome: BaselineReplayOutcome.configurationBlocked,
        reasons: const [BaselineReplayReason.malformedFrozenEvidence],
      );
    }

    final thresholds = switch (mode) {
      BaselineReplayMode.review => config.reviewThresholds,
      BaselineReplayMode.automatic => config.automaticThresholds,
    };
    final lowerStable = _directionIsStable(
      evidence: evidence,
      direction: BaselineReplayDirection.decrease,
      thresholds: thresholds,
    );
    final higherStable = _directionIsStable(
      evidence: evidence,
      direction: BaselineReplayDirection.increase,
      thresholds: thresholds,
    );
    if (!lowerStable && !higherStable) {
      final alignedStable = _alignmentIsStable(
        evidence: evidence,
        thresholds: thresholds,
      );
      return _result(
        evidence: evidence,
        baselineAnchorEnergy: baselineAnchorEnergy,
        mode: mode,
        outcome: alignedStable
            ? BaselineReplayOutcome.noChange
            : BaselineReplayOutcome.unstable,
        reasons: [
          alignedStable
              ? BaselineReplayReason.stableAlignment
              : BaselineReplayReason.directionUnstable,
        ],
      );
    }
    if (lowerStable == higherStable) {
      return _result(
        evidence: evidence,
        baselineAnchorEnergy: baselineAnchorEnergy,
        mode: mode,
        outcome: BaselineReplayOutcome.configurationBlocked,
        reasons: const [BaselineReplayReason.malformedFrozenEvidence],
      );
    }

    final direction = lowerStable
        ? BaselineReplayDirection.decrease
        : BaselineReplayDirection.increase;
    final delta = direction == BaselineReplayDirection.decrease
        ? -config.step
        : config.step;
    final candidate = evidence.baseEnergy + delta;
    if (candidate < config.hardMinimum || candidate > config.hardMaximum) {
      return _result(
        evidence: evidence,
        baselineAnchorEnergy: baselineAnchorEnergy,
        mode: mode,
        outcome: BaselineReplayOutcome.noChange,
        direction: direction,
        reasons: const [BaselineReplayReason.hardRangeBoundary],
      );
    }
    if ((candidate - baselineAnchorEnergy).abs() >
        config.anchorCumulativeLimit) {
      return _result(
        evidence: evidence,
        baselineAnchorEnergy: baselineAnchorEnergy,
        mode: mode,
        outcome: BaselineReplayOutcome.noChange,
        direction: direction,
        reasons: const [BaselineReplayReason.anchorBoundary],
      );
    }

    final afterComparisons = <ObservationComparisonResult>[];
    for (final item in frozen) {
      final after = comparisonService.compare(
        actualState: item.actualState,
        estimate: item.estimate + delta,
        initialEstimate: item.initialEstimate + delta,
      );
      if (!after.isValid) {
        return _result(
          evidence: evidence,
          baselineAnchorEnergy: baselineAnchorEnergy,
          mode: mode,
          outcome: BaselineReplayOutcome.configurationBlocked,
          direction: direction,
          reasons: const [
            BaselineReplayReason.counterfactualInvalidInitialEstimate,
          ],
        );
      }
      afterComparisons.add(after);
    }
    final before = _metrics(beforeComparisons, direction);
    final after = _metrics(afterComparisons, direction);
    final safetyReasons = <BaselineReplayReason>[
      if (after.aligned < before.aligned)
        BaselineReplayReason.counterfactualAlignedCountDecreased,
      if (after.opposite > before.opposite)
        BaselineReplayReason.counterfactualOppositeCountIncreased,
      if (after.totalAbsoluteOrdinalError > before.totalAbsoluteOrdinalError)
        BaselineReplayReason.counterfactualOrdinalErrorIncreased,
    ];
    final alignedGain = after.aligned - before.aligned;
    final errorReduction =
        before.totalAbsoluteOrdinalError - after.totalAbsoluteOrdinalError;
    if (alignedGain < config.minimumCounterfactualAlignedGain ||
        errorReduction < config.minimumCounterfactualOrdinalErrorReduction) {
      safetyReasons.add(BaselineReplayReason.minimumUsefulImprovementNotMet);
    }
    if (safetyReasons.isNotEmpty) {
      return _result(
        evidence: evidence,
        baselineAnchorEnergy: baselineAnchorEnergy,
        mode: mode,
        outcome: BaselineReplayOutcome.noChange,
        direction: direction,
        before: before,
        after: after,
        reasons: safetyReasons,
      );
    }

    return _result(
      evidence: evidence,
      baselineAnchorEnergy: baselineAnchorEnergy,
      mode: mode,
      outcome: BaselineReplayOutcome.candidate,
      direction: direction,
      candidateBaseEnergy: candidate,
      candidateValuesJson: canonicalEncoder.encode({
        'activationAllowed': false,
        'baseEnergy': candidate,
        'watermark': config.watermark,
      }),
      before: before,
      after: after,
      reasons: const [BaselineReplayReason.shadowCandidateOnly],
    );
  }

  bool _directionIsStable({
    required ShadowEvidencePackage evidence,
    required BaselineReplayDirection direction,
    required BaselineDirectionThresholds thresholds,
  }) {
    final sameTotal = direction == BaselineReplayDirection.decrease
        ? evidence.directionCounts.lower
        : evidence.directionCounts.higher;
    if (sameTotal < thresholds.minimumSameDirectionTotal) return false;
    for (final window in evidence.windowDirectionCounts) {
      final same = direction == BaselineReplayDirection.decrease
          ? window.lower
          : window.higher;
      final opposite = direction == BaselineReplayDirection.decrease
          ? window.higher
          : window.lower;
      if (same < thresholds.minimumSameDirectionPerWindow ||
          opposite > thresholds.maximumOppositePerWindow) {
        return false;
      }
    }
    return true;
  }

  bool _alignmentIsStable({
    required ShadowEvidencePackage evidence,
    required BaselineDirectionThresholds thresholds,
  }) {
    return evidence.directionCounts.aligned >=
            thresholds.minimumSameDirectionTotal &&
        evidence.windowDirectionCounts.every(
          (window) =>
              window.aligned >= thresholds.minimumSameDirectionPerWindow,
        );
  }

  List<_FrozenReplayObservation>? _decodeFrozenEvidence(
    ShadowEvidencePackage evidence,
    BaselineShadowReplayConfig config,
  ) {
    try {
      final snapshot = jsonDecode(evidence.evidenceSnapshotJson);
      if (snapshot is! Map<String, Object?>) return null;
      if (canonicalEncoder.encode(snapshot) != evidence.evidenceSnapshotJson) {
        return null;
      }
      final hashInput = snapshot['hashInput'];
      if (hashInput is! Map<String, Object?>) return null;
      final isShadowEvidenceIdentity =
          hashInput['algorithmVersion'] == shadowLearningAlgorithmV1 &&
          hashInput['configVersion'] == shadowLearningConfigV1;
      final isReplayEvidenceIdentity =
          hashInput['algorithmVersion'] == config.algorithmVersion &&
          hashInput['configVersion'] == config.configVersion;
      if ((!isShadowEvidenceIdentity && !isReplayEvidenceIdentity) ||
          hashInput['evidenceHashVersion'] != canonicalEvidenceHashV1 ||
          hashInput['parameterFamily'] !=
              LearningParameterFamily.baseline.code ||
          hashInput['referenceType'] != evidence.referenceType.code ||
          hashInput['sourceModelIdentity'] != evidence.sourceModelIdentity) {
        return null;
      }
      final canonicalHashInput = canonicalEncoder.encode(hashInput);
      if (sha256.convert(utf8.encode(canonicalHashInput)).toString() !=
          evidence.evidenceHash) {
        return null;
      }
      final thresholds = hashInput['readinessThresholds'];
      if (thresholds is! Map<String, Object?> ||
          thresholds['minimumEligibleObservationPairs'] != 14 ||
          thresholds['minimumObservationSpanCalendarDays'] != 21 ||
          thresholds['shadowWindowCount'] != 2 ||
          thresholds['shadowWindowEligiblePairs'] != 7) {
        return null;
      }
      final selected = hashInput['selectedEligibleEvidence'];
      if (selected is! List<Object?>) return null;
      final result = <_FrozenReplayObservation>[];
      for (final value in selected) {
        if (value is! Map<String, Object?>) return null;
        final actualCode = value['absoluteState'];
        final estimate = value['estimateAtObservation'];
        final initialEstimate = value['initialEstimateAtObservation'];
        final baseEnergy = value['baseEnergyAtObservation'];
        final referenceType = value['referenceType'];
        final sourceModelIdentity = value['modelRegimeKey'];
        final storedDirection = value['alignmentDirection'];
        final storedEstimatedOrdinal = value['estimatedOrdinalAtObservation'];
        if (actualCode is! String ||
            estimate is! int ||
            initialEstimate is! int ||
            baseEnergy != evidence.baseEnergy ||
            referenceType != evidence.referenceType.code ||
            sourceModelIdentity != evidence.sourceModelIdentity ||
            storedDirection is! String ||
            storedEstimatedOrdinal is! int) {
          return null;
        }
        final actual = AbsoluteEnergyState.values
            .where((item) => item.code == actualCode)
            .firstOrNull;
        if (actual == null) return null;
        final comparison = comparisonService.compare(
          actualState: actual,
          estimate: estimate,
          initialEstimate: initialEstimate,
        );
        if (!comparison.isValid ||
            comparison.direction?.code != storedDirection ||
            comparison.estimatedOrdinal != storedEstimatedOrdinal) {
          return null;
        }
        result.add(
          _FrozenReplayObservation(
            actualState: actual,
            estimate: estimate,
            initialEstimate: initialEstimate,
          ),
        );
      }
      return result;
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  BaselineCounterfactualMetrics _metrics(
    List<ObservationComparisonResult> comparisons,
    BaselineReplayDirection intendedDirection,
  ) {
    var lower = 0;
    var aligned = 0;
    var higher = 0;
    var error = 0;
    for (final comparison in comparisons) {
      switch (comparison.direction!) {
        case ObservationAlignmentDirection.lower:
          lower++;
        case ObservationAlignmentDirection.aligned:
          aligned++;
        case ObservationAlignmentDirection.higher:
          higher++;
      }
      error += comparison.alignmentDelta!.abs();
    }
    final opposite = intendedDirection == BaselineReplayDirection.decrease
        ? higher
        : lower;
    return BaselineCounterfactualMetrics(
      lower: lower,
      aligned: aligned,
      higher: higher,
      opposite: opposite,
      totalAbsoluteOrdinalError: error,
    );
  }

  bool _matchesFrozenDirectionCounts(
    List<ObservationComparisonResult> comparisons,
    ShadowEvidencePackage evidence,
  ) {
    if (comparisons.length != 14 ||
        evidence.windowDirectionCounts.length != 2) {
      return false;
    }
    bool countsMatch(
      Iterable<ObservationComparisonResult> source,
      DirectionCounts expected,
    ) {
      var lower = 0;
      var aligned = 0;
      var higher = 0;
      for (final comparison in source) {
        switch (comparison.direction!) {
          case ObservationAlignmentDirection.lower:
            lower++;
          case ObservationAlignmentDirection.aligned:
            aligned++;
          case ObservationAlignmentDirection.higher:
            higher++;
        }
      }
      return lower == expected.lower &&
          aligned == expected.aligned &&
          higher == expected.higher;
    }

    return countsMatch(comparisons, evidence.directionCounts) &&
        countsMatch(
          comparisons.take(7),
          evidence.windowDirectionCounts.first,
        ) &&
        countsMatch(comparisons.skip(7), evidence.windowDirectionCounts.last);
  }

  BaselineShadowReplayResult _result({
    required ShadowEvidencePackage evidence,
    required int baselineAnchorEnergy,
    required BaselineReplayMode mode,
    required BaselineReplayOutcome outcome,
    required List<BaselineReplayReason> reasons,
    BaselineReplayDirection? direction,
    int? candidateBaseEnergy,
    String? candidateValuesJson,
    BaselineCounterfactualMetrics? before,
    BaselineCounterfactualMetrics? after,
  }) {
    return BaselineShadowReplayResult(
      outcome: outcome,
      mode: mode,
      currentBaseEnergy: evidence.baseEnergy,
      baselineAnchorEnergy: baselineAnchorEnergy,
      direction: direction,
      candidateBaseEnergy: candidateBaseEnergy,
      candidateValuesJson: candidateValuesJson,
      before: before,
      after: after,
      reasons: reasons,
    );
  }
}

final class _FrozenReplayObservation {
  const _FrozenReplayObservation({
    required this.actualState,
    required this.estimate,
    required this.initialEstimate,
  });

  final AbsoluteEnergyState actualState;
  final int estimate;
  final int initialEstimate;
}
