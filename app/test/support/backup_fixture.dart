import 'package:power_manager/data/export/power_manager_export_dto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

final backupFixtureNow = DateTime.utc(2026, 8, 9, 4);

PowerManagerExportDto backupFixture({int baseEnergy = 100}) {
  final config = EnergyRuleConfig.v2MvpA();
  return PowerManagerExportDto(
    schemaVersion: 1,
    exportedAt: backupFixtureNow,
    appVersion: '0.1.0+fixture',
    appSettings: AppSettings(
      baseEstimatedEnergy: baseEnergy,
      pendingBaseEstimatedEnergy: null,
      baseEnergyEffectiveLifeDay: null,
      activeRuleVersion: config.ruleVersion,
      pendingRuleVersion: null,
      pendingRuleEffectiveLifeDay: null,
      onboardingCompleted: true,
      createdAt: backupFixtureNow,
      updatedAt: backupFixtureNow,
    ),
    ruleVersions: [
      RuleConfigVersion(
        version: config.ruleVersion,
        values: {
          'ruleVersion': config.ruleVersion,
          'activityRules': {
            for (final rule in config.rules)
              rule.subcategory.code: {
                for (final duration in DurationSlot.values)
                  '${duration.minutes}': rule.deltas[duration],
              },
          },
        },
        createdAt: backupFixtureNow,
      ),
    ],
    morningCheckIns: const [],
    activityRecords: const [],
    energyObservations: const [],
    dailySummaries: const [],
    promptReceipts: const [],
  );
}

PowerManagerExportDto backupFixtureV2({int baseEnergy = 100}) {
  final legacy = backupFixture(baseEnergy: baseEnergy);
  final config = EnergyRuleConfig.v2MvpA();
  final lifeDay = LifeDay(2026, 8, 8);
  final activeDelta = config.theoreticalDelta(
    ActivitySubcategory.homework,
    DurationSlot.minutes30,
  );
  final deletedDelta = config.theoreticalDelta(
    ActivitySubcategory.nap,
    DurationSlot.minutes30,
  );
  final activeUpdatedAt = DateTime.utc(2026, 8, 8, 2);
  final deletedSnapshotAt = DateTime.utc(2026, 8, 8, 1, 30);
  final deletedAt = DateTime.utc(2026, 8, 8, 3, 30);
  final activities = [
    StoredEstimatedActivity(
      id: 'activity-active-v2',
      lifeDay: lifeDay,
      completedAt: DateTime.utc(2026, 8, 8, 1),
      createdAt: DateTime.utc(2026, 8, 8, 1),
      updatedAt: activeUpdatedAt,
      category: ActivityCategory.study,
      subcategory: ActivitySubcategory.homework,
      duration: DurationSlot.minutes30,
      theoreticalDelta: activeDelta,
      appliedDelta: activeDelta,
      ruleVersion: config.ruleVersion,
      status: ActivityRecordStatus.active,
      deletedAt: null,
    ),
    StoredEstimatedActivity(
      id: 'activity-deleted-v2',
      lifeDay: lifeDay,
      completedAt: DateTime.utc(2026, 8, 8, 1),
      createdAt: DateTime.utc(2026, 8, 8, 1),
      updatedAt: deletedAt,
      category: ActivityCategory.recovery,
      subcategory: ActivitySubcategory.nap,
      duration: DurationSlot.minutes30,
      theoreticalDelta: deletedDelta,
      appliedDelta: deletedDelta,
      ruleVersion: config.ruleVersion,
      status: ActivityRecordStatus.deleted,
      deletedAt: deletedAt,
    ),
  ];
  return PowerManagerExportDto(
    schemaVersion: 2,
    exportedAt: legacy.exportedAt,
    appVersion: '0.1.2+fixture',
    appSettings: legacy.appSettings,
    ruleVersions: legacy.ruleVersions,
    morningCheckIns: legacy.morningCheckIns,
    activityRecords: activities,
    energyObservations: [
      EnergyObservation(
        id: 'observation-contract-v2',
        lifeDay: lifeDay,
        type: EnergyObservationType.dailyAbsolute,
        absoluteState: AbsoluteEnergyState.good,
        relativeState: null,
        estimateAtObservation: baseEnergy + activeDelta,
        observedAt: backupFixtureNow,
        contractVersion: mvpBObservationContractV1,
        referenceType: ObservationReferenceType.currentMoment,
        initialEstimateAtObservation: baseEnergy,
        estimatedOrdinalAtObservation: 4,
        baseEnergyAtObservation: baseEnergy,
        ruleVersionAtObservation: config.ruleVersion,
        comparisonBandVersion: mvpBComparisonBandV1,
        personalizationVersionAtObservation: fixedMvpAPersonalizationVersion,
        effectiveModelFingerprintAtObservation:
            fixedMvpAEffectiveModelFingerprint,
        modelRegimeEpochAtObservation: fixedMvpAInitialModelRegimeEpoch,
        activeActivityCountAtObservation: 1,
        coverageState: ObservationCoverageState.confirmed,
        modelRegimeKey: const ModelRegimeKeyBuilder().build(
          referenceType: ObservationReferenceType.currentMoment,
          baseEnergy: baseEnergy,
          ruleVersion: config.ruleVersion,
          comparisonBandVersion: mvpBComparisonBandV1,
          effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
          modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
        ),
      ),
      EnergyObservation(
        id: 'observation-legacy-v2',
        lifeDay: lifeDay,
        type: EnergyObservationType.relativeCorrection,
        absoluteState: null,
        relativeState: RelativeCorrection.aboutRight,
        estimateAtObservation: baseEnergy + activeDelta,
        observedAt: backupFixtureNow,
        coverageState: ObservationCoverageState.legacyUnknown,
      ),
    ],
    activityFeedback: [
      ActivityFeedback(
        id: 'feedback-active-v2',
        activityRecordId: activities[0].id,
        lifeDay: lifeDay,
        subcategorySnapshot: activities[0].subcategory,
        durationSnapshot: activities[0].duration,
        theoreticalDeltaSnapshot: activeDelta,
        appliedDeltaSnapshot: activeDelta,
        impactSignSnapshot: ActivityImpactSign.consumption,
        ruleVersionSnapshot: config.ruleVersion,
        activityUpdatedAtSnapshot: activeUpdatedAt,
        direction: ActivityFeedbackDirection.aboutRight,
        status: ActivityFeedbackStatus.active,
        invalidationReason: null,
        observedAt: DateTime.utc(2026, 8, 8, 3),
      ),
      ActivityFeedback(
        id: 'feedback-invalidated-v2',
        activityRecordId: activities[1].id,
        lifeDay: lifeDay,
        subcategorySnapshot: activities[1].subcategory,
        durationSnapshot: activities[1].duration,
        theoreticalDeltaSnapshot: deletedDelta,
        appliedDeltaSnapshot: deletedDelta,
        impactSignSnapshot: ActivityImpactSign.recovery,
        ruleVersionSnapshot: config.ruleVersion,
        activityUpdatedAtSnapshot: deletedSnapshotAt,
        direction: ActivityFeedbackDirection.strongerImpact,
        status: ActivityFeedbackStatus.invalidated,
        invalidationReason: ActivityFeedbackInvalidationReason.activityDeleted,
        observedAt: DateTime.utc(2026, 8, 8, 3),
      ),
    ],
    dailySummaries: legacy.dailySummaries,
    promptReceipts: legacy.promptReceipts,
  );
}

