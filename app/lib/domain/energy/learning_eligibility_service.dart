import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/energy/observation_comparison_service.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';

enum LearningIneligibilityReason {
  legacyContract('legacyContract'),
  missingEstimateSnapshot('missingEstimateSnapshot'),
  coverageUncertain('coverageUncertain'),
  missingMorningCheckIn('missingMorningCheckIn'),
  invalidInitialEstimate('invalidInitialEstimate'),
  unsettledLifeDay('unsettledLifeDay'),
  modelRegimeMismatch('modelRegimeMismatch'),
  integrityFailure('integrityFailure');

  const LearningIneligibilityReason(this.code);
  final String code;
}

final class LearningEligibility {
  const LearningEligibility({
    required this.eligible,
    required this.reasonCodes,
    required this.modelRegimeKey,
    required this.referenceType,
    required this.settled,
  });

  final bool eligible;
  final List<LearningIneligibilityReason> reasonCodes;
  final String? modelRegimeKey;
  final ObservationReferenceType? referenceType;
  final bool settled;
}

final class LearningEligibilityService {
  const LearningEligibilityService({
    this.comparisonService = const ObservationComparisonService(),
    this.regimeKeyBuilder = const ModelRegimeKeyBuilder(),
  });

  final ObservationComparisonService comparisonService;
  final ModelRegimeKeyBuilder regimeKeyBuilder;

  LearningEligibility evaluate({
    required EnergyObservation observation,
    required bool hasMorningCheckIn,
    required bool settled,
    String? expectedModelRegimeKey,
  }) {
    final found = <LearningIneligibilityReason>{};
    final dailyShape =
        observation.type == EnergyObservationType.dailyAbsolute &&
        observation.absoluteState != null &&
        observation.relativeState == null;
    if (!dailyShape) {
      found.add(LearningIneligibilityReason.integrityFailure);
    }

    final currentContract =
        observation.contractVersion == mvpBObservationContractV1;
    if (!currentContract) {
      found.add(LearningIneligibilityReason.legacyContract);
    } else {
      final snapshotComplete = _snapshotComplete(observation);
      if (!snapshotComplete) {
        found.add(LearningIneligibilityReason.missingEstimateSnapshot);
      }
      if (observation.coverageState == ObservationCoverageState.uncertain) {
        found.add(LearningIneligibilityReason.coverageUncertain);
      }
      if (!hasMorningCheckIn) {
        found.add(LearningIneligibilityReason.missingMorningCheckIn);
      }
      if (observation.initialEstimateAtObservation case final initial?
          when initial <= 0) {
        found.add(LearningIneligibilityReason.invalidInitialEstimate);
      }
      if (!settled) {
        found.add(LearningIneligibilityReason.unsettledLifeDay);
      }

      if (snapshotComplete) {
        _validateCompleteSnapshot(
          observation,
          expectedModelRegimeKey: expectedModelRegimeKey,
          reasons: found,
        );
      }
    }

    final ordered = <LearningIneligibilityReason>[
      for (final reason in LearningIneligibilityReason.values)
        if (found.contains(reason)) reason,
    ];
    return LearningEligibility(
      eligible: ordered.isEmpty,
      reasonCodes: List.unmodifiable(ordered),
      modelRegimeKey: observation.modelRegimeKey,
      referenceType: observation.referenceType,
      settled: settled,
    );
  }

  bool _snapshotComplete(EnergyObservation observation) {
    return observation.estimateAtObservation != null &&
        observation.referenceType != null &&
        observation.initialEstimateAtObservation != null &&
        observation.estimatedOrdinalAtObservation != null &&
        observation.baseEnergyAtObservation != null &&
        _notEmpty(observation.ruleVersionAtObservation) &&
        _notEmpty(observation.comparisonBandVersion) &&
        _notEmpty(observation.personalizationVersionAtObservation) &&
        _notEmpty(observation.effectiveModelFingerprintAtObservation) &&
        _notEmpty(observation.modelRegimeEpochAtObservation) &&
        observation.activeActivityCountAtObservation != null &&
        observation.coverageState != null &&
        _notEmpty(observation.modelRegimeKey);
  }

  void _validateCompleteSnapshot(
    EnergyObservation observation, {
    required String? expectedModelRegimeKey,
    required Set<LearningIneligibilityReason> reasons,
  }) {
    final initial = observation.initialEstimateAtObservation!;
    final actual = observation.absoluteState;
    final comparison = actual == null
        ? null
        : comparisonService.compare(
            actualState: actual,
            estimate: observation.estimateAtObservation!,
            initialEstimate: initial,
          );
    if (comparison?.failure ==
        ObservationComparisonFailure.invalidInitialEstimate) {
      reasons.add(LearningIneligibilityReason.invalidInitialEstimate);
    }
    final integrityFailure =
        actual == null ||
        observation.comparisonBandVersion != mvpBComparisonBandV1 ||
        !_validPersonalizationVersion(
          observation.personalizationVersionAtObservation!,
        ) ||
        observation.coverageState == ObservationCoverageState.legacyUnknown ||
        observation.activeActivityCountAtObservation! < 0 ||
        observation.baseEnergyAtObservation! < 60 ||
        observation.baseEnergyAtObservation! > 140 ||
        (comparison?.isValid == true &&
            comparison!.estimatedOrdinal !=
                observation.estimatedOrdinalAtObservation);
    if (integrityFailure) {
      reasons.add(LearningIneligibilityReason.integrityFailure);
    }

    final rebuiltKey = regimeKeyBuilder.build(
      referenceType: observation.referenceType!,
      baseEnergy: observation.baseEnergyAtObservation!,
      ruleVersion: observation.ruleVersionAtObservation!,
      comparisonBandVersion: observation.comparisonBandVersion!,
      effectiveModelFingerprint:
          observation.effectiveModelFingerprintAtObservation!,
      modelRegimeEpoch: observation.modelRegimeEpochAtObservation!,
    );
    if (rebuiltKey != observation.modelRegimeKey ||
        (expectedModelRegimeKey != null &&
            rebuiltKey != expectedModelRegimeKey)) {
      reasons.add(LearningIneligibilityReason.modelRegimeMismatch);
    }
  }

  bool _notEmpty(String? value) => value != null && value.trim().isNotEmpty;

  bool _validPersonalizationVersion(String value) {
    if (value == fixedMvpAPersonalizationVersion) return true;
    final prefix = '$deterministicPersonalizationVersionIdV1:';
    if (!value.startsWith(prefix)) return false;
    final digest = value.substring(prefix.length);
    return digest.length == 64 && RegExp(r'^[0-9a-f]+$').hasMatch(digest);
  }
}
