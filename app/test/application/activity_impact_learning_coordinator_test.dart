import 'package:power_manager/application/activity_impact_learning_coordinator.dart';
import 'package:power_manager/application/activity_impact_monitoring_coordinator.dart';
import 'package:power_manager/application/automatic_learning_coordinator.dart';
import 'package:power_manager/application/business_write_coordinator.dart';
import 'package:power_manager/application/model_activation_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/db/drift_transaction_runner.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/activity_impact_contract.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

import '../data/db/test_database.dart';

void main() {
  late _Harness harness;

  setUp(() {
    harness = _Harness();
  });

  tearDown(() => harness.close());

  test('does not write a learning run without a responded sample', () async {
    await harness.enable(LearningMode.review);

    final report = await harness.coordinator().request(
      AutomaticLearningTrigger.settlement,
    );

    expect(report.createdRuns, 0);
    expect(report.completedRuns, 0);
    expect(report.skipReason, LearningCoordinationSkipReason.noSettledEvidence);
    expect(await harness.runs.list(), isEmpty);
  });

  test(
    'monitoring also stays read-only when there is no responded sample',
    () async {
      await harness.enable(LearningMode.review);

      final run = await harness.monitoring().request();

      expect(run, isNull);
      expect(await harness.runs.list(), isEmpty);
    },
  );

  test(
    'automatic activity learning is blocked when automatic apply is closed',
    () async {
      await harness.enable(LearningMode.automatic);
      await harness.seedEligibleEvidence();

      final report = await harness.coordinator().request(
        AutomaticLearningTrigger.settlement,
      );

      expect(report.completedRuns, 1);
      final run = (await harness.runs.list()).single;
      expect(run.result, LearningRunResult.configurationBlocked);
      expect(run.reasonCodesJson, contains('automaticApplyDisabled'));
      expect(await harness.models.findPending(), isNull);
    },
  );

  test('repeated activity evidence is idempotent', () async {
    await harness.enable(LearningMode.review);
    await harness.seedEligibleEvidence();

    final coordinator = harness.coordinator();
    final first = await coordinator.request(
      AutomaticLearningTrigger.settlement,
    );
    final second = await coordinator.request(AutomaticLearningTrigger.retry);

    expect(first.createdRuns, 1);
    expect(second.createdRuns, 0);
    expect(second.completedRuns, 0);
    expect(await harness.runs.list(), hasLength(1));
    expect(await harness.models.findPending(), isNotNull);
  });
}

final class _Harness {
  _Harness()
    : clock = _MutableClock(DateTime.utc(2026, 8, 25, 12)),
      database = createTestDatabase(
        clock: _MutableClock(DateTime.utc(2026, 8, 25, 12)),
      ) {
    settings = DriftAppSettingsRepository(database.appSettingsDao);
    models = DriftPersonalizationVersionsRepository(
      database.personalizationVersionsDao,
    );
    activities = DriftActivityRecordsRepository(database.activityRecordsDao);
    feedback = DriftActivityFeedbackRepository(database.activityFeedbackDao);
    samples = DriftActivityFeedbackSamplesRepository(
      database.activityFeedbackSamplesDao,
    );
    summaries = DriftDailySummariesRepository(database.dailySummariesDao);
    factors = DriftPersonalizationActivityFactorsRepository(
      database.personalizationActivityFactorsDao,
    );
    runs = DriftLearningRunsRepository(database.learningRunsDao);
    consents = DriftLearningConsentsRepository(database.learningConsentsDao);
    notices = DriftLearningNoticesRepository(database.learningNoticesDao);
  }

