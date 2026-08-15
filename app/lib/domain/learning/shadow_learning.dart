import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/learning_eligibility_service.dart';
import 'package:power_manager/domain/energy/observation_comparison_service.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

enum ShadowLearningReason {
  automaticLearningEngineDisabled('automaticLearningEngineDisabled'),
  minimumEligibleObservationPairsNotMet(
    'minimumEligibleObservationPairsNotMet',
  ),
  minimumObservationSpanNotMet('minimumObservationSpanNotMet'),
  shadowWindowsIncomplete('shadowWindowsIncomplete'),
  readyForAudit('readyForAudit');

  const ShadowLearningReason(this.code);
  final String code;
}

final class ShadowLearningConfig {
  ShadowLearningConfig({
    required this.engineEnabled,
    this.algorithmVersion = shadowLearningAlgorithmV1,
    this.configVersion = shadowLearningConfigV1,
    this.evidenceHashVersion = canonicalEvidenceHashV1,
    this.minimumEligibleObservationPairs = 14,
    this.minimumObservationSpanCalendarDays = 21,
    this.windowCount = 2,
    this.windowEligiblePairs = 7,
  }) {
    if (algorithmVersion != shadowLearningAlgorithmV1 ||
        configVersion != shadowLearningConfigV1 ||
        evidenceHashVersion != canonicalEvidenceHashV1) {
      throw ArgumentError('Unsupported shadow learning version');
    }
    if (minimumEligibleObservationPairs <= 0 ||
        minimumObservationSpanCalendarDays < 0 ||
        windowCount <= 0 ||
        windowEligiblePairs <= 0 ||
        windowCount * windowEligiblePairs != minimumEligibleObservationPairs) {
      throw ArgumentError('Invalid shadow readiness thresholds');
    }
  }

  factory ShadowLearningConfig.evidenceReadinessV1({
    bool engineEnabled = true,
  }) => ShadowLearningConfig(engineEnabled: engineEnabled);

  final bool engineEnabled;
  final String algorithmVersion;
  final String configVersion;
  final String evidenceHashVersion;
  final int minimumEligibleObservationPairs;
  final int minimumObservationSpanCalendarDays;
  final int windowCount;
  final int windowEligiblePairs;
}

final class DirectionCounts {
  const DirectionCounts({
    required this.lower,
    required this.aligned,
    required this.higher,
  });

  const DirectionCounts.empty() : lower = 0, aligned = 0, higher = 0;

  final int lower;
  final int aligned;
  final int higher;

  Map<String, Object?> toJson() => {
    'aligned': aligned,
    'higher': higher,
    'lower': lower,
  };
}

final class ShadowReadiness {
  const ShadowReadiness({
    required this.hasMinimumCount,
    required this.hasMinimumSpan,
    required this.hasCompleteWindows,
    required this.spanCalendarDays,
  });

  final bool hasMinimumCount;
  final bool hasMinimumSpan;
  final bool hasCompleteWindows;
  final int spanCalendarDays;

  bool get ready => hasMinimumCount && hasMinimumSpan && hasCompleteWindows;

  Map<String, Object?> toJson() => {
    'hasCompleteWindows': hasCompleteWindows,
    'hasMinimumCount': hasMinimumCount,
    'hasMinimumSpan': hasMinimumSpan,
    'spanCalendarDays': spanCalendarDays,
  };
}

final class ShadowEvidencePackage {
  ShadowEvidencePackage({
    required this.sourceModelIdentity,
    required this.referenceType,
    required this.baseEnergy,
    required this.evidenceSnapshotJson,
    required this.evidenceHash,
    required this.currentValuesJson,
    required this.eligibleTotal,
    required this.selectedEligible,
    required this.excludedTotal,
    required this.missingToMinimum,
    required this.earliestLifeDay,
    required this.latestLifeDay,
    required this.directionCounts,
    required List<DirectionCounts> windowDirectionCounts,
    required List<int> windowSizes,
    required Map<LearningIneligibilityReason, int> exclusionCounts,
    required this.readiness,
  }) : windowDirectionCounts = List.unmodifiable(windowDirectionCounts),
       windowSizes = List.unmodifiable(windowSizes),
       exclusionCounts = Map.unmodifiable(exclusionCounts);

  final String sourceModelIdentity;
  final ObservationReferenceType referenceType;
  final int baseEnergy;
  final String evidenceSnapshotJson;
  final String evidenceHash;
  final String currentValuesJson;
  final int eligibleTotal;
  final int selectedEligible;
  final int excludedTotal;
  final int missingToMinimum;
  final LifeDay? earliestLifeDay;
  final LifeDay? latestLifeDay;
  final DirectionCounts directionCounts;
  final List<DirectionCounts> windowDirectionCounts;
  final List<int> windowSizes;
  final Map<LearningIneligibilityReason, int> exclusionCounts;
  final ShadowReadiness readiness;
}

