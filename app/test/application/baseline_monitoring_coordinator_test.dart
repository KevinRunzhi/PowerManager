import 'package:power_manager/application/automatic_learning_coordinator.dart';
import 'package:power_manager/application/baseline_monitoring_coordinator.dart';
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
import 'package:power_manager/domain/learning/baseline_monitoring.dart';
import 'package:power_manager/domain/learning/baseline_production_learner.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

import '../data/db/test_database.dart';

void main() {
  late _Harness harness;

  setUp(() async {
    harness = _Harness();
    await harness.seedInitialEvidence();
    await harness.activateLearnedBaseline();
    await harness.seedActiveEpochEvidence(estimate: 10);
  });

  tearDown(() => harness.close());

  test(
    'worsened new epoch suspends baseline, keeps model and is idempotent',
    () async {
      harness.clock.value = DateTime.utc(2026, 9, 7, 12);
      final first = await harness.monitor().request(
        BaselineMonitoringTrigger.settlement,
      );
      expect(first.createdRuns, 1);
      expect(first.completedRuns, 1);
      expect(first.suspended, isTrue);

      final settings = await harness.settings.get();
      expect(settings.baselineLearningSuspended, isTrue);
      expect(settings.activityImpactLearningSuspended, isFalse);
      expect((await harness.models.getActive()).baseEnergy, 98);
      expect(
        (await harness.runs.list()).where(
          (run) => run.algorithmVersion == baselineMonitoringAlgorithmV1,
        ),
        hasLength(1),
      );
      expect(
        (await harness.notices.list()).where(
          (notice) => notice.type == LearningNoticeType.learningSuspended,
        ),
        hasLength(1),
      );

      final second = await harness.monitor().request(
        BaselineMonitoringTrigger.retry,
      );
      expect(second.createdRuns, 0);
      expect(second.skipReason, BaselineMonitoringSkipReason.learningSuspended);
      expect(
        (await harness.notices.list()).where(
          (notice) => notice.type == LearningNoticeType.learningSuspended,
        ),
        hasLength(1),
      );
    },
  );
}

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

  final gate = const LearningProductionGate(
    baselineProductionLearningEnabled: true,
    activityImpactProductionLearningEnabled: true,
    automaticLearningEngineEnabled: true,
    baselineAutoApplyEnabled: true,
    supportedBaselineAlgorithms: {baselineProductionAlgorithmV1},
    supportedBaselineConfigs: {baselineProductionConfigV1},
  );

  Future<void> close() => database.close();

  ModelActivationService activation() => ModelActivationService(
    transactionRunner: DriftTransactionRunner(database),
    settings: settings,
    versions: models,
    learningRuns: runs,
    consents: consents,
    notices: notices,
    productionGate: gate,
  );

  AutomaticLearningCoordinator learner() => AutomaticLearningCoordinator(
    writeCoordinator: writer,
    transactionRunner: DriftTransactionRunner(database),
    clock: clock,
    integrityVerifier: const _Integrity(),
    observations: observations,
    mornings: mornings,
    summaries: summaries,
    learningRuns: runs,
    productionGate: gate,
    productionConfig: BaselineProductionConfig(),
    modelActivationService: activation(),
    personalizationVersions: models,
    appSettings: settings,
  );

  BaselineMonitoringCoordinator monitor() => BaselineMonitoringCoordinator(
    transactionRunner: DriftTransactionRunner(database),
    clock: clock,
    observations: observations,
    mornings: mornings,
    summaries: summaries,
    learningRuns: runs,
    versions: models,
    settings: settings,
    modelActivationService: activation(),
    config: BaselineMonitoringConfig(),
  );

  Future<void> seedInitialEvidence() async {
    final current = await settings.get();
    await settings.save(
      AppSettings(
        activeRuleVersion: current.activeRuleVersion,
        pendingRuleVersion: null,
        pendingRuleEffectiveLifeDay: null,
        onboardingCompleted: current.onboardingCompleted,
        baselineLearningMode: LearningMode.review,
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
    for (var index = 0; index < 14; index++) {
      await _insertObservation(
        index: index,
        day: _dayPlus(LifeDay(2026, 7, 15), index * 2),
        baseEnergy: 100,
        personalizationId: fixedMvpAPersonalizationVersion,
        fingerprint: fixedMvpAEffectiveModelFingerprint,
        epoch: fixedMvpAInitialModelRegimeEpoch,
        estimate: 50,
      );
    }
  }

  Future<void> activateLearnedBaseline() async {
    await learner().request(AutomaticLearningTrigger.settlement);
    final pending = await models.findPending();
    expect(pending, isNotNull);
    await activation().acceptReviewCandidate(
      versionId: pending!.id,
      currentLifeDay: LifeDay(2026, 8, 15),
      effectiveLifeDay: LifeDay(2026, 8, 16),
      at: clock.now(),
    );
    await activation().activateDue(
      currentLifeDay: LifeDay(2026, 8, 16),
      at: DateTime.utc(2026, 8, 16, 5),
    );
  }

  Future<void> seedActiveEpochEvidence({required int estimate}) async {
    final active = await models.getActive();
    for (var index = 0; index < 14; index++) {
      await _insertObservation(
        index: 100 + index,
        day: _dayPlus(LifeDay(2026, 8, 17), index * 2),
        baseEnergy: active.baseEnergy,
        personalizationId: active.id,
        fingerprint: active.effectiveModelFingerprint,
        epoch: active.modelRegimeEpoch,
        estimate: estimate,
      );
    }
  }

  Future<void> _insertObservation({
    required int index,
    required LifeDay day,
    required int baseEnergy,
    required String personalizationId,
    required String fingerprint,
    required String epoch,
    required int estimate,
  }) async {
    await mornings.insert(
      MorningCheckIn(
        id: 'monitor-morning-$index',
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
      estimate: estimate,
      initialEstimate: 99,
    );
    final regime = const ModelRegimeKeyBuilder().build(
      referenceType: ObservationReferenceType.currentMoment,
      baseEnergy: baseEnergy,
      ruleVersion: energyRulesV2MvpAVersion,
      comparisonBandVersion: mvpBComparisonBandV1,
      effectiveModelFingerprint: fingerprint,
      modelRegimeEpoch: epoch,
    );
    await observations.insert(
      EnergyObservation(
        id: 'monitor-observation-$index',
        lifeDay: day,
        type: EnergyObservationType.dailyAbsolute,
        absoluteState: AbsoluteEnergyState.okay,
        relativeState: null,
        estimateAtObservation: estimate,
        observedAt: DateTime.utc(day.year, day.month, day.day, 12),
        contractVersion: mvpBObservationContractV1,
        referenceType: ObservationReferenceType.currentMoment,
        initialEstimateAtObservation: 99,
        estimatedOrdinalAtObservation: comparison.estimatedOrdinal,
        baseEnergyAtObservation: baseEnergy,
        ruleVersionAtObservation: energyRulesV2MvpAVersion,
        comparisonBandVersion: mvpBComparisonBandV1,
        personalizationVersionAtObservation: personalizationId,
        effectiveModelFingerprintAtObservation: fingerprint,
        modelRegimeEpochAtObservation: epoch,
        activeActivityCountAtObservation: 0,
        coverageState: ObservationCoverageState.confirmed,
        modelRegimeKey: regime,
      ),
    );
    await summaries.insertOrGet(
      DailySummary(
        lifeDay: day,
        baseEstimatedEnergy: baseEnergy,
        ruleVersion: energyRulesV2MvpAVersion,
        morningAdjustment: 0,
        shortTermAdjustment: 0,
        initialEstimatedEnergy: 99,
        finalEstimatedEnergy: 99,
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

LifeDay _dayPlus(LifeDay day, int days) {
  final value = DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).add(Duration(days: days));
  return LifeDay(value.year, value.month, value.day);
}
