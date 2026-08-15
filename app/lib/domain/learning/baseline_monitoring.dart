import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/observation_comparison_service.dart';
import 'package:power_manager/domain/learning/baseline_shadow_replay.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';

const baselineMonitoringAlgorithmV1 = 'baseline-monitoring-v1';
const baselineMonitoringConfigV1 = 'baseline-monitoring-config-v1';

final class BaselineMonitoringConfig {
  const BaselineMonitoringConfig({
    this.algorithmVersion = baselineMonitoringAlgorithmV1,
    this.configVersion = baselineMonitoringConfigV1,
    this.watermark = preproductionOnlyWatermark,
    this.activationAllowed = false,
    this.minimumEligibleObservationPairs = 14,
    this.minimumObservationSpanCalendarDays = 21,
    this.windowCount = 2,
    this.windowEligiblePairs = 7,
    this.minimumUsefulAlignedGain = 2,
    this.minimumUsefulOrdinalErrorReduction = 2,
    this.maximumOppositeTotal = 2,
    this.maximumOppositePerWindow = 1,
    this.pauseExpectedOppositePerWindow = 5,
    this.pauseAlignedDrop = 3,
    this.pauseOrdinalErrorIncrease = 3,
  });

  final String algorithmVersion;
  final String configVersion;
  final String watermark;
  final bool activationAllowed;
  final int minimumEligibleObservationPairs;
  final int minimumObservationSpanCalendarDays;
  final int windowCount;
  final int windowEligiblePairs;
  final int minimumUsefulAlignedGain;
  final int minimumUsefulOrdinalErrorReduction;
  final int maximumOppositeTotal;
  final int maximumOppositePerWindow;
  final int pauseExpectedOppositePerWindow;
  final int pauseAlignedDrop;
  final int pauseOrdinalErrorIncrease;

  bool get isValid =>
      algorithmVersion.trim().isNotEmpty &&
      configVersion.trim().isNotEmpty &&
      watermark == preproductionOnlyWatermark &&
      !activationAllowed &&
      minimumEligibleObservationPairs == 14 &&
      minimumObservationSpanCalendarDays == 21 &&
      windowCount == 2 &&
      windowEligiblePairs == 7 &&
      minimumUsefulAlignedGain > 0 &&
      minimumUsefulOrdinalErrorReduction > 0 &&
      maximumOppositeTotal >= 0 &&
      maximumOppositePerWindow >= 0 &&
      pauseExpectedOppositePerWindow > maximumOppositePerWindow &&
      pauseAlignedDrop > 0 &&
      pauseOrdinalErrorIncrease > 0;
}

final class BaselineMonitoringMetrics {
  BaselineMonitoringMetrics({
    required this.aligned,
    required this.opposite,
    required this.totalAbsoluteOrdinalError,
    required List<int> windowAligned,
    required List<int> windowOpposite,
  }) : windowAligned = List.unmodifiable(windowAligned),
       windowOpposite = List.unmodifiable(windowOpposite);

  final int aligned;
  final int opposite;
  final int totalAbsoluteOrdinalError;
  final List<int> windowAligned;
  final List<int> windowOpposite;
}

final class BaselineMonitoringEvaluation {
  BaselineMonitoringEvaluation({
    required this.result,
    required List<String> reasonCodes,
    this.before,
    this.after,
  }) : reasonCodes = List.unmodifiable(reasonCodes);

  final LearningRunResult result;
  final List<String> reasonCodes;
  final BaselineMonitoringMetrics? before;
  final BaselineMonitoringMetrics? after;
}

/// Pure post-activation monitoring decision. It never writes settings or
/// versions; the coordinator applies a worsened result through the existing
/// transactional suspension service.
final class BaselineMonitoringEvaluator {
  const BaselineMonitoringEvaluator({
    this.comparisonService = const ObservationComparisonService(),
    this.canonicalEncoder = const CanonicalJsonEncoder(),
  });

  final ObservationComparisonService comparisonService;
  final CanonicalJsonEncoder canonicalEncoder;