final class ShadowLearningEvaluation {
  ShadowLearningEvaluation({
    required this.result,
    required List<ShadowLearningReason> reasonCodes,
  }) : reasonCodes = List.unmodifiable(reasonCodes);

  final LearningRunResult result;
  final List<ShadowLearningReason> reasonCodes;
}

abstract interface class ShadowLearningEvaluator {
  ShadowLearningEvaluation evaluate({
    required ShadowEvidencePackage evidence,
    required ShadowLearningConfig config,
  });
}

final class BaselineShadowLearner implements ShadowLearningEvaluator {
  const BaselineShadowLearner();

  @override
  ShadowLearningEvaluation evaluate({
    required ShadowEvidencePackage evidence,
    required ShadowLearningConfig config,
  }) {
    if (!config.engineEnabled) {
      return ShadowLearningEvaluation(
        result: LearningRunResult.configurationBlocked,
        reasonCodes: const [
          ShadowLearningReason.automaticLearningEngineDisabled,
        ],
      );
    }
    final reasons = <ShadowLearningReason>[
      if (!evidence.readiness.hasMinimumCount)
        ShadowLearningReason.minimumEligibleObservationPairsNotMet,
      if (!evidence.readiness.hasMinimumSpan)
        ShadowLearningReason.minimumObservationSpanNotMet,
      if (!evidence.readiness.hasCompleteWindows)
        ShadowLearningReason.shadowWindowsIncomplete,
    ];
    if (reasons.isNotEmpty) {
      return ShadowLearningEvaluation(
        result: LearningRunResult.insufficientEvidence,
        reasonCodes: reasons,
      );
    }
    return ShadowLearningEvaluation(
      result: LearningRunResult.readyForAudit,
      reasonCodes: const [ShadowLearningReason.readyForAudit],
    );
  }
}

final class ShadowEvidenceBuilder {
  const ShadowEvidenceBuilder({
    this.eligibilityService = const LearningEligibilityService(),
    this.comparisonService = const ObservationComparisonService(),
    this.canonicalEncoder = const CanonicalJsonEncoder(),
  });

  final LearningEligibilityService eligibilityService;
  final ObservationComparisonService comparisonService;
  final CanonicalJsonEncoder canonicalEncoder;

  List<ShadowEvidencePackage> buildAll({
    required List<EnergyObservation> observations,
    required Set<LifeDay> morningLifeDays,
    required Set<LifeDay> settledLifeDays,
    required ShadowLearningConfig config,
  }) {
    final groups = <String, List<EnergyObservation>>{};
    for (final observation in observations) {
      final key = observation.modelRegimeKey;
      if (observation.type != EnergyObservationType.dailyAbsolute ||
          observation.contractVersion != mvpBObservationContractV1 ||
          key == null ||
          key.trim().isEmpty ||
          !settledLifeDays.contains(observation.lifeDay)) {
        continue;
      }
      groups.putIfAbsent(key, () => []).add(observation);
    }

    final keys = groups.keys.toList()..sort();
    final packages = <ShadowEvidencePackage>[];
    for (final key in keys) {
      final package = _buildGroup(
        sourceModelIdentity: key,
        observations: groups[key]!,
        morningLifeDays: morningLifeDays,
        config: config,
      );
      if (package != null) packages.add(package);
    }
    return packages;
  }

