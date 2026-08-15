import 'package:crypto/crypto.dart';
import 'package:power_manager/application/automatic_learning_coordinator.dart';
import 'package:power_manager/application/business_write_coordinator.dart';
import 'package:power_manager/application/model_activation_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/db/drift_transaction_runner.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/energy/observation_comparison_service.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/baseline_production_learner.dart';
import 'package:power_manager/domain/learning/personalization_identity.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

import '../data/db/test_database.dart';

void main() {
  late _Harness harness;

  setUp(() async {
    harness = _Harness();
    await harness.seedStableLowerEvidence();
  });

  tearDown(() => harness.close());

  test('review creates one production candidate and app notice', () async {
    await harness.enable(LearningMode.review);
    final report = await harness.coordinator().request(
      AutomaticLearningTrigger.settlement,
    );

    expect(report.completedRuns, 2);
    expect(await harness.runs.list(), hasLength(2));
    final production = (await harness.runs.list()).singleWhere(
      (run) => run.algorithmVersion == baselineProductionAlgorithmV1,
    );
    expect(production.result, LearningRunResult.candidate);
    expect(production.sourcePersonalizationVersionId, isNotNull);
    expect(production.candidateValuesJson, '{"baseEnergy":98}');
    final pending = await harness.models.findPending();
    expect(pending?.status, PersonalizationVersionStatus.awaitingReview);
    expect((await harness.notices.list()), hasLength(1));
  });

  test(
    'automatic schedules with the 24-hour notice and is idempotent',
    () async {
      await harness.enable(LearningMode.automatic);
      final coordinator = harness.coordinator();
      final first = await coordinator.request(
        AutomaticLearningTrigger.settlement,
      );
      final second = await coordinator.request(AutomaticLearningTrigger.retry);

      expect(first.completedRuns, 2);
      expect(second.createdRuns, 0);
      expect(await harness.runs.list(), hasLength(2));
      final pending = await harness.models.findPending();
      expect(pending?.status, PersonalizationVersionStatus.scheduled);
      expect(pending?.scheduleSource, PersonalizationScheduleSource.automatic);
      expect(
        pending!.effectiveLifeDay!.compareTo(LifeDay(2026, 8, 17)),
        greaterThanOrEqualTo(0),
      );
      expect((await harness.notices.list()), hasLength(1));
    },
  );

  test(
    'closed engine persists a blocked production run without a candidate',
    () async {
      await harness.enable(LearningMode.review);
      final coordinator = harness.coordinator(
        gate: const LearningProductionGate(
          baselineProductionLearningEnabled: true,
          activityImpactProductionLearningEnabled: true,
          automaticLearningEngineEnabled: false,
          supportedBaselineAlgorithms: {baselineProductionAlgorithmV1},
          supportedBaselineConfigs: {baselineProductionConfigV1},
        ),
      );
      await coordinator.request(AutomaticLearningTrigger.settlement);

      final production = (await harness.runs.list()).singleWhere(
        (run) => run.algorithmVersion == baselineProductionAlgorithmV1,
      );
      expect(production.result, LearningRunResult.configurationBlocked);
      expect(await harness.models.findPending(), isNull);
    },
  );

  test(
    'activity-impact pending candidate blocks a new baseline production run',
    () async {
      await harness.enable(LearningMode.review);
      final active = await harness.models.getActive();
      final evidence = '{"samples":["activity-pending"]}';
      final activityRun = LearningRun(
        id: 'activity-pending-run',
        parameterFamily: LearningParameterFamily.activityImpact,
        sourceModelIdentity: active.id,
        sourcePersonalizationVersionId: active.id,
        status: LearningRunStatus.completed,
        result: LearningRunResult.candidate,
        evidenceSnapshotJson: evidence,
        evidenceHash: _hash(evidence),
        evidenceHashVersion: canonicalEvidenceHashV1,
        algorithmVersion: activityImpactLearningAlgorithmV1,
        configVersion: activityImpactLearningConfigV1,
        currentValuesJson:
            '{"factors":{"selfStudyOrThesis|consumption":{"factorBps":100}}}',
        candidateValuesJson:
            '{"factors":{"selfStudyOrThesis|consumption":{"factorBps":105}}}',
        reasonCodesJson: '["sampleCount"]',
        triggeredAt: harness.clock.now(),
        completedAt: harness.clock.now().add(const Duration(minutes: 1)),
      );
      await harness.runs.insert(activityRun);
      final pending = learningPersonalizationVersion(
        parent: active,
        sourceRun: activityRun,
        baseEnergy: active.baseEnergy,
        createdAt: harness.clock.now(),
        ruleVersion: energyRulesV2MvpAVersion,
      );
      await harness.models.insert(pending);

      final report = await harness.coordinator().request(
        AutomaticLearningTrigger.settlement,
      );

      expect(report.completedRuns, 1); // shadow audit only
      expect(
        report.skipReason,
        LearningCoordinationSkipReason.blockedByOtherParameterFamily,
      );
      expect(
        (await harness.runs.list()).where(
          (run) => run.algorithmVersion == baselineProductionAlgorithmV1,
        ),
        isEmpty,
      );
      expect((await harness.models.findPending())!.id, pending.id);
    },
  );
}