  BaselineMonitoringEvaluation evaluate({
    required ShadowEvidencePackage evidence,
    required BaselineReplayDirection expectedDirection,
    required int baselineAligned,
    required int baselineOrdinalError,
    BaselineMonitoringConfig config = const BaselineMonitoringConfig(),
  }) {
    if (!config.isValid) {
      return BaselineMonitoringEvaluation(
        result: LearningRunResult.configurationBlocked,
        reasonCodes: ['invalidMonitoringConfiguration'],
      );
    }
    if (!evidence.readiness.ready ||
        evidence.selectedEligible != config.minimumEligibleObservationPairs ||
        evidence.windowSizes.length != config.windowCount ||
        evidence.windowSizes.any(
          (size) => size != config.windowEligiblePairs,
        )) {
      return BaselineMonitoringEvaluation(
        result: LearningRunResult.insufficientEvidence,
        reasonCodes: ['monitoringEvidenceNotReady'],
      );
    }
    final observations = _decode(evidence, config);
    if (observations == null || observations.length != 14) {
      return BaselineMonitoringEvaluation(
        result: LearningRunResult.configurationBlocked,
        reasonCodes: ['malformedMonitoringEvidence'],
      );
    }
    if (baselineAligned < 0 ||
        baselineAligned > 14 ||
        baselineOrdinalError < 0) {
      return BaselineMonitoringEvaluation(
        result: LearningRunResult.configurationBlocked,
        reasonCodes: ['invalidBaselineMetrics'],
      );
    }
    final comparisons = [
      for (final item in observations)
        comparisonService.compare(
          actualState: item.actualState,
          estimate: item.estimate,
          initialEstimate: item.initialEstimate,
        ),
    ];
    if (comparisons.any((item) => !item.isValid)) {
      return BaselineMonitoringEvaluation(
        result: LearningRunResult.configurationBlocked,
        reasonCodes: ['malformedMonitoringEvidence'],
      );
    }
    final after = _metrics(comparisons, expectedDirection);
    final before = BaselineMonitoringMetrics(
      aligned: baselineAligned,
      opposite: 0,
      totalAbsoluteOrdinalError: baselineOrdinalError,
      windowAligned: const [0, 0],
      windowOpposite: const [0, 0],
    );
    final alignedDrop = baselineAligned - after.aligned;
    final errorIncrease =
        after.totalAbsoluteOrdinalError - baselineOrdinalError;
    final expectedOppositeWindow = after.windowOpposite.every(
      (count) => count >= config.pauseExpectedOppositePerWindow,
    );
    if (expectedOppositeWindow ||
        (alignedDrop >= config.pauseAlignedDrop &&
            errorIncrease >= config.pauseOrdinalErrorIncrease) ||
        after.opposite > config.maximumOppositeTotal ||
        after.windowOpposite.any(
          (count) => count > config.maximumOppositePerWindow,
        )) {
      return BaselineMonitoringEvaluation(
        result: LearningRunResult.worsened,
        reasonCodes: [
          if (expectedOppositeWindow) 'expectedOppositeWindowBoundary',
          if (alignedDrop >= config.pauseAlignedDrop &&
              errorIncrease >= config.pauseOrdinalErrorIncrease)
            'alignedDropAndOrdinalErrorIncrease',
          if (after.opposite > config.maximumOppositeTotal)
            'oppositeTotalBoundary',
          if (after.windowOpposite.any(
            (count) => count > config.maximumOppositePerWindow,
          ))
            'oppositeWindowBoundary',
        ],
        before: before,
        after: after,
      );
    }
    final alignedGain = after.aligned - baselineAligned;
    final errorReduction =
        baselineOrdinalError - after.totalAbsoluteOrdinalError;
    if (alignedGain >= config.minimumUsefulAlignedGain &&
        errorReduction >= config.minimumUsefulOrdinalErrorReduction) {
      return BaselineMonitoringEvaluation(
        result: LearningRunResult.improved,
        reasonCodes: const ['minimumUsefulImprovementMet'],
        before: before,
        after: after,
      );
    }
    return BaselineMonitoringEvaluation(
      result: LearningRunResult.noChange,
      reasonCodes: const ['minimumUsefulImprovementNotMet'],
      before: before,
      after: after,
    );
  }