  ShadowEvidencePackage? _buildGroup({
    required String sourceModelIdentity,
    required List<EnergyObservation> observations,
    required Set<LifeDay> morningLifeDays,
    required ShadowLearningConfig config,
  }) {
    final sorted = List<EnergyObservation>.of(observations)
      ..sort(_compareObservations);
    final evaluated = <_EvaluatedObservation>[];
    for (final observation in sorted) {
      evaluated.add(
        _EvaluatedObservation(
          observation: observation,
          eligibility: eligibilityService.evaluate(
            observation: observation,
            hasMorningCheckIn: morningLifeDays.contains(observation.lifeDay),
            settled: true,
            expectedModelRegimeKey: sourceModelIdentity,
          ),
        ),
      );
    }
    final eligible = evaluated
        .where((item) => item.eligibility.eligible)
        .toList();
    final source = eligible.firstOrNull ?? evaluated.firstOrNull;
    final referenceType = source?.observation.referenceType;
    final baseEnergy = source?.observation.baseEnergyAtObservation;
    if (referenceType == null || baseEnergy == null) return null;

    final selected = eligible.length <= config.minimumEligibleObservationPairs
        ? eligible
        : eligible.sublist(
            eligible.length - config.minimumEligibleObservationPairs,
          );
    final excluded = evaluated
        .where((item) => !item.eligibility.eligible)
        .toList();
    final selectedEvidence = [
      for (final item in selected) _eligibleEvidenceJson(item.observation),
    ];
    final excludedEvidence = [
      for (final item in excluded)
        <String, Object?>{
          'id': item.observation.id,
          'lifeDay': item.observation.lifeDay.toString(),
          'observedAt': canonicalUtcIso8601Micros(item.observation.observedAt),
          'reasonCodes': [
            for (final reason in item.eligibility.reasonCodes) reason.code,
          ],
        },
    ];
    final thresholds = <String, Object?>{
      'minimumEligibleObservationPairs': config.minimumEligibleObservationPairs,
      'minimumObservationSpanCalendarDays':
          config.minimumObservationSpanCalendarDays,
      'shadowWindowCount': config.windowCount,
      'shadowWindowEligiblePairs': config.windowEligiblePairs,
    };
    final hashInput = <String, Object?>{
      'algorithmVersion': config.algorithmVersion,
      'configVersion': config.configVersion,
      'evidenceHashVersion': config.evidenceHashVersion,
      'parameterFamily': LearningParameterFamily.baseline.code,
      'readinessThresholds': thresholds,
      'referenceType': referenceType.code,
      'scopedExcludedEvidence': excludedEvidence,
      'selectedEligibleEvidence': selectedEvidence,
      'sourceModelIdentity': sourceModelIdentity,
    };
    final canonicalHashInput = canonicalEncoder.encode(hashInput);
    final evidenceHash = sha256
        .convert(utf8.encode(canonicalHashInput))
        .toString();
    final directions = [
      for (final item in selected) _direction(item.observation),
    ];
    final windowItems = _windows(directions, config);
    final earliestLifeDay = selected.firstOrNull?.observation.lifeDay;
    final latestLifeDay = selected.lastOrNull?.observation.lifeDay;
    final span = earliestLifeDay == null || latestLifeDay == null
        ? 0
        : DateTime.utc(
                latestLifeDay.year,
                latestLifeDay.month,
                latestLifeDay.day,
              )
              .difference(
                DateTime.utc(
                  earliestLifeDay.year,
                  earliestLifeDay.month,
                  earliestLifeDay.day,
                ),
              )
              .inDays;
    final readiness = ShadowReadiness(
      hasMinimumCount:
          selected.length >= config.minimumEligibleObservationPairs,
      hasMinimumSpan: span >= config.minimumObservationSpanCalendarDays,
      hasCompleteWindows:
          windowItems.length == config.windowCount &&
          windowItems.every(
            (window) => window.length == config.windowEligiblePairs,
          ),
      spanCalendarDays: span,
    );
    final exclusionCounts = <LearningIneligibilityReason, int>{};
    for (final item in excluded) {
      for (final reason in item.eligibility.reasonCodes) {
        exclusionCounts.update(reason, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final directionCounts = _countDirections(directions);
    final windowCounts = [
      for (final window in windowItems) _countDirections(window),
    ];
    final exclusionReasonJson = <String, Object?>{};
    for (final reason in LearningIneligibilityReason.values) {
      final count = exclusionCounts[reason];
      if (count != null) exclusionReasonJson[reason.code] = count;
    }
    final descriptive = <String, Object?>{
      'directionCounts': directionCounts.toJson(),
      'earliestSelectedLifeDay': earliestLifeDay?.toString(),
      'eligibleTotal': eligible.length,
      'excludedReasonCounts': exclusionReasonJson,
      'excludedTotal': excluded.length,
      'latestSelectedLifeDay': latestLifeDay?.toString(),
      'missingToMinimum':
          (config.minimumEligibleObservationPairs - selected.length).clamp(
            0,
            config.minimumEligibleObservationPairs,
          ),
      'readiness': readiness.toJson(),
      'selectedEligible': selected.length,
      'windowDirectionCounts': [
        for (final counts in windowCounts) counts.toJson(),
      ],
      'windowSizes': [for (final window in windowItems) window.length],
    };
    final evidenceSnapshotJson = canonicalEncoder.encode({
      'descriptive': descriptive,
      'hashInput': hashInput,
    });
    final currentValuesJson = canonicalEncoder.encode({
      'baseEnergy': baseEnergy,
    });
    return ShadowEvidencePackage(
      sourceModelIdentity: sourceModelIdentity,
      referenceType: referenceType,
      baseEnergy: baseEnergy,
      evidenceSnapshotJson: evidenceSnapshotJson,
      evidenceHash: evidenceHash,
      currentValuesJson: currentValuesJson,
      eligibleTotal: eligible.length,
      selectedEligible: selected.length,
      excludedTotal: excluded.length,
      missingToMinimum:
          (config.minimumEligibleObservationPairs - selected.length).clamp(
            0,
            config.minimumEligibleObservationPairs,
          ),
      earliestLifeDay: earliestLifeDay,
      latestLifeDay: latestLifeDay,
      directionCounts: directionCounts,
      windowDirectionCounts: windowCounts,
      windowSizes: [for (final window in windowItems) window.length],
      exclusionCounts: exclusionCounts,
      readiness: readiness,
    );
  }

  Map<String, Object?> _eligibleEvidenceJson(EnergyObservation observation) {
    final comparison = comparisonService.compare(
      actualState: observation.absoluteState!,
      estimate: observation.estimateAtObservation!,
      initialEstimate: observation.initialEstimateAtObservation!,
    );
    return {
      'absoluteState': observation.absoluteState!.code,
      'activeActivityCountAtObservation':
          observation.activeActivityCountAtObservation!,
      'actualOrdinal': comparison.actualOrdinal,
      'alignmentDirection': comparison.direction!.code,
      'baseEnergyAtObservation': observation.baseEnergyAtObservation!,
      'comparisonBandVersion': observation.comparisonBandVersion!,
      'contractVersion': observation.contractVersion!,
      'coverageState': observation.coverageState!.code,
      'effectiveModelFingerprintAtObservation':
          observation.effectiveModelFingerprintAtObservation!,
      'estimateAtObservation': observation.estimateAtObservation!,
      'estimatedOrdinalAtObservation':
          observation.estimatedOrdinalAtObservation!,
      'hasMorningCheckIn': true,
      'id': observation.id,
      'initialEstimateAtObservation': observation.initialEstimateAtObservation!,
      'lifeDay': observation.lifeDay.toString(),
      'modelRegimeEpochAtObservation':
          observation.modelRegimeEpochAtObservation!,
      'modelRegimeKey': observation.modelRegimeKey!,
      'observedAt': canonicalUtcIso8601Micros(observation.observedAt),
      'personalizationVersionAtObservation':
          observation.personalizationVersionAtObservation!,
      'referenceType': observation.referenceType!.code,
      'ruleVersionAtObservation': observation.ruleVersionAtObservation!,
      'settled': true,
    };
  }

  ObservationAlignmentDirection _direction(EnergyObservation observation) {
    return comparisonService
        .compare(
          actualState: observation.absoluteState!,
          estimate: observation.estimateAtObservation!,
          initialEstimate: observation.initialEstimateAtObservation!,
        )
        .direction!;
  }

  List<List<ObservationAlignmentDirection>> _windows(
    List<ObservationAlignmentDirection> directions,
    ShadowLearningConfig config,
  ) {
    final windows = <List<ObservationAlignmentDirection>>[];
    for (var index = 0; index < config.windowCount; index++) {
      final start = index * config.windowEligiblePairs;
      if (start >= directions.length) break;
      final end = (start + config.windowEligiblePairs).clamp(
        0,
        directions.length,
      );
      windows.add(directions.sublist(start, end));
    }
    return windows;
  }

  DirectionCounts _countDirections(
    List<ObservationAlignmentDirection> directions,
  ) {
    var lower = 0;
    var aligned = 0;
    var higher = 0;
    for (final direction in directions) {
      switch (direction) {
        case ObservationAlignmentDirection.lower:
          lower++;
        case ObservationAlignmentDirection.aligned:
          aligned++;
        case ObservationAlignmentDirection.higher:
          higher++;
      }
    }
    return DirectionCounts(lower: lower, aligned: aligned, higher: higher);
  }
}

String deterministicLearningRunId({
  required LearningParameterFamily parameterFamily,
  required String sourceModelIdentity,
  required String algorithmVersion,
  required String configVersion,
  required String evidenceHash,
  CanonicalJsonEncoder canonicalEncoder = const CanonicalJsonEncoder(),
}) {
  final canonical = canonicalEncoder.encode({
    'algorithmVersion': algorithmVersion,
    'configVersion': configVersion,
    'evidenceHash': evidenceHash,
    'parameterFamily': parameterFamily.code,
    'sourceModelIdentity': sourceModelIdentity,
  });
  return '$deterministicLearningRunIdV1:'
      '${sha256.convert(utf8.encode(canonical))}';
}

int _compareObservations(EnergyObservation left, EnergyObservation right) {
  final lifeDay = left.lifeDay.compareTo(right.lifeDay);
  if (lifeDay != 0) return lifeDay;
  final observedAt = left.observedAt.toUtc().compareTo(
    right.observedAt.toUtc(),
  );
  if (observedAt != 0) return observedAt;
  return left.id.compareTo(right.id);
}

final class _EvaluatedObservation {
  const _EvaluatedObservation({
    required this.observation,
    required this.eligibility,
  });

  final EnergyObservation observation;
  final LearningEligibility eligibility;
}
