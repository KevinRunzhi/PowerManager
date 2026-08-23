import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:power_manager/data/export/power_manager_export_dto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/energy/observation_comparison_service.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/personalization_identity.dart';
import 'package:power_manager/domain/learning/personalization_lifecycle.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

import 'backup_fixture.dart';

const productionFixtureAlgorithm = 'baseline-production-v1';
const productionFixtureConfig = 'baseline-production-config-v1';

PowerManagerExportDto productionBackupFixture({
  bool automaticScheduled = false,
  bool shortAutomaticNotice = false,
  String algorithmVersion = productionFixtureAlgorithm,
  String configVersion = productionFixtureConfig,
}) {
  final previous = backupFixtureV4();
  final active = previous.personalizationVersions.single;
  final run = _productionRun(
    source: active,
    algorithmVersion: algorithmVersion,
    configVersion: configVersion,
  );
  final createdAt = DateTime.utc(2026, 8, 15, 10);
  var candidate = learningPersonalizationVersion(
    parent: active,
    sourceRun: run,
    baseEnergy: 98,
    createdAt: createdAt,
    ruleVersion: previous.appSettings.activeRuleVersion,
  );
  final mode = automaticScheduled
      ? LearningMode.automatic
      : LearningMode.review;
  final noticeType = automaticScheduled
      ? LearningNoticeType.changeScheduled
      : LearningNoticeType.candidateAvailable;
  final noticeReason = automaticScheduled
      ? 'automaticCandidateScheduled'
      : 'reviewCandidateAvailable';
  if (automaticScheduled) {
    candidate = const PersonalizationLifecycle().transition(
      version: candidate,
      to: PersonalizationVersionStatus.scheduled,
      at: createdAt,
      reason: noticeReason,
      effectiveLifeDay: shortAutomaticNotice
          ? LifeDay(2026, 8, 16)
          : LifeDay(2026, 8, 17),
      scheduleSource: PersonalizationScheduleSource.automatic,
    );
  } else {
    candidate = const PersonalizationLifecycle().transition(
      version: candidate,
      to: PersonalizationVersionStatus.awaitingReview,
      at: createdAt,
      reason: noticeReason,
    );
  }
  const identities = PersonalizationIdentityBuilder();
  final dedupKey = identities.noticeDedupKey(
    parameterFamily: LearningParameterFamily.baseline,
    type: noticeType,
    personalizationVersionId: candidate.id,
    learningRunId: run.id,
    reasonCode: noticeReason,
  );
  final notice = LearningNotice(
    id: identities.noticeId(dedupKey),
    parameterFamily: LearningParameterFamily.baseline,
    type: noticeType,
    personalizationVersionId: candidate.id,
    learningRunId: run.id,
    dedupKey: dedupKey,
    status: LearningNoticeStatus.unseen,
    reasonCode: noticeReason,
    createdAt: createdAt,
    seenAt: null,
    dismissedAt: null,
  );
  final settings = AppSettings(
    activeRuleVersion: previous.appSettings.activeRuleVersion,
    pendingRuleVersion: null,
    pendingRuleEffectiveLifeDay: null,
    onboardingCompleted: previous.appSettings.onboardingCompleted,
    baselineLearningMode: mode,
    activityImpactLearningMode: LearningMode.off,
    baselineLearningSuspended: false,
    baselineLearningSuspendedAt: null,
    baselineLearningSuspensionReason: null,
    activityImpactLearningSuspended: false,
    activityImpactLearningSuspendedAt: null,
    activityImpactLearningSuspensionReason: null,
    baselineLearningCooldownUntil: null,
    activityImpactLearningCooldownUntil: null,
    createdAt: previous.appSettings.createdAt,
    updatedAt: createdAt,
  );
  return PowerManagerExportDto(
    schemaVersion: 4,
    exportedAt: DateTime.utc(2026, 8, 15, 12),
    appVersion: '0.1.4+production-fixture',
    appSettings: settings,
    ruleVersions: previous.ruleVersions,
    morningCheckIns: previous.morningCheckIns,
    activityRecords: previous.activityRecords,
    energyObservations: previous.energyObservations,
    activityFeedback: previous.activityFeedback,
    learningRuns: [...previous.learningRuns, run],
    personalizationVersions: [active, candidate],
    learningConsents: [
      LearningConsent(
        parameterFamily: LearningParameterFamily.baseline,
        disclosureVersion: baselineLearningDisclosureV1,
        acceptedAt: createdAt.subtract(const Duration(minutes: 1)),
      ),
    ],
    learningNotices: [notice],
    dailySummaries: previous.dailySummaries,
    promptReceipts: previous.promptReceipts,
  );
}

