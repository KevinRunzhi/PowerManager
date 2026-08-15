import 'dart:convert';

import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/energy/learning_eligibility_service.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

void main() {
  final config = ShadowLearningConfig.evidenceReadinessV1();

  test('13, 14, and 15 eligible pairs obey count and last-14 windows', () {
    final thirteen = _package(
      List.generate(13, (index) => _observation(index * 2)),
      config: config,
    );
    expect(thirteen.eligibleTotal, 13);
    expect(thirteen.selectedEligible, 13);
    expect(thirteen.missingToMinimum, 1);
    expect(thirteen.windowSizes, [7, 6]);
    expect(thirteen.readiness.hasMinimumCount, isFalse);
    expect(
      const BaselineShadowLearner()
          .evaluate(evidence: thirteen, config: config)
          .result,
      LearningRunResult.insufficientEvidence,
    );

    final fourteen = _package(
      List.generate(14, (index) => _observation(index * 2)),
      config: config,
    );
    expect(fourteen.selectedEligible, 14);
    expect(fourteen.windowSizes, [7, 7]);
    expect(fourteen.readiness.ready, isTrue);
    expect(
      const BaselineShadowLearner()
          .evaluate(evidence: fourteen, config: config)
          .result,
      LearningRunResult.readyForAudit,
    );

    final fifteen = _package(
      List.generate(15, (index) => _observation(index * 2)),
      config: config,
    );
    expect(fifteen.eligibleTotal, 15);
    expect(fifteen.selectedEligible, 14);
    expect(_selectedIds(fifteen), isNot(contains('observation-000')));
    expect(_selectedIds(fifteen).first, 'observation-002');
  });

  test('20, 21, and 22 calendar-day span boundaries are exact', () {
    ShadowEvidencePackage withSpan(int span) {
      final offsets = <int>[...List.generate(13, (index) => index), span];
      return _package([
        for (final offset in offsets) _observation(offset),
      ], config: config);
    }

    expect(withSpan(20).readiness.spanCalendarDays, 20);
    expect(withSpan(20).readiness.hasMinimumSpan, isFalse);
    expect(withSpan(21).readiness.hasMinimumSpan, isTrue);
    expect(withSpan(22).readiness.spanCalendarDays, 22);
    expect(withSpan(22).readiness.hasMinimumSpan, isTrue);
  });

  test('lifeDay, observedAt, then id provide stable tie ordering', () {
    final day = _day(0);
    final observedAt = DateTime.utc(2026, 1, 1, 12);
    final observations = [
      for (var index = 14; index >= 0; index--)
        _observation(
          0,
          id: 'tie-${index.toString().padLeft(2, '0')}',
          lifeDay: day,
          observedAt: observedAt,
        ),
    ];

    final evidence = _package(observations, config: config);

    expect(_selectedIds(evidence), [
      for (var index = 1; index < 15; index++)
        'tie-${index.toString().padLeft(2, '0')}',
    ]);
  });

  test('two seven-pair windows keep independent direction counts', () {
    final observations = <EnergyObservation>[
      for (var index = 0; index < 7; index++)
        _observation(index * 2, actualState: AbsoluteEnergyState.okay),
      for (var index = 7; index < 14; index++)
        _observation(index * 2, actualState: AbsoluteEnergyState.full),
    ];

    final evidence = _package(observations, config: config);

    expect(evidence.directionCounts.lower, 7);
    expect(evidence.directionCounts.higher, 7);
    expect(evidence.windowDirectionCounts.first.lower, 7);
    expect(evidence.windowDirectionCounts.first.higher, 0);
    expect(evidence.windowDirectionCounts.last.lower, 0);
    expect(evidence.windowDirectionCounts.last.higher, 7);
  });

  test('scoped exclusions use the shared eligibility reason order', () {
    final eligible = _observation(0);
    final uncertain = _observation(
      1,
      coverageState: ObservationCoverageState.uncertain,
    );
    final noMorning = _observation(2);
    final invalidInitial = _observation(3, initialEstimate: 0);
    final badOrdinal = _observation(4, estimatedOrdinal: 0);
    final missingEstimate = _observation(5, missingEstimate: true);
    final rebuiltMismatch = _observation(
      6,
      modelRegimeKey: 'model-regime-sha256-v1:${List.filled(64, 'f').join()}',
    );
    final observations = [
      eligible,
      uncertain,
      noMorning,
      invalidInitial,
      badOrdinal,
      missingEstimate,
      rebuiltMismatch,
    ];
    final packages = const ShadowEvidenceBuilder().buildAll(
      observations: observations,
      morningLifeDays: {
        for (final item in observations)
          if (item.id != noMorning.id) item.lifeDay,
      },
      settledLifeDays: {for (final item in observations) item.lifeDay},
      config: config,
    );
    final regular = packages.singleWhere(
      (item) => item.sourceModelIdentity == eligible.modelRegimeKey,
    );
    final mismatch = packages.singleWhere(
      (item) => item.sourceModelIdentity == rebuiltMismatch.modelRegimeKey,
    );

    expect(regular.eligibleTotal, 1);
    expect(
      regular.exclusionCounts[LearningIneligibilityReason.coverageUncertain],
      1,
    );
    expect(
      regular.exclusionCounts[LearningIneligibilityReason
          .missingMorningCheckIn],
      1,
    );
    expect(
      regular.exclusionCounts[LearningIneligibilityReason
          .invalidInitialEstimate],
      1,
    );
    expect(
      regular.exclusionCounts[LearningIneligibilityReason.integrityFailure],
      1,
    );
    expect(
      regular.exclusionCounts[LearningIneligibilityReason
          .missingEstimateSnapshot],
      1,
    );
    expect(
      mismatch.exclusionCounts[LearningIneligibilityReason.modelRegimeMismatch],
      1,
    );
  });

  test('reference type and model regime never share an evidence package', () {
    final observations = [
      _observation(0),
      _observation(
        1,
        referenceType: ObservationReferenceType.previousLifeDayEnd,
      ),
      _observation(2, baseEnergy: 110),
    ];

    final packages = _packages(observations, config: config);

    expect(packages, hasLength(3));
    expect(
      packages.map((item) => item.sourceModelIdentity).toSet(),
      hasLength(3),
    );
    expect(
      packages
          .where(
            (item) =>
                item.referenceType == ObservationReferenceType.currentMoment,
          )
          .length,
      2,
    );
  });

  test(
    'input order, timezone representation, and older evidence keep hash stable',
    () {
      final observations = [
        for (var index = 0; index < 14; index++) _observation(10 + index * 2),
      ];
      final forward = _package(observations, config: config);
      final reversed = _package(observations.reversed.toList(), config: config);
      expect(reversed.evidenceHash, forward.evidenceHash);
      expect(reversed.evidenceSnapshotJson, forward.evidenceSnapshotJson);

      final timezoneEquivalent = observations.toList();
      final source = timezoneEquivalent[5];
      timezoneEquivalent[5] = _observation(
        20,
        id: source.id,
        lifeDay: source.lifeDay,
        observedAt: source.observedAt.toUtc().add(const Duration(hours: 8)),
        observedAtIsLocalOffset: true,
      );
      expect(
        _package(timezoneEquivalent, config: config).evidenceHash,
        forward.evidenceHash,
      );

      final withOlder = _package([
        _observation(0, id: 'older-evidence'),
        ...observations,
      ], config: config);
      expect(withOlder.evidenceHash, forward.evidenceHash);
      expect(withOlder.eligibleTotal, 15);
      expect(
        withOlder.evidenceSnapshotJson,
        isNot(forward.evidenceSnapshotJson),
      );
    },
  );

  test(
    'legacy, missing-key, and unsettled records do not enter scoped hash',
    () {
      final eligible = _observation(0);
      final original = _package([eligible], config: config);
      final ignored = [
        _observation(1, legacyContract: true),
        _observation(2, omitModelRegimeKey: true),
        _observation(3),
      ];
      final packages = const ShadowEvidenceBuilder().buildAll(
        observations: [eligible, ...ignored],
        morningLifeDays: {
          eligible.lifeDay,
          for (final item in ignored) item.lifeDay,
        },
        settledLifeDays: {
          eligible.lifeDay,
          ignored[0].lifeDay,
          ignored[1].lifeDay,
        },
        config: config,
      );

      expect(packages, hasLength(1));
      expect(packages.single.evidenceHash, original.evidenceHash);
    },
  );

  test(
    'disabled engine is explicit and unsupported thresholds fail closed',
    () {
      final evidence = _package([_observation(0)], config: config);
      final disabled = ShadowLearningConfig.evidenceReadinessV1(
        engineEnabled: false,
      );
      final evaluation = const BaselineShadowLearner().evaluate(
        evidence: evidence,
        config: disabled,
      );

      expect(evaluation.result, LearningRunResult.configurationBlocked);
      expect(evaluation.reasonCodes, [
        ShadowLearningReason.automaticLearningEngineDisabled,
      ]);
      expect(
        () => ShadowLearningConfig(
          engineEnabled: true,
          minimumEligibleObservationPairs: 14,
          minimumObservationSpanCalendarDays: 21,
          windowCount: 2,
          windowEligiblePairs: 6,
        ),
        throwsArgumentError,
      );
    },
  );

  test('canonical evidence hash and timestamp have locked golden vectors', () {
    final evidence = _package([
      _observation(
        0,
        id: 'golden-observation',
        observedAt: DateTime.parse('2026-01-01T20:01:02.123456+08:00'),
      ),
    ], config: config);
    final snapshot = _snapshot(evidence);
    final selected = snapshot['hashInput']! as Map<String, Object?>;
    final rows = selected['selectedEligibleEvidence']! as List<Object?>;
    final row = rows.single! as Map<String, Object?>;

    expect(row['observedAt'], '2026-01-01T12:01:02.123456Z');
    expect(
      evidence.evidenceHash,
      '236b25f654a0c329589e41592d7359c16f240b52778e0c11067ebe783315d05d',
    );
  });
}

