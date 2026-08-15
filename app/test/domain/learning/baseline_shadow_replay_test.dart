import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/energy/observation_comparison_service.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/baseline_shadow_replay.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

import '../../support/b1_preproduction_config.dart';

void main() {
  const replay = BaselineShadowReplayEngine();

  test('review replay produces a down-only watermarked candidate', () {
    final evidence = _evidence(_stableLowerEvidence(samePerWindow: 5));

    final result = replay.replay(
      evidence: evidence,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.review,
      config: b1PreproductionBaselineConfig(),
    );

    expect(result.outcome, BaselineReplayOutcome.candidate);
    expect(result.direction, BaselineReplayDirection.decrease);
    expect(result.candidateBaseEnergy, 98);
    expect(result.before?.lower, 10);
    expect(result.before?.aligned, 4);
    expect(result.before?.totalAbsoluteOrdinalError, 10);
    expect(result.after?.lower, 0);
    expect(result.after?.aligned, 14);
    expect(result.after?.totalAbsoluteOrdinalError, 0);
    expect(
      result.candidateValuesJson,
      '{"activationAllowed":false,"baseEnergy":98,'
      '"watermark":"$preproductionOnlyWatermark"}',
    );
    expect(result.reasons, [BaselineReplayReason.shadowCandidateOnly]);
  });

  test('automatic replay uses the stricter 6-of-7 zero-opposite gate', () {
    final reviewOnly = _evidence(_stableLowerEvidence(samePerWindow: 5));
    final strict = _evidence(_stableLowerEvidence(samePerWindow: 6));
    final config = b1PreproductionBaselineConfig();

    expect(
      replay
          .replay(
            evidence: reviewOnly,
            baselineAnchorEnergy: 100,
            mode: BaselineReplayMode.automatic,
            config: config,
          )
          .outcome,
      BaselineReplayOutcome.unstable,
    );
    final accepted = replay.replay(
      evidence: strict,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.automatic,
      config: config,
    );
    expect(accepted.outcome, BaselineReplayOutcome.candidate);
    expect(accepted.candidateBaseEnergy, 98);
  });

  test('stable higher evidence can only increase the baseline', () {
    final evidence = _evidence(_stableHigherEvidence(samePerWindow: 6));

    final result = replay.replay(
      evidence: evidence,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.automatic,
      config: b1PreproductionBaselineConfig(),
    );

    expect(result.outcome, BaselineReplayOutcome.candidate);
    expect(result.direction, BaselineReplayDirection.increase);
    expect(result.candidateBaseEnergy, 102);
    expect(result.before?.higher, 12);
    expect(result.after?.aligned, 14);
  });

  test('stable alignment is noChange and opposing windows are unstable', () {
    final aligned = _evidence([
      for (var index = 0; index < 14; index++)
        _observation(
          index,
          actualState: AbsoluteEnergyState.good,
          initialEstimate: 100,
          estimate: 60,
        ),
    ]);
    final opposing = _evidence([
      ..._stableLowerEvidence(samePerWindow: 7).take(7),
      ..._stableHigherEvidence(samePerWindow: 7).skip(7),
    ]);
    final config = b1PreproductionBaselineConfig();

    final noChange = replay.replay(
      evidence: aligned,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.review,
      config: config,
    );
    final unstable = replay.replay(
      evidence: opposing,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.review,
      config: config,
    );

    expect(noChange.outcome, BaselineReplayOutcome.noChange);
    expect(noChange.reasons, [BaselineReplayReason.stableAlignment]);
    expect(unstable.outcome, BaselineReplayOutcome.unstable);
    expect(unstable.reasons, [BaselineReplayReason.directionUnstable]);
  });

  test('count and span readiness remain mandatory', () {
    final observations = _stableLowerEvidence(samePerWindow: 7).take(13);
    final evidence = _evidence(observations.toList());

    final result = replay.replay(
      evidence: evidence,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.review,
      config: b1PreproductionBaselineConfig(),
    );

    expect(result.outcome, BaselineReplayOutcome.insufficientEvidence);
    expect(result.reasons, [BaselineReplayReason.evidenceNotReady]);
    expect(result.candidateValuesJson, isNull);
  });

  test('step 1 is inert while step 5 overreacts on the frozen fixture', () {
    final evidence = _evidence(_stableLowerEvidence(samePerWindow: 5));

    final tooSmall = replay.replay(
      evidence: evidence,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.review,
      config: b1PreproductionBaselineConfig(step: 1),
    );
    final tooLarge = replay.replay(
      evidence: evidence,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.review,
      config: b1PreproductionBaselineConfig(step: 5),
    );

    expect(tooSmall.outcome, BaselineReplayOutcome.noChange);
    expect(
      tooSmall.reasons,
      contains(BaselineReplayReason.minimumUsefulImprovementNotMet),
    );
    expect(tooLarge.outcome, BaselineReplayOutcome.noChange);
    expect(tooLarge.after?.opposite, 4);
    expect(
      tooLarge.reasons,
      contains(BaselineReplayReason.counterfactualOppositeCountIncreased),
    );
    expect(tooSmall.candidateValuesJson, isNull);
    expect(tooLarge.candidateValuesJson, isNull);
  });

  test('hard range and anchor cumulative boundaries never clamp a step', () {
    final atHardMinimum = _evidence(
      _stableLowerEvidence(samePerWindow: 6, baseEnergy: 60),
    );
    final beyondAnchor = _evidence(
      _stableLowerEvidence(samePerWindow: 6, baseEnergy: 93),
    );
    final config = b1PreproductionBaselineConfig();

    final hardResult = replay.replay(
      evidence: atHardMinimum,
      baselineAnchorEnergy: 60,
      mode: BaselineReplayMode.automatic,
      config: config,
    );
    final anchorResult = replay.replay(
      evidence: beyondAnchor,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.automatic,
      config: config,
    );

    expect(hardResult.outcome, BaselineReplayOutcome.noChange);
    expect(hardResult.reasons, [BaselineReplayReason.hardRangeBoundary]);
    expect(anchorResult.outcome, BaselineReplayOutcome.noChange);
    expect(anchorResult.reasons, [BaselineReplayReason.anchorBoundary]);
  });

  test('unsupported source, watermark, and activatable config fail closed', () {
    final yesterday = _evidence(
      _stableLowerEvidence(
        samePerWindow: 6,
        referenceType: ObservationReferenceType.previousLifeDayEnd,
      ),
    );
    final currentOnly = b1PreproductionBaselineConfig(
      referencePriority: const [ObservationReferenceType.currentMoment],
    );
    final activatable = b1PreproductionBaselineConfig(activationAllowed: true);
    final wrongWatermark = b1PreproductionBaselineConfig(
      watermark: 'not-a-preproduction-watermark',
    );

    final unsupported = replay.replay(
      evidence: yesterday,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.automatic,
      config: currentOnly,
    );
    final blocked = replay.replay(
      evidence: yesterday,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.automatic,
      config: activatable,
    );
    final watermarkBlocked = replay.replay(
      evidence: yesterday,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.automatic,
      config: wrongWatermark,
    );

    expect(unsupported.outcome, BaselineReplayOutcome.configurationBlocked);
    expect(unsupported.reasons, [
      BaselineReplayReason.unsupportedReferenceType,
    ]);
    expect(blocked.outcome, BaselineReplayOutcome.configurationBlocked);
    expect(blocked.reasons, [
      BaselineReplayReason.invalidShadowOnlyConfiguration,
    ]);
    expect(
      watermarkBlocked.outcome,
      BaselineReplayOutcome.configurationBlocked,
    );
    expect(watermarkBlocked.reasons, [
      BaselineReplayReason.invalidShadowOnlyConfiguration,
    ]);
  });

  test('malformed canonical evidence cannot become a candidate', () {
    final evidence = _evidence(_stableLowerEvidence(samePerWindow: 6));
    final malformed = _withSnapshot(evidence, '{"hashInput":{}}');

    final result = replay.replay(
      evidence: malformed,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.automatic,
      config: b1PreproductionBaselineConfig(),
    );

    expect(result.outcome, BaselineReplayOutcome.configurationBlocked);
    expect(result.reasons, [BaselineReplayReason.malformedFrozenEvidence]);
    expect(result.candidateValuesJson, isNull);
  });

  test('snapshot content cannot change without the evidence hash', () {
    final evidence = _evidence(_stableLowerEvidence(samePerWindow: 6));
    final tampered = _withSnapshot(
      evidence,
      evidence.evidenceSnapshotJson.replaceFirst(
        '"estimateAtObservation":50',
        '"estimateAtObservation":51',
      ),
    );
    final unsupportedNumber = _withSnapshot(
      evidence,
      evidence.evidenceSnapshotJson.replaceFirst(
        '"estimateAtObservation":50',
        '"estimateAtObservation":50.5',
      ),
    );

    final result = replay.replay(
      evidence: tampered,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.automatic,
      config: b1PreproductionBaselineConfig(),
    );
    final unsupportedResult = replay.replay(
      evidence: unsupportedNumber,
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.automatic,
      config: b1PreproductionBaselineConfig(),
    );

    expect(result.outcome, BaselineReplayOutcome.configurationBlocked);
    expect(result.reasons, [BaselineReplayReason.malformedFrozenEvidence]);
    expect(
      unsupportedResult.outcome,
      BaselineReplayOutcome.configurationBlocked,
    );
    expect(unsupportedResult.reasons, [
      BaselineReplayReason.malformedFrozenEvidence,
    ]);
  });

  test('counterfactual invalid initial estimate fails closed', () {
    final evidence = _evidence([
      for (var index = 0; index < 14; index++)
        if (index % 7 < 5)
          _observation(
            index,
            actualState: AbsoluteEnergyState.exhausted,
            initialEstimate: 1,
            estimate: 0,
            baseEnergy: 62,
          )
        else
          _observation(
            index,
            actualState: AbsoluteEnergyState.exhausted,
            initialEstimate: 1,
            estimate: -1,
            baseEnergy: 62,
          ),
    ]);

    final result = replay.replay(
      evidence: evidence,
      baselineAnchorEnergy: 62,
      mode: BaselineReplayMode.review,
      config: b1PreproductionBaselineConfig(),
    );

    expect(result.outcome, BaselineReplayOutcome.configurationBlocked);
    expect(result.reasons, [
      BaselineReplayReason.counterfactualInvalidInitialEstimate,
    ]);
    expect(result.candidateValuesJson, isNull);
  });
}

