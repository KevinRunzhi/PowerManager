import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/energy/learning_eligibility_service.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

void main() {
  const service = LearningEligibilityService();

  test('confirmed settled complete observation is eligible', () {
    final observation = _observation();
    final result = service.evaluate(
      observation: observation,
      hasMorningCheckIn: true,
      settled: true,
      expectedModelRegimeKey: observation.modelRegimeKey,
    );

    expect(result.eligible, isTrue);
    expect(result.reasonCodes, isEmpty);
    expect(result.referenceType, ObservationReferenceType.currentMoment);
    expect(result.settled, isTrue);
  });

  test('zero activities can be explicitly confirmed without exclusion', () {
    final observation = _observation(activeActivityCount: 0);
    final result = service.evaluate(
      observation: observation,
      hasMorningCheckIn: true,
      settled: true,
    );

    expect(result.eligible, isTrue);
  });

  test('legacy contract is excluded without inventing snapshot reasons', () {
    final result = service.evaluate(
      observation: EnergyObservation(
        id: 'legacy',
        lifeDay: LifeDay(2026, 7, 26),
        type: EnergyObservationType.dailyAbsolute,
        absoluteState: AbsoluteEnergyState.okay,
        relativeState: null,
        estimateAtObservation: null,
        observedAt: DateTime.utc(2026, 7, 26, 12),
      ),
      hasMorningCheckIn: false,
      settled: false,
    );

    expect(result.eligible, isFalse);
    expect(result.reasonCodes, [LearningIneligibilityReason.legacyContract]);
  });

  test('reports every individual ineligibility reason code', () {
    final cases = <LearningIneligibilityReason, LearningEligibility Function()>{
      LearningIneligibilityReason.missingEstimateSnapshot: () =>
          service.evaluate(
            observation: _observation(estimate: null),
            hasMorningCheckIn: true,
            settled: true,
          ),
      LearningIneligibilityReason.coverageUncertain: () => service.evaluate(
        observation: _observation(
          coverageState: ObservationCoverageState.uncertain,
        ),
        hasMorningCheckIn: true,
        settled: true,
      ),
      LearningIneligibilityReason.missingMorningCheckIn: () => service.evaluate(
        observation: _observation(),
        hasMorningCheckIn: false,
        settled: true,
      ),
      LearningIneligibilityReason.invalidInitialEstimate: () =>
          service.evaluate(
            observation: _observation(initialEstimate: 0),
            hasMorningCheckIn: true,
            settled: true,
          ),
      LearningIneligibilityReason.unsettledLifeDay: () => service.evaluate(
        observation: _observation(),
        hasMorningCheckIn: true,
        settled: false,
      ),
      LearningIneligibilityReason.modelRegimeMismatch: () => service.evaluate(
        observation: _observation(modelRegimeKey: 'wrong'),
        hasMorningCheckIn: true,
        settled: true,
      ),
      LearningIneligibilityReason.integrityFailure: () => service.evaluate(
        observation: _observation(estimatedOrdinal: 2),
        hasMorningCheckIn: true,
        settled: true,
      ),
      LearningIneligibilityReason.legacyContract: () => service.evaluate(
        observation: _observation(contractVersion: null),
        hasMorningCheckIn: true,
        settled: true,
      ),
    };

    for (final entry in cases.entries) {
      expect(
        entry.value().reasonCodes,
        contains(entry.key),
        reason: entry.key.code,
      );
    }
  });

  test('multiple reasons are de-duplicated in the specified stable order', () {
    final result = service.evaluate(
      observation: _observation(
        initialEstimate: 0,
        comparisonBandVersion: 'unsupported-band',
        coverageState: ObservationCoverageState.uncertain,
      ),
      hasMorningCheckIn: false,
      settled: false,
    );

    expect(result.reasonCodes, [
      LearningIneligibilityReason.coverageUncertain,
      LearningIneligibilityReason.missingMorningCheckIn,
      LearningIneligibilityReason.invalidInitialEstimate,
      LearningIneligibilityReason.unsettledLifeDay,
      LearningIneligibilityReason.integrityFailure,
    ]);
  });

  test('stored and expected regime keys are both verified', () {
    final previous = _observation(
      referenceType: ObservationReferenceType.previousLifeDayEnd,
    );
    final currentKey = _regimeKey(ObservationReferenceType.currentMoment);
    final result = service.evaluate(
      observation: previous,
      hasMorningCheckIn: true,
      settled: true,
      expectedModelRegimeKey: currentKey,
    );

    expect(previous.modelRegimeKey, isNot(currentKey));
    expect(result.reasonCodes, [
      LearningIneligibilityReason.modelRegimeMismatch,
    ]);
  });
}

EnergyObservation _observation({
  String? contractVersion = mvpBObservationContractV1,
  ObservationReferenceType? referenceType =
      ObservationReferenceType.currentMoment,
  int? estimate = 50,
  int? initialEstimate = 100,
  int? estimatedOrdinal = 3,
  int? baseEnergy = 100,
  String? ruleVersion = energyRulesV2MvpAVersion,
  String? comparisonBandVersion = mvpBComparisonBandV1,
  String? personalizationVersion = fixedMvpAPersonalizationVersion,
  String? fingerprint = fixedMvpAEffectiveModelFingerprint,
  String? epoch = fixedMvpAInitialModelRegimeEpoch,
  int? activeActivityCount = 1,
  ObservationCoverageState? coverageState = ObservationCoverageState.confirmed,
  String? modelRegimeKey,
}) {
  final resolvedKey =
      modelRegimeKey ??
      (referenceType == null ||
              baseEnergy == null ||
              ruleVersion == null ||
              comparisonBandVersion == null ||
              fingerprint == null ||
              epoch == null
          ? null
          : const ModelRegimeKeyBuilder().build(
              referenceType: referenceType,
              baseEnergy: baseEnergy,
              ruleVersion: ruleVersion,
              comparisonBandVersion: comparisonBandVersion,
              effectiveModelFingerprint: fingerprint,
              modelRegimeEpoch: epoch,
            ));
  return EnergyObservation(
    id: 'observation',
    lifeDay: LifeDay(2026, 7, 26),
    type: EnergyObservationType.dailyAbsolute,
    absoluteState: AbsoluteEnergyState.okay,
    relativeState: null,
    estimateAtObservation: estimate,
    observedAt: DateTime.utc(2026, 7, 26, 12),
    contractVersion: contractVersion,
    referenceType: referenceType,
    initialEstimateAtObservation: initialEstimate,
    estimatedOrdinalAtObservation: estimatedOrdinal,
    baseEnergyAtObservation: baseEnergy,
    ruleVersionAtObservation: ruleVersion,
    comparisonBandVersion: comparisonBandVersion,
    personalizationVersionAtObservation: personalizationVersion,
    effectiveModelFingerprintAtObservation: fingerprint,
    modelRegimeEpochAtObservation: epoch,
    activeActivityCountAtObservation: activeActivityCount,
    coverageState: coverageState,
    modelRegimeKey: resolvedKey,
  );
}

String _regimeKey(ObservationReferenceType referenceType) {
  return const ModelRegimeKeyBuilder().build(
    referenceType: referenceType,
    baseEnergy: 100,
    ruleVersion: energyRulesV2MvpAVersion,
    comparisonBandVersion: mvpBComparisonBandV1,
    effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
    modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
  );
}