String _hash(String value) => sha256.convert(value.codeUnits).toString();

final class _Harness {
  _Harness()
    : database = createTestDatabase(),
      clock = _MutableClock(DateTime.utc(2026, 8, 15, 12)) {
    settings = DriftAppSettingsRepository(database.appSettingsDao);
    models = DriftPersonalizationVersionsRepository(
      database.personalizationVersionsDao,
    );
    mornings = DriftMorningCheckInsRepository(database.morningCheckInsDao);
    observations = DriftEnergyObservationsRepository(
      database.energyObservationsDao,
    );
    summaries = DriftDailySummariesRepository(database.dailySummariesDao);
    runs = DriftLearningRunsRepository(database.learningRunsDao);
    consents = DriftLearningConsentsRepository(database.learningConsentsDao);
    notices = DriftLearningNoticesRepository(database.learningNoticesDao);
  }

  final AppDatabase database;
  final _MutableClock clock;
  final BusinessWriteCoordinator writer = SerialBusinessWriteCoordinator();
  late final DriftAppSettingsRepository settings;
  late final DriftPersonalizationVersionsRepository models;
  late final DriftMorningCheckInsRepository mornings;
  late final DriftEnergyObservationsRepository observations;
  late final DriftDailySummariesRepository summaries;
  late final DriftLearningRunsRepository runs;
  late final DriftLearningConsentsRepository consents;
  late final DriftLearningNoticesRepository notices;

  Future<void> close() => database.close();

  Future<void> enable(LearningMode mode) async {
    final current = await settings.get();
    await settings.save(
      AppSettings(
        activeRuleVersion: current.activeRuleVersion,
        pendingRuleVersion: null,
        pendingRuleEffectiveLifeDay: null,
        onboardingCompleted: current.onboardingCompleted,
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
        createdAt: current.createdAt,
        updatedAt: current.updatedAt,
      ),
    );
    await consents.insert(
      LearningConsent(
        parameterFamily: LearningParameterFamily.baseline,
        disclosureVersion: baselineLearningDisclosureV1,
        acceptedAt: clock.now(),
      ),
    );
  }

  AutomaticLearningCoordinator coordinator({LearningProductionGate? gate}) {
    final effectiveGate =
        gate ??
        const LearningProductionGate(
          baselineProductionLearningEnabled: true,
          activityImpactProductionLearningEnabled: true,
          automaticLearningEngineEnabled: true,
          baselineAutoApplyEnabled: true,
          supportedBaselineAlgorithms: {baselineProductionAlgorithmV1},
          supportedBaselineConfigs: {baselineProductionConfigV1},
        );
    final activation = ModelActivationService(
      transactionRunner: DriftTransactionRunner(database),
      settings: settings,
      versions: models,
      learningRuns: runs,
      consents: consents,
      notices: notices,
      productionGate: effectiveGate,
    );
    return AutomaticLearningCoordinator(
      writeCoordinator: writer,
      transactionRunner: DriftTransactionRunner(database),
      clock: clock,
      integrityVerifier: const _Integrity(),
      observations: observations,
      mornings: mornings,
      summaries: summaries,
      learningRuns: runs,
      productionGate: effectiveGate,
      productionConfig: BaselineProductionConfig(),
      modelActivationService: activation,
      personalizationVersions: models,
      appSettings: settings,
    );
  }