List<EnergyObservation> _stableLowerEvidence({
  required int samePerWindow,
  int baseEnergy = 100,
  ObservationReferenceType referenceType =
      ObservationReferenceType.currentMoment,
}) {
  return [
    for (var index = 0; index < 14; index++)
      if (index % 7 < samePerWindow)
        _observation(
          index,
          actualState: AbsoluteEnergyState.okay,
          initialEstimate: 99,
          estimate: 50,
          baseEnergy: baseEnergy,
          referenceType: referenceType,
        )
      else
        _observation(
          index,
          actualState: AbsoluteEnergyState.good,
          initialEstimate: 100,
          estimate: 52,
          baseEnergy: baseEnergy,
          referenceType: referenceType,
        ),
  ];
}

List<EnergyObservation> _stableHigherEvidence({
  required int samePerWindow,
  int baseEnergy = 100,
  ObservationReferenceType referenceType =
      ObservationReferenceType.currentMoment,
}) {
  return [
    for (var index = 0; index < 14; index++)
      if (index % 7 < samePerWindow)
        _observation(
          index,
          actualState: AbsoluteEnergyState.full,
          initialEstimate: 98,
          estimate: 78,
          baseEnergy: baseEnergy,
          referenceType: referenceType,
        )
      else
        _observation(
          index,
          actualState: AbsoluteEnergyState.good,
          initialEstimate: 100,
          estimate: 79,
          baseEnergy: baseEnergy,
          referenceType: referenceType,
        ),
  ];
}