PowerManagerExportDto backupFixtureV3({int baseEnergy = 100}) {
  final previous = backupFixtureV2(baseEnergy: baseEnergy);
  final lifeDay = previous.energyObservations
      .firstWhere((item) => item.type == EnergyObservationType.dailyAbsolute)
      .lifeDay;
  final config = ShadowLearningConfig.evidenceReadinessV1();
  final evidence = const ShadowEvidenceBuilder()
      .buildAll(
        observations: previous.energyObservations,
        morningLifeDays: {lifeDay},
        settledLifeDays: {lifeDay},
        config: config,
      )
      .single;
  final run = LearningRun(
    id: deterministicLearningRunId(
      parameterFamily: LearningParameterFamily.baseline,
      sourceModelIdentity: evidence.sourceModelIdentity,
      algorithmVersion: config.algorithmVersion,
      configVersion: config.configVersion,
      evidenceHash: evidence.evidenceHash,
    ),
    parameterFamily: LearningParameterFamily.baseline,
    sourceModelIdentity: evidence.sourceModelIdentity,
    sourcePersonalizationVersionId: null,
    status: LearningRunStatus.completed,
    result: LearningRunResult.insufficientEvidence,
    evidenceSnapshotJson: evidence.evidenceSnapshotJson,
    evidenceHash: evidence.evidenceHash,
    evidenceHashVersion: config.evidenceHashVersion,
    algorithmVersion: config.algorithmVersion,
    configVersion: config.configVersion,
    currentValuesJson: evidence.currentValuesJson,
    candidateValuesJson: null,
    reasonCodesJson: const CanonicalJsonEncoder().encode([
      ShadowLearningReason.minimumEligibleObservationPairsNotMet.code,
      ShadowLearningReason.minimumObservationSpanNotMet.code,
      ShadowLearningReason.shadowWindowsIncomplete.code,
    ]),
    triggeredAt: backupFixtureNow,
    completedAt: backupFixtureNow.add(const Duration(seconds: 1)),
  );
  return PowerManagerExportDto(
    schemaVersion: 3,
    exportedAt: previous.exportedAt,
    appVersion: '0.1.3+fixture',
    appSettings: previous.appSettings,
    ruleVersions: previous.ruleVersions,
    morningCheckIns: previous.morningCheckIns,
    activityRecords: previous.activityRecords,
    energyObservations: previous.energyObservations,
    activityFeedback: previous.activityFeedback,
    learningRuns: [run],
    dailySummaries: previous.dailySummaries,
    promptReceipts: previous.promptReceipts,
  );
}