  final _MutableClock clock;
  final AppDatabase database;
  final BusinessWriteCoordinator writer = SerialBusinessWriteCoordinator();
  late final DriftAppSettingsRepository settings;
  late final DriftPersonalizationVersionsRepository models;
  late final DriftActivityRecordsRepository activities;
  late final DriftActivityFeedbackRepository feedback;
  late final DriftActivityFeedbackSamplesRepository samples;
  late final DriftDailySummariesRepository summaries;
  late final DriftPersonalizationActivityFactorsRepository factors;
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
        baselineLearningMode: LearningMode.off,
        activityImpactLearningMode: mode,
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
        parameterFamily: LearningParameterFamily.activityImpact,
        disclosureVersion: activityImpactLearningDisclosureV1,
        acceptedAt: clock.now(),
      ),
    );
  }

  ActivityImpactLearningCoordinator coordinator() {
    const gate = LearningProductionGate(
      baselineProductionLearningEnabled: false,
      activityImpactProductionLearningEnabled: true,
      automaticLearningEngineEnabled: true,
      activityImpactAutoApplyEnabled: false,
      supportedActivityImpactAlgorithms: {activityImpactLearningAlgorithmV1},
      supportedActivityImpactConfigs: {activityImpactLearningConfigV1},
    );
    final activation = ModelActivationService(
      transactionRunner: DriftTransactionRunner(database),
      settings: settings,
      versions: models,
      learningRuns: runs,
      consents: consents,
      notices: notices,
      activityFactors: factors,
      productionGate: gate,
    );
    return ActivityImpactLearningCoordinator(
      writeCoordinator: writer,
      transactionRunner: DriftTransactionRunner(database),
      clock: clock,
      integrityVerifier: const _Integrity(),
      activities: activities,
      feedback: feedback,
      samples: samples,
      summaries: summaries,
      factors: factors,
      versions: models,
      learningRuns: runs,
      settings: settings,
      modelActivationService: activation,
      productionGate: gate,
    );
  }

  ActivityImpactMonitoringCoordinator monitoring() {
    const gate = LearningProductionGate(
      baselineProductionLearningEnabled: false,
      activityImpactProductionLearningEnabled: true,
      automaticLearningEngineEnabled: true,
      supportedActivityImpactAlgorithms: {activityImpactLearningAlgorithmV1},
      supportedActivityImpactConfigs: {activityImpactLearningConfigV1},
    );
    final activation = ModelActivationService(
      transactionRunner: DriftTransactionRunner(database),
      settings: settings,
      versions: models,
      learningRuns: runs,
      consents: consents,
      notices: notices,
      activityFactors: factors,
      productionGate: gate,
    );
    return ActivityImpactMonitoringCoordinator(
      writeCoordinator: writer,
      transactionRunner: DriftTransactionRunner(database),
      clock: clock,
      integrityVerifier: const _Integrity(),
      activities: activities,
      feedback: feedback,
      samples: samples,
      summaries: summaries,
      factors: factors,
      versions: models,
      learningRuns: runs,
      settings: settings,
      modelActivationService: activation,
      productionGate: gate,
    );
  }

  Future<void> seedEligibleEvidence() async {
    final active = await models.getActive();
    final regime = LifeDay(2026, 8, 25);
    for (var index = 0; index < 8; index++) {
      final day = LifeDay(2026, 8, 25 + index % 4);
      final timestamp = DateTime.utc(day.year, day.month, day.day, 10);
      final activityId = 'activity-$index';
      final feedbackId = 'feedback-$index';
      final sampleId = 'sample-$index';
      await activities.insert(
        StoredEstimatedActivity(
          id: activityId,
          lifeDay: day,
          completedAt: timestamp,
          createdAt: timestamp,
          updatedAt: timestamp,
          category: ActivityCategory.study,
          subcategory: ActivitySubcategory.selfStudyOrThesis,
          duration: DurationSlot.minutes30,
          theoreticalDelta: -6,
          appliedDelta: -6,
          ruleVersion: activityImpactSupportedRuleVersion,
          status: ActivityRecordStatus.active,
          deletedAt: null,
          personalizationVersionId: active.id,
          factorRegimeStartedLifeDay: regime,
          defaultTheoreticalDelta: -6,
          factor: 1,
          personalizedTheoreticalDelta: -6,
        ),
      );
      await feedback.insert(
        ActivityFeedback(
          id: feedbackId,
          activityRecordId: activityId,
          lifeDay: day,
          subcategorySnapshot: ActivitySubcategory.selfStudyOrThesis,
          durationSnapshot: DurationSlot.minutes30,
          theoreticalDeltaSnapshot: -6,
          appliedDeltaSnapshot: -6,
          impactSignSnapshot: ActivityImpactSign.consumption,
          ruleVersionSnapshot: activityImpactSupportedRuleVersion,
          activityUpdatedAtSnapshot: timestamp,
          direction: ActivityFeedbackDirection.strongerImpact,
          status: ActivityFeedbackStatus.active,
          invalidationReason: null,
          observedAt: timestamp,
          defaultTheoreticalDeltaSnapshot: -6,
          factorSnapshot: 1,
          personalizedTheoreticalDeltaSnapshot: -6,
          personalizationVersionId: active.id,
          factorRegimeStartedLifeDay: regime,
          collectionSource: ActivityFeedbackCollectionSource.sampledPrompt,
          samplingPolicyVersion: activityFeedbackSamplingPolicyV1,
          sampledAt: timestamp,
          sampleId: sampleId,
        ),
      );
      await samples.insert(
        ActivityFeedbackSample(
          id: sampleId,
          activityRecordId: activityId,
          lifeDay: day,
          samplingPolicyVersion: activityFeedbackSamplingPolicyV1,
          status: ActivityFeedbackSampleStatus.responded,
          selectedAt: timestamp,
          promptedAt: timestamp,
          respondedAt: timestamp,
          feedbackId: feedbackId,
          invalidatedAt: null,
          invalidationReason: null,
        ),
      );
      await summaries.insertOrGet(_summary(day));
    }
  }

  DailySummary _summary(LifeDay day) => DailySummary(
    lifeDay: day,
    baseEstimatedEnergy: 100,
    ruleVersion: activityImpactSupportedRuleVersion,
    morningAdjustment: 0,
    shortTermAdjustment: 0,
    initialEstimatedEnergy: 100,
    finalEstimatedEnergy: 94,
    totalConsumption: 6,
    totalRecovery: 0,
    categorySummaries: {
      for (final category in ActivityCategory.values)
        category: CategoryEstimatedSummary(
          category: category,
          durationMinutes: category == ActivityCategory.study ? 30 : 0,
          netDelta: category == ActivityCategory.study ? -6 : 0,
          grossDelta: category == ActivityCategory.study ? -6 : 0,
        ),
    },
    isStandardEffectiveDay: false,
    isWeakEffectiveDay: false,
    settledAt: DateTime.utc(day.year, day.month, day.day + 1, 4),
  );
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