  Future<void> seedStableLowerEvidence() async {
    await settings.get();
    for (var index = 0; index < 14; index++) {
      final date = DateTime.utc(2026, 7, 15).add(Duration(days: index * 2));
      final day = LifeDay(date.year, date.month, date.day);
      await mornings.insert(
        MorningCheckIn(
          id: 'production-morning-$index',
          lifeDay: day,
          overallState: MorningOverallState.normal,
          freeTimeLevel: FreeTimeLevel.medium,
          pressureSource: PressureSource.low,
          sleepRecovery: SleepRecovery.normal,
          morningAdjustment: 0,
          completedAt: DateTime.utc(day.year, day.month, day.day, 5),
        ),
      );
      final comparison = const ObservationComparisonService().compare(
        actualState: AbsoluteEnergyState.okay,
        estimate: 50,
        initialEstimate: 99,
      );
      await observations.insert(
        EnergyObservation(
          id: 'production-observation-$index',
          lifeDay: day,
          type: EnergyObservationType.dailyAbsolute,
          absoluteState: AbsoluteEnergyState.okay,
          relativeState: null,
          estimateAtObservation: 50,
          observedAt: DateTime.utc(day.year, day.month, day.day, 12),
          contractVersion: mvpBObservationContractV1,
          referenceType: ObservationReferenceType.currentMoment,
          initialEstimateAtObservation: 99,
          estimatedOrdinalAtObservation: comparison.estimatedOrdinal,
          baseEnergyAtObservation: 100,
          ruleVersionAtObservation: energyRulesV2MvpAVersion,
          comparisonBandVersion: mvpBComparisonBandV1,
          personalizationVersionAtObservation: fixedMvpAPersonalizationVersion,
          effectiveModelFingerprintAtObservation:
              fixedMvpAEffectiveModelFingerprint,
          modelRegimeEpochAtObservation: fixedMvpAInitialModelRegimeEpoch,
          activeActivityCountAtObservation: 0,
          coverageState: ObservationCoverageState.confirmed,
          modelRegimeKey: const ModelRegimeKeyBuilder().build(
            referenceType: ObservationReferenceType.currentMoment,
            baseEnergy: 100,
            ruleVersion: energyRulesV2MvpAVersion,
            comparisonBandVersion: mvpBComparisonBandV1,
            effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
            modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
          ),
        ),
      );
      await summaries.insertOrGet(
        DailySummary(
          lifeDay: day,
          baseEstimatedEnergy: 100,
          ruleVersion: energyRulesV2MvpAVersion,
          morningAdjustment: 0,
          shortTermAdjustment: 0,
          initialEstimatedEnergy: 100,
          finalEstimatedEnergy: 100,
          totalConsumption: 0,
          totalRecovery: 0,
          categorySummaries: {
            for (final category in ActivityCategory.values)
              category: CategoryEstimatedSummary(
                category: category,
                durationMinutes: 0,
                netDelta: 0,
                grossDelta: 0,
              ),
          },
          isStandardEffectiveDay: false,
          isWeakEffectiveDay: false,
          settledAt: DateTime.utc(day.year, day.month, day.day + 1, 4),
        ),
      );
    }
  }
}

final class _Integrity implements LearningIntegrityVerifier {
  const _Integrity();

  @override
  Future<bool> verify() async => true;
}

final class _MutableClock implements Clock {
  _MutableClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}