  List<_MonitoringObservation>? _decode(
    ShadowEvidencePackage evidence,
    BaselineMonitoringConfig config,
  ) {
    try {
      final snapshot = jsonDecode(evidence.evidenceSnapshotJson);
      if (snapshot is! Map<String, Object?> ||
          canonicalEncoder.encode(snapshot) != evidence.evidenceSnapshotJson) {
        return null;
      }
      final hashInput = snapshot['hashInput'];
      if (hashInput is! Map<String, Object?> ||
          hashInput['algorithmVersion'] != config.algorithmVersion ||
          hashInput['configVersion'] != config.configVersion ||
          hashInput['evidenceHashVersion'] != canonicalEvidenceHashV1 ||
          hashInput['parameterFamily'] !=
              LearningParameterFamily.baseline.code ||
          hashInput['sourceModelIdentity'] != evidence.sourceModelIdentity ||
          hashInput['referenceType'] != evidence.referenceType.code) {
        return null;
      }
      final hash = sha256
          .convert(utf8.encode(canonicalEncoder.encode(hashInput)))
          .toString();
      if (hash != evidence.evidenceHash) return null;
      final selected = hashInput['selectedEligibleEvidence'];
      if (selected is! List<Object?>) return null;
      final result = <_MonitoringObservation>[];
      for (final raw in selected) {
        if (raw is! Map<String, Object?> ||
            raw['baseEnergyAtObservation'] != evidence.baseEnergy ||
            raw['modelRegimeKey'] != evidence.sourceModelIdentity ||
            raw['referenceType'] != evidence.referenceType.code ||
            raw['absoluteState'] is! String ||
            raw['estimateAtObservation'] is! int ||
            raw['initialEstimateAtObservation'] is! int) {
          return null;
        }
        final actual = AbsoluteEnergyState.values.firstWhere(
          (item) => item.code == raw['absoluteState'],
          orElse: () => throw const FormatException('state'),
        );
        result.add(
          _MonitoringObservation(
            actualState: actual,
            estimate: raw['estimateAtObservation']! as int,
            initialEstimate: raw['initialEstimateAtObservation']! as int,
          ),
        );
      }
      return result;
    } on Object {
      return null;
    }
  }

  BaselineMonitoringMetrics _metrics(
    List<ObservationComparisonResult> comparisons,
    BaselineReplayDirection expectedDirection,
  ) {
    var aligned = 0;
    var opposite = 0;
    var error = 0;
    final windowAligned = <int>[];
    final windowOpposite = <int>[];
    for (var start = 0; start < comparisons.length; start += 7) {
      var windowAlignedCount = 0;
      var windowOppositeCount = 0;
      for (final comparison in comparisons.skip(start).take(7)) {
        if (comparison.direction == ObservationAlignmentDirection.aligned) {
          aligned++;
          windowAlignedCount++;
        }
        final isOpposite = expectedDirection == BaselineReplayDirection.decrease
            ? comparison.direction == ObservationAlignmentDirection.higher
            : comparison.direction == ObservationAlignmentDirection.lower;
        if (isOpposite) {
          opposite++;
          windowOppositeCount++;
        }
        error += comparison.alignmentDelta!.abs();
      }
      windowAligned.add(windowAlignedCount);
      windowOpposite.add(windowOppositeCount);
    }
    return BaselineMonitoringMetrics(
      aligned: aligned,
      opposite: opposite,
      totalAbsoluteOrdinalError: error,
      windowAligned: windowAligned,
      windowOpposite: windowOpposite,
    );
  }
}

final class _MonitoringObservation {
  const _MonitoringObservation({
    required this.actualState,
    required this.estimate,
    required this.initialEstimate,
  });

  final AbsoluteEnergyState actualState;
  final int estimate;
  final int initialEstimate;
}
