import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/learning/baseline_shadow_replay.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';

/// The B2-1 production identity is deliberately separate from the B1 shadow
/// identity.  The implementation is still evaluated with the watermarked
/// replay contract until a release explicitly replaces this configuration.
const baselineProductionAlgorithmV1 = 'baseline-production-v1';
const baselineProductionConfigV1 = 'baseline-production-config-v1';

final class BaselineProductionConfig {
  BaselineProductionConfig({
    this.algorithmVersion = baselineProductionAlgorithmV1,
    this.configVersion = baselineProductionConfigV1,
    this.watermark = preproductionOnlyWatermark,
    this.activationAllowed = false,
    List<ObservationReferenceType> referencePriority = const [
      ObservationReferenceType.currentMoment,
      ObservationReferenceType.previousLifeDayEnd,
    ],
    this.reviewThresholds = const BaselineDirectionThresholds(
      minimumSameDirectionPerWindow: 5,
      minimumSameDirectionTotal: 10,
      maximumOppositePerWindow: 1,
    ),
    this.automaticThresholds = const BaselineDirectionThresholds(
      minimumSameDirectionPerWindow: 6,
      minimumSameDirectionTotal: 12,
      maximumOppositePerWindow: 0,
    ),
    this.step = 2,
    this.anchorCumulativeLimit = 8,
    this.hardMinimum = 60,
    this.hardMaximum = 140,
    this.minimumCounterfactualAlignedGain = 1,
    this.minimumCounterfactualOrdinalErrorReduction = 1,
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

  bool get isValid => BaselineShadowReplayConfig(
    algorithmVersion: algorithmVersion,
    configVersion: configVersion,
    watermark: watermark,
    activationAllowed: activationAllowed,
    referencePriority: referencePriority,
    reviewThresholds: reviewThresholds,
    automaticThresholds: automaticThresholds,
    step: step,
    anchorCumulativeLimit: anchorCumulativeLimit,
    hardMinimum: hardMinimum,
    hardMaximum: hardMaximum,
    minimumCounterfactualAlignedGain: minimumCounterfactualAlignedGain,
    minimumCounterfactualOrdinalErrorReduction:
        minimumCounterfactualOrdinalErrorReduction,
  ).isValidShadowOnly;

  BaselineShadowReplayConfig toReplayConfig() => BaselineShadowReplayConfig(
    algorithmVersion: algorithmVersion,
    configVersion: configVersion,
    watermark: watermark,
    activationAllowed: activationAllowed,
    referencePriority: referencePriority,
    reviewThresholds: reviewThresholds,
    automaticThresholds: automaticThresholds,
    step: step,
    anchorCumulativeLimit: anchorCumulativeLimit,
    hardMinimum: hardMinimum,
    hardMaximum: hardMaximum,
    minimumCounterfactualAlignedGain: minimumCounterfactualAlignedGain,
    minimumCounterfactualOrdinalErrorReduction:
        minimumCounterfactualOrdinalErrorReduction,
  );
}

final class BaselineProductionEvaluation {
  BaselineProductionEvaluation({
    required this.result,
    required List<String> reasonCodes,
    required this.evidence,
    this.direction,
    this.candidateBaseEnergy,
    this.candidateValuesJson,
  }) : reasonCodes = List.unmodifiable(reasonCodes);

  final LearningRunResult result;
  final List<String> reasonCodes;
  final ShadowEvidencePackage evidence;
  final BaselineReplayDirection? direction;
  final int? candidateBaseEnergy;
  final String? candidateValuesJson;
}

/// Pure B2 learner. It performs no persistence, reads no settings and cannot
/// activate a model. Gate failures are represented as a durable result by the
/// coordinator rather than silently becoming a shadow-only success.
final class BaselineProductionLearner {
  const BaselineProductionLearner({
    this.replayEngine = const BaselineShadowReplayEngine(),
    this.canonicalEncoder = const CanonicalJsonEncoder(),
  });

  final BaselineShadowReplayEngine replayEngine;
  final CanonicalJsonEncoder canonicalEncoder;

  BaselineProductionEvaluation evaluate({
    required ShadowEvidencePackage shadowEvidence,
    required int baselineAnchorEnergy,
    required BaselineReplayMode mode,
    required BaselineProductionConfig config,
  }) {
    final evidence = shadowEvidence.reidentify(
      algorithmVersion: config.algorithmVersion,
      configVersion: config.configVersion,
    );
    if (!config.isValid) {
      return BaselineProductionEvaluation(
        result: LearningRunResult.configurationBlocked,
        reasonCodes: const ['invalidProductionConfiguration'],
        evidence: evidence,
      );
    }
    final replay = replayEngine.replay(
      evidence: evidence,
      baselineAnchorEnergy: baselineAnchorEnergy,
      mode: mode,
      config: config.toReplayConfig(),
    );
    final candidateValues = replay.candidateBaseEnergy == null
        ? null
        : canonicalEncoder.encode({'baseEnergy': replay.candidateBaseEnergy});
    return BaselineProductionEvaluation(
      result: switch (replay.outcome) {
        BaselineReplayOutcome.insufficientEvidence =>
          LearningRunResult.insufficientEvidence,
        BaselineReplayOutcome.unstable => LearningRunResult.unstable,
        BaselineReplayOutcome.noChange => LearningRunResult.noChange,
        BaselineReplayOutcome.candidate => LearningRunResult.candidate,
        BaselineReplayOutcome.configurationBlocked =>
          LearningRunResult.configurationBlocked,
      },
      reasonCodes: [for (final reason in replay.reasons) reason.code],
      evidence: evidence,
      direction: replay.direction,
      candidateBaseEnergy: replay.candidateBaseEnergy,
      candidateValuesJson: candidateValues,
    );
  }
}