LearningRun _productionRun({
  required PersonalizationVersion source,
  required String algorithmVersion,
  required String configVersion,
}) {
  final observations = <EnergyObservation>[
    for (var index = 0; index < 14; index++)
      _observation(index, source: source),
  ];
  final evidence = const ShadowEvidenceBuilder()
      .buildAll(
        observations: observations,
        morningLifeDays: {for (final item in observations) item.lifeDay},
        settledLifeDays: {for (final item in observations) item.lifeDay},
        config: ShadowLearningConfig.evidenceReadinessV1(),
      )
      .single;
  final snapshot =
      jsonDecode(evidence.evidenceSnapshotJson) as Map<String, Object?>;
  final hashInput = snapshot['hashInput']! as Map<String, Object?>;
  hashInput['algorithmVersion'] = algorithmVersion;
  hashInput['configVersion'] = configVersion;
  const encoder = CanonicalJsonEncoder();
  final evidenceHash = sha256
      .convert(utf8.encode(encoder.encode(hashInput)))
      .toString();
  return LearningRun(
    id: deterministicLearningRunId(
      parameterFamily: LearningParameterFamily.baseline,
      sourceModelIdentity: evidence.sourceModelIdentity,
      algorithmVersion: algorithmVersion,
      configVersion: configVersion,
      evidenceHash: evidenceHash,
    ),
    parameterFamily: LearningParameterFamily.baseline,
    sourceModelIdentity: evidence.sourceModelIdentity,
    sourcePersonalizationVersionId: source.id,
    status: LearningRunStatus.completed,
    result: LearningRunResult.candidate,
    evidenceSnapshotJson: encoder.encode(snapshot),
    evidenceHash: evidenceHash,
    evidenceHashVersion: canonicalEvidenceHashV1,
    algorithmVersion: algorithmVersion,
    configVersion: configVersion,
    currentValuesJson: encoder.encode({'baseEnergy': source.baseEnergy}),
    candidateValuesJson: encoder.encode({'baseEnergy': 98}),
    reasonCodesJson: encoder.encode(const ['stableCandidate']),
    triggeredAt: DateTime.utc(2026, 8, 15, 9),
    completedAt: DateTime.utc(2026, 8, 15, 9, 1),
  );
}

EnergyObservation _observation(
  int index, {
  required PersonalizationVersion source,
}) {
  final date = DateTime.utc(2026, 7, 19).add(Duration(days: index * 2));
  final lifeDay = LifeDay(date.year, date.month, date.day);
  const actualState = AbsoluteEnergyState.okay;
  const estimate = 50;
  const initialEstimate = 100;
  final comparison = const ObservationComparisonService().compare(
    actualState: actualState,
    estimate: estimate,
    initialEstimate: initialEstimate,
  );
  final regime = const ModelRegimeKeyBuilder().build(
    referenceType: ObservationReferenceType.currentMoment,
    baseEnergy: source.baseEnergy,
    ruleVersion: energyRulesV2MvpAVersion,
    comparisonBandVersion: mvpBComparisonBandV1,
    effectiveModelFingerprint: source.effectiveModelFingerprint,
    modelRegimeEpoch: source.modelRegimeEpoch,
  );
  return EnergyObservation(
    id: 'production-${index.toString().padLeft(2, '0')}',
    lifeDay: lifeDay,
    type: EnergyObservationType.dailyAbsolute,
    absoluteState: actualState,
    relativeState: null,
    estimateAtObservation: estimate,
    observedAt: DateTime.utc(lifeDay.year, lifeDay.month, lifeDay.day, 12),
    contractVersion: mvpBObservationContractV1,
    referenceType: ObservationReferenceType.currentMoment,
    initialEstimateAtObservation: initialEstimate,
    estimatedOrdinalAtObservation: comparison.estimatedOrdinal,
    baseEnergyAtObservation: source.baseEnergy,
    ruleVersionAtObservation: energyRulesV2MvpAVersion,
    comparisonBandVersion: mvpBComparisonBandV1,
    personalizationVersionAtObservation: fixedMvpAPersonalizationVersion,
    effectiveModelFingerprintAtObservation: source.effectiveModelFingerprint,
    modelRegimeEpochAtObservation: source.modelRegimeEpoch,
    activeActivityCountAtObservation: 1,
    coverageState: ObservationCoverageState.confirmed,
    modelRegimeKey: regime,
  );
}