ShadowEvidencePackage _evidence(List<EnergyObservation> observations) {
  return const ShadowEvidenceBuilder()
      .buildAll(
        observations: observations,
        morningLifeDays: {for (final item in observations) item.lifeDay},
        settledLifeDays: {for (final item in observations) item.lifeDay},
        config: ShadowLearningConfig.evidenceReadinessV1(),
      )
      .single;
}

EnergyObservation _observation(
  int index, {
  required AbsoluteEnergyState actualState,
  required int initialEstimate,
  required int estimate,
  int baseEnergy = 100,
  ObservationReferenceType referenceType =
      ObservationReferenceType.currentMoment,
}) {
  final date = DateTime.utc(2026, 1, 1).add(Duration(days: index * 2));
  final lifeDay = LifeDay(date.year, date.month, date.day);
  final comparison = const ObservationComparisonService().compare(
    actualState: actualState,
    estimate: estimate,
    initialEstimate: initialEstimate,
  );
  final modelRegimeKey = const ModelRegimeKeyBuilder().build(
    referenceType: referenceType,
    baseEnergy: baseEnergy,
    ruleVersion: energyRulesV2MvpAVersion,
    comparisonBandVersion: mvpBComparisonBandV1,
    effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
    modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
  );
  return EnergyObservation(
    id: 'replay-${index.toString().padLeft(2, '0')}',
    lifeDay: lifeDay,
    type: EnergyObservationType.dailyAbsolute,
    absoluteState: actualState,
    relativeState: null,
    estimateAtObservation: estimate,
    observedAt: DateTime.utc(lifeDay.year, lifeDay.month, lifeDay.day, 12),
    contractVersion: mvpBObservationContractV1,
    referenceType: referenceType,
    initialEstimateAtObservation: initialEstimate,
    estimatedOrdinalAtObservation: comparison.estimatedOrdinal,
    baseEnergyAtObservation: baseEnergy,
    ruleVersionAtObservation: energyRulesV2MvpAVersion,
    comparisonBandVersion: mvpBComparisonBandV1,
    personalizationVersionAtObservation: fixedMvpAPersonalizationVersion,
    effectiveModelFingerprintAtObservation: fixedMvpAEffectiveModelFingerprint,
    modelRegimeEpochAtObservation: fixedMvpAInitialModelRegimeEpoch,
    activeActivityCountAtObservation: 1,
    coverageState: ObservationCoverageState.confirmed,
    modelRegimeKey: modelRegimeKey,
  );
}

ShadowEvidencePackage _withSnapshot(
  ShadowEvidencePackage source,
  String snapshot,
) {
  return ShadowEvidencePackage(
    sourceModelIdentity: source.sourceModelIdentity,
    referenceType: source.referenceType,
    baseEnergy: source.baseEnergy,
    evidenceSnapshotJson: snapshot,
    evidenceHash: source.evidenceHash,
    currentValuesJson: source.currentValuesJson,
    eligibleTotal: source.eligibleTotal,
    selectedEligible: source.selectedEligible,
    excludedTotal: source.excludedTotal,
    missingToMinimum: source.missingToMinimum,
    earliestLifeDay: source.earliestLifeDay,
    latestLifeDay: source.latestLifeDay,
    directionCounts: source.directionCounts,
    windowDirectionCounts: source.windowDirectionCounts,
    windowSizes: source.windowSizes,
    exclusionCounts: source.exclusionCounts,
    readiness: source.readiness,
  );
}