List<ShadowEvidencePackage> _packages(
  List<EnergyObservation> observations, {
  required ShadowLearningConfig config,
}) {
  return const ShadowEvidenceBuilder().buildAll(
    observations: observations,
    morningLifeDays: {for (final item in observations) item.lifeDay},
    settledLifeDays: {for (final item in observations) item.lifeDay},
    config: config,
  );
}

ShadowEvidencePackage _package(
  List<EnergyObservation> observations, {
  required ShadowLearningConfig config,
}) {
  return _packages(observations, config: config).single;
}

Map<String, Object?> _snapshot(ShadowEvidencePackage evidence) {
  return jsonDecode(evidence.evidenceSnapshotJson) as Map<String, Object?>;
}

List<String> _selectedIds(ShadowEvidencePackage evidence) {
  final snapshot = _snapshot(evidence);
  final hashInput = snapshot['hashInput']! as Map<String, Object?>;
  final selected = hashInput['selectedEligibleEvidence']! as List<Object?>;
  return [
    for (final item in selected)
      (item! as Map<String, Object?>)['id']! as String,
  ];
}

EnergyObservation _observation(
  int dayOffset, {
  String? id,
  LifeDay? lifeDay,
  DateTime? observedAt,
  bool observedAtIsLocalOffset = false,
  ObservationReferenceType referenceType =
      ObservationReferenceType.currentMoment,
  int baseEnergy = 100,
  int initialEstimate = 100,
  int estimate = 60,
  int estimatedOrdinal = 3,
  AbsoluteEnergyState actualState = AbsoluteEnergyState.good,
  ObservationCoverageState coverageState = ObservationCoverageState.confirmed,
  bool missingEstimate = false,
  bool legacyContract = false,
  bool omitModelRegimeKey = false,
  String? modelRegimeKey,
}) {
  final day = lifeDay ?? _day(dayOffset);
  final instant = observedAt ?? DateTime.utc(day.year, day.month, day.day, 12);
  final storedObservedAt = observedAtIsLocalOffset
      ? DateTime.parse(
          '${instant.year.toString().padLeft(4, '0')}-'
          '${instant.month.toString().padLeft(2, '0')}-'
          '${instant.day.toString().padLeft(2, '0')}T'
          '${instant.hour.toString().padLeft(2, '0')}:'
          '${instant.minute.toString().padLeft(2, '0')}:'
          '${instant.second.toString().padLeft(2, '0')}.'
          '${(instant.millisecond * 1000 + instant.microsecond).toString().padLeft(6, '0')}+08:00',
        )
      : instant;
  final expectedKey = const ModelRegimeKeyBuilder().build(
    referenceType: referenceType,
    baseEnergy: baseEnergy,
    ruleVersion: energyRulesV2MvpAVersion,
    comparisonBandVersion: mvpBComparisonBandV1,
    effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
    modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
  );
  return EnergyObservation(
    id: id ?? 'observation-${dayOffset.toString().padLeft(3, '0')}',
    lifeDay: day,
    type: EnergyObservationType.dailyAbsolute,
    absoluteState: actualState,
    relativeState: null,
    estimateAtObservation: missingEstimate ? null : estimate,
    observedAt: storedObservedAt,
    contractVersion: legacyContract ? null : mvpBObservationContractV1,
    referenceType: referenceType,
    initialEstimateAtObservation: initialEstimate,
    estimatedOrdinalAtObservation: estimatedOrdinal,
    baseEnergyAtObservation: baseEnergy,
    ruleVersionAtObservation: energyRulesV2MvpAVersion,
    comparisonBandVersion: mvpBComparisonBandV1,
    personalizationVersionAtObservation: fixedMvpAPersonalizationVersion,
    effectiveModelFingerprintAtObservation: fixedMvpAEffectiveModelFingerprint,
    modelRegimeEpochAtObservation: fixedMvpAInitialModelRegimeEpoch,
    activeActivityCountAtObservation: 0,
    coverageState: coverageState,
    modelRegimeKey: omitModelRegimeKey ? null : modelRegimeKey ?? expectedKey,
  );
}

LifeDay _day(int offset) {
  return LifeDay.fromLocalDateTime(DateTime(2026, 1, 1 + offset));
}
