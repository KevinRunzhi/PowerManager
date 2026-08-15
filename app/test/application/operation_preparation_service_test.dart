import 'package:power_manager/application/activity_feedback_use_cases.dart';
import 'package:power_manager/application/activity_use_cases.dart';
import 'package:power_manager/application/business_write_coordinator.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/model_activation_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/settlement_service.dart';
import 'package:power_manager/application/wellbeing_use_cases.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/db/drift_transaction_runner.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/energy/learning_eligibility_service.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/energy/observation_comparison_service.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/life_day/life_day_calculator.dart';
import 'package:power_manager/domain/repositories/repositories.dart';
import 'package:test/test.dart';

import '../data/db/test_database.dart';

void main() {
  late AppDatabase database;
  late MutableClock clock;
  late _Harness harness;

  setUp(() {
    clock = MutableClock(DateTime(2026, 7, 26, 3, 50));
    database = createTestDatabase(clock: clock);
    harness = _Harness(database, clock);
  });

  tearDown(() => database.close());

  test(
    'current projection derives every value from persisted sources',
    () async {
      await harness.summaries.insertOrGet(
        _summary(LifeDay(2026, 7, 24), finalEstimate: -8),
      );
      await harness.mornings.insert(_morning(LifeDay(2026, 7, 25)));
      await harness.activities.insert(
        _activity('later', LifeDay(2026, 7, 25), minute: 30),
      );
      await harness.activities.insert(
        _activity('earlier', LifeDay(2026, 7, 25), minute: 10),
      );

      final result = await harness.prepare(PreparationTrigger.coldStart);

      expect(result.current.lifeDay, LifeDay(2026, 7, 25));
      expect(result.current.previousFinalEstimate, -8);
      expect(result.current.shortTermAdjustment, -2);
      expect(result.current.morningAdjustment, 6);
      expect(result.current.projection.initialEstimate, 104);
      expect(
        result.current.projection.activities.map((item) => item.record.id),
        ['earlier', 'later'],
      );
      expect(result.current.projection.currentEstimate, 94);
    },
  );

  test('first write after crossing 04:00 settles the old life day', () async {
    await harness.activities.insert(
      _activity('before-boundary', LifeDay(2026, 7, 25), minute: 10),
    );
    final opened = await harness.prepare(PreparationTrigger.coldStart);
    expect(opened.current.lifeDay, LifeDay(2026, 7, 25));

    clock.value = DateTime(2026, 7, 26, 4, 10);
    final beforeWrite = await harness.prepare(PreparationTrigger.beforeWrite);

    expect(beforeWrite.current.lifeDay, LifeDay(2026, 7, 26));
    expect(beforeWrite.settledSummaries.single.lifeDay, LifeDay(2026, 7, 25));
    expect(await harness.summaries.list(), hasLength(1));
  });

  test(
    'multi-day settlement is oldest-to-newest and skips empty days',
    () async {
      clock.value = DateTime(2026, 7, 29, 10);
      await harness.mornings.insert(_morning(LifeDay(2026, 7, 25)));
      await harness.activities.insert(
        _activity('day-27', LifeDay(2026, 7, 27), minute: 10),
      );

      final result = await harness.prepare(PreparationTrigger.resumed);

      expect(result.settledSummaries.map((summary) => summary.lifeDay), [
        LifeDay(2026, 7, 25),
        LifeDay(2026, 7, 27),
      ]);
      expect(
        (await harness.summaries.list()).map((summary) => summary.lifeDay),
        [LifeDay(2026, 7, 25), LifeDay(2026, 7, 27)],
      );
    },
  );

  test('ten repeated preparations are idempotent', () async {
    clock.value = DateTime(2026, 7, 26, 10);
    await harness.activities.insert(
      _activity('yesterday', LifeDay(2026, 7, 25), minute: 10),
    );

    for (var index = 0; index < 10; index++) {
      await harness.prepare(PreparationTrigger.resumed);
    }

    expect(await harness.summaries.list(), hasLength(1));
  });

  test('transaction failure leaves no half-written summaries', () async {
    clock.value = DateTime(2026, 7, 28, 10);
    await harness.activities.insert(
      _activity('day-25', LifeDay(2026, 7, 25), minute: 10),
    );
    await harness.activities.insert(
      _activity('day-26', LifeDay(2026, 7, 26), minute: 10),
    );
    final failing = harness.withSummaries(
      _FailOnSecondInsertSummaries(harness.summaries),
    );

    await expectLater(
      failing.prepare(PreparationTrigger.resumed),
      throwsStateError,
    );
    expect(await harness.summaries.list(), isEmpty);
  });

  test(
    'pending base and rule activate on the due life day exactly once',
    () async {
      const nextRule = 'energy-rules-next';
      await harness.rules.insert(
        RuleConfigVersion(
          version: nextRule,
          values: const {'ruleVersion': nextRule},
          createdAt: DateTime.utc(2026, 7, 26),
        ),
      );
      final original = await harness.settings.get();
      await harness.modelActivationService.scheduleManualBaseline(
        baseEnergy: 112,
        currentLifeDay: LifeDay(2026, 7, 25),
        effectiveLifeDay: LifeDay(2026, 7, 26),
        at: clock.now().toUtc(),
        ruleVersion: original.activeRuleVersion,
      );
      final scheduledSettings = await harness.settings.get();
      await harness.settings.save(
        AppSettings(
          activeRuleVersion: scheduledSettings.activeRuleVersion,
          pendingRuleVersion: nextRule,
          pendingRuleEffectiveLifeDay: LifeDay(2026, 7, 26),
          onboardingCompleted: scheduledSettings.onboardingCompleted,
          baselineLearningMode: scheduledSettings.baselineLearningMode,
          activityImpactLearningMode:
              scheduledSettings.activityImpactLearningMode,
          baselineLearningSuspended:
              scheduledSettings.baselineLearningSuspended,
          baselineLearningSuspendedAt:
              scheduledSettings.baselineLearningSuspendedAt,
          baselineLearningSuspensionReason:
              scheduledSettings.baselineLearningSuspensionReason,
          activityImpactLearningSuspended:
              scheduledSettings.activityImpactLearningSuspended,
          activityImpactLearningSuspendedAt:
              scheduledSettings.activityImpactLearningSuspendedAt,
          activityImpactLearningSuspensionReason:
              scheduledSettings.activityImpactLearningSuspensionReason,
          baselineLearningCooldownUntil:
              scheduledSettings.baselineLearningCooldownUntil,
          activityImpactLearningCooldownUntil:
              scheduledSettings.activityImpactLearningCooldownUntil,
          createdAt: scheduledSettings.createdAt,
          updatedAt: scheduledSettings.updatedAt,
        ),
      );

      final beforeDue = await harness.prepare(PreparationTrigger.coldStart);
      expect(beforeDue.current.lifeDay, LifeDay(2026, 7, 25));
      expect(beforeDue.current.baseEstimatedEnergy, 100);
      expect(beforeDue.current.ruleVersion, energyRulesV2MvpAVersion);

      clock.value = DateTime(2026, 7, 26, 4, 1);
      final due = await harness.prepare(PreparationTrigger.beforeWrite);
      final repeated = await harness.prepare(PreparationTrigger.resumed);
      final saved = await harness.settings.get();

      expect(due.appliedPendingBaseEnergy, isTrue);
      expect(due.appliedPendingRuleVersion, isTrue);
      expect(repeated.appliedPendingBaseEnergy, isFalse);
      expect(repeated.appliedPendingRuleVersion, isFalse);
      expect((await harness.versions.getActive()).baseEnergy, 112);
      expect(saved.activeRuleVersion, nextRule);
      expect(await harness.versions.findPending(), isNull);
      expect(saved.pendingRuleVersion, isNull);
    },
  );

  test(
    'late actual-state observation does not mutate an existing summary',
    () async {
      clock.value = DateTime(2026, 7, 26, 10);
      await harness.activities.insert(
        _activity('yesterday', LifeDay(2026, 7, 25), minute: 10),
      );
      await harness.prepare(PreparationTrigger.coldStart);
      final before = await harness.summaries.findByLifeDay(
        LifeDay(2026, 7, 25),
      );

      await harness.observations.insert(
        EnergyObservation(
          id: 'late-observation',
          lifeDay: LifeDay(2026, 7, 25),
          type: EnergyObservationType.dailyAbsolute,
          absoluteState: AbsoluteEnergyState.low,
          relativeState: null,
          estimateAtObservation: null,
          observedAt: DateTime.utc(2026, 7, 26, 3),
        ),
      );
      await harness.prepare(PreparationTrigger.beforeWrite);
      final after = await harness.summaries.findByLifeDay(LifeDay(2026, 7, 25));

      expect(after!.settledAt, before!.settledAt);
      expect(after.finalEstimatedEnergy, before.finalEstimatedEnergy);
    },
  );
  test(
    'all 24 subcategories can be created through the same use case',
    () async {
      clock.value = DateTime(2026, 7, 26, 12);
      final useCases = harness.activityUseCases();
      for (var index = 0; index < ActivitySubcategory.values.length; index++) {
        final subcategory = ActivitySubcategory.values[index];
        await useCases.create(
          ActivityDraft(
            operationId: 'subcategory-${subcategory.code}',
            category: subcategory.category,
            subcategory: subcategory,
            duration: DurationSlot.minutes15,
            completedAt: DateTime(2026, 7, 26, 8, index),
          ),
        );
      }
      expect(
        await harness.activities.listActiveForLifeDay(LifeDay(2026, 7, 26)),
        hasLength(24),
      );
    },
  );

  test(
    'the four other subcategories use their exact configured rules',
    () async {
      clock.value = DateTime(2026, 7, 26, 12);
      final useCases = harness.activityUseCases();
      final others = [
        ActivitySubcategory.otherStudy,
        ActivitySubcategory.otherPractice,
        ActivitySubcategory.otherRecovery,
        ActivitySubcategory.otherLeisure,
      ];
      for (var index = 0; index < others.length; index++) {
        final subcategory = others[index];
        await useCases.create(
          ActivityDraft(
            operationId: 'other-${subcategory.code}',
            category: subcategory.category,
            subcategory: subcategory,
            duration: DurationSlot.minutes15,
            completedAt: DateTime(2026, 7, 26, 9, index),
          ),
        );
      }
      final stored = await harness.activities.listActiveForLifeDay(
        LifeDay(2026, 7, 26),
      );
      expect(stored.map((item) => item.theoreticalDelta), [-5, -5, 5, 0]);
    },
  );

  test(
    'editing the earliest consumption recomputes later recovery cap',
    () async {
      clock.value = DateTime(2026, 7, 26, 12);
      final useCases = harness.activityUseCases();
      await useCases.create(
        ActivityDraft(
          operationId: 'consumption',
          category: ActivityCategory.study,
          subcategory: ActivitySubcategory.classAttendance,
          duration: DurationSlot.minutes60,
          completedAt: DateTime(2026, 7, 26, 8),
        ),
      );
      await useCases.create(
        ActivityDraft(
          operationId: 'recovery',
          category: ActivityCategory.recovery,
          subcategory: ActivitySubcategory.nap,
          duration: DurationSlot.minutes60,
          completedAt: DateTime(2026, 7, 26, 9),
        ),
      );
      expect((await harness.activities.find('recovery'))!.appliedDelta, 12);

      final result = await useCases.edit(
        activityId: 'consumption',
        category: ActivityCategory.study,
        subcategory: ActivitySubcategory.classAttendance,
        duration: DurationSlot.minutes15,
        completedAt: DateTime(2026, 7, 26, 8),
      );
      expect((await harness.activities.find('recovery'))!.appliedDelta, 5);
      expect(result.current.projection.currentEstimate, 100);
    },
  );

  test('duplicate create and repeated delete are idempotent', () async {
    clock.value = DateTime(2026, 7, 26, 12);
    final useCases = harness.activityUseCases();
    final draft = ActivityDraft(
      operationId: 'single-operation',
      category: ActivityCategory.study,
      subcategory: ActivitySubcategory.homework,
      duration: DurationSlot.minutes30,
      completedAt: DateTime(2026, 7, 26, 10),
    );
    final created = await Future.wait([
      useCases.create(draft),
      useCases.create(draft),
    ]);
    final deleted = await Future.wait([
      useCases.delete(draft.operationId),
      useCases.delete(draft.operationId),
    ]);
    expect(created.where((result) => !result.wasAlreadyApplied), hasLength(1));
    expect(deleted.where((result) => !result.wasAlreadyApplied), hasLength(1));
    expect(
      await harness.activities.listActiveForLifeDay(LifeDay(2026, 7, 26)),
      isEmpty,
    );
    expect(
      (await harness.activities.find(draft.operationId))!.status,
      ActivityRecordStatus.deleted,
    );
  });

  test('deleted activity restores its identity and replays the day', () async {
    clock.value = DateTime(2026, 7, 26, 12);
    final useCases = harness.activityUseCases();
    final created = await useCases.create(
      ActivityDraft(
        operationId: 'restore-operation',
        category: ActivityCategory.study,
        subcategory: ActivitySubcategory.homework,
        duration: DurationSlot.minutes30,
        completedAt: DateTime(2026, 7, 26, 10),
      ),
    );
    final estimateAfterCreate = created.current.projection.currentEstimate;
    final deleted = await useCases.delete(created.activity.id);
    expect(
      deleted.current.projection.currentEstimate,
      greaterThan(estimateAfterCreate),
    );

    clock.value = DateTime(2026, 7, 26, 12, 5);
    final restored = await useCases.restore(created.activity.id);
    final stored = (await harness.activities.find(created.activity.id))!;

    expect(restored.wasAlreadyApplied, isFalse);
    expect(restored.current.projection.currentEstimate, estimateAfterCreate);
    expect(stored.status, ActivityRecordStatus.active);
    expect(stored.deletedAt, isNull);
    expect(stored.id, created.activity.id);
    expect(stored.createdAt, created.activity.createdAt);
    expect(stored.completedAt, created.activity.completedAt);
    expect(stored.ruleVersion, created.activity.ruleVersion);
    expect(stored.updatedAt, clock.value.toUtc());

    final repeated = await useCases.restore(created.activity.id);
    expect(repeated.wasAlreadyApplied, isTrue);
    expect(
      await harness.activities.listActiveForLifeDay(LifeDay(2026, 7, 26)),
      hasLength(1),
    );
  });

  test('restore rejects missing and settled-life-day records', () async {
    clock.value = DateTime(2026, 7, 26, 12);
    final useCases = harness.activityUseCases();
    await expectLater(useCases.restore('missing'), throwsStateError);

    final created = await useCases.create(
      ActivityDraft(
        operationId: 'settled-restore',
        category: ActivityCategory.study,
        subcategory: ActivitySubcategory.homework,
        duration: DurationSlot.minutes15,
        completedAt: DateTime(2026, 7, 26, 10),
      ),
    );
    await useCases.delete(created.activity.id);
    clock.value = DateTime(2026, 7, 27, 5);

    await expectLater(useCases.restore(created.activity.id), throwsStateError);
    expect(
      (await harness.activities.find(created.activity.id))!.status,
      ActivityRecordStatus.deleted,
    );
  });

  test(
    'future, cross-life-day, and settled-history edits are rejected',
    () async {
      clock.value = DateTime(2026, 7, 26, 5);
      final useCases = harness.activityUseCases();
      await expectLater(
        useCases.create(
          ActivityDraft(
            operationId: 'future',
            category: ActivityCategory.study,
            subcategory: ActivitySubcategory.homework,
            duration: DurationSlot.minutes15,
            completedAt: DateTime(2026, 7, 26, 6),
          ),
        ),
        throwsArgumentError,
      );
      await expectLater(
        useCases.create(
          ActivityDraft(
            operationId: 'previous-life-day',
            category: ActivityCategory.study,
            subcategory: ActivitySubcategory.homework,
            duration: DurationSlot.minutes15,
            completedAt: DateTime(2026, 7, 26, 3, 30),
          ),
        ),
        throwsStateError,
      );
      await harness.activities.insert(
        _activity('historical', LifeDay(2026, 7, 25), minute: 10),
      );
      await expectLater(
        useCases.edit(
          activityId: 'historical',
          category: ActivityCategory.study,
          subcategory: ActivitySubcategory.homework,
          duration: DurationSlot.minutes30,
          completedAt: DateTime(2026, 7, 25, 8),
        ),
        throwsStateError,
      );
    },
  );
  test(
    'morning context saves but only overall state changes estimate',
    () async {
      clock.value = DateTime(2026, 7, 26, 8);
      final useCases = harness.wellbeingUseCases();
      final badSleep = await useCases.saveMorningCheckIn(
        _morningWith(
          LifeDay(2026, 7, 26),
          overall: MorningOverallState.normal,
          sleep: SleepRecovery.bad,
        ),
      );
      final goodSleep = await useCases.saveMorningCheckIn(
        _morningWith(
          LifeDay(2026, 7, 26),
          overall: MorningOverallState.normal,
          sleep: SleepRecovery.good,
        ),
      );
      final goodOverall = await useCases.saveMorningCheckIn(
        _morningWith(
          LifeDay(2026, 7, 26),
          overall: MorningOverallState.good,
          sleep: SleepRecovery.good,
        ),
      );
      expect(badSleep.projection.initialEstimate, 100);
      expect(goodSleep.projection.initialEstimate, 100);
      expect(goodOverall.projection.initialEstimate, 106);
      final stored = await harness.mornings.findByLifeDay(LifeDay(2026, 7, 26));
      expect(stored!.freeTimeLevel, FreeTimeLevel.medium);
      expect(stored.pressureSource, PressureSource.low);
      expect(stored.sleepRecovery, SleepRecovery.good);
      expect(stored.morningAdjustment, 6);
    },
  );

  test('skipping morning never blocks activity recording', () async {
    clock.value = DateTime(2026, 7, 26, 8);
    await harness.wellbeingUseCases().skipMorning('skip-morning');
    await harness.wellbeingUseCases().skipMorning('skip-morning-duplicate');
    final result = await harness.activityUseCases().create(
      ActivityDraft(
        operationId: 'after-skip',
        category: ActivityCategory.study,
        subcategory: ActivitySubcategory.homework,
        duration: DurationSlot.minutes15,
        completedAt: DateTime(2026, 7, 26, 7),
      ),
    );
    expect(result.current.morningAdjustment, 0);
    expect(result.current.projection.initialEstimate, 100);
    expect(result.current.projection.currentEstimate, 95);
    expect(
      await harness.receipts.exists(
        type: PromptReceiptType.morning,
        scopeKey: '2026-07-26',
        action: PromptReceiptAction.skipped,
      ),
      isTrue,
    );
  });

  test(
    'today daily state updates but yesterday supplement is immutable',
    () async {
      clock.value = DateTime(2026, 7, 26, 8);
      await harness.summaries.insertOrGet(
        _summary(LifeDay(2026, 7, 25), finalEstimate: 70),
      );
      final useCases = harness.wellbeingUseCases();
      final first = await useCases.saveDailyAbsolute(
        observationId: 'today-daily',
        targetLifeDay: LifeDay(2026, 7, 26),
        referenceType: ObservationReferenceType.currentMoment,
        state: AbsoluteEnergyState.low,
        coverageState: ObservationCoverageState.confirmed,
      );
      final updated = await useCases.saveDailyAbsolute(
        observationId: 'ignored-id',
        targetLifeDay: LifeDay(2026, 7, 26),
        referenceType: ObservationReferenceType.currentMoment,
        state: AbsoluteEnergyState.good,
        coverageState: ObservationCoverageState.uncertain,
      );
      final yesterday = await useCases.saveDailyAbsolute(
        observationId: 'yesterday-daily',
        targetLifeDay: LifeDay(2026, 7, 25),
        referenceType: ObservationReferenceType.previousLifeDayEnd,
        state: AbsoluteEnergyState.exhausted,
        coverageState: ObservationCoverageState.confirmed,
      );
      expect(first.wasUpdated, isFalse);
      expect(updated.wasUpdated, isTrue);
      expect(updated.observation.id, 'today-daily');
      expect(yesterday.systemEstimate, 70);
      expect(
        await harness.observations.listForLifeDay(LifeDay(2026, 7, 26)),
        hasLength(1),
      );
      await expectLater(
        useCases.saveDailyAbsolute(
          observationId: 'second-yesterday',
          targetLifeDay: LifeDay(2026, 7, 25),
          referenceType: ObservationReferenceType.previousLifeDayEnd,
          state: AbsoluteEnergyState.full,
          coverageState: ObservationCoverageState.confirmed,
        ),
        throwsStateError,
      );
      expect(
        (await harness.summaries.findByLifeDay(
          LifeDay(2026, 7, 25),
        ))!.finalEstimatedEnergy,
        70,
      );
    },
  );

  test(
    'current observation freezes a complete v1 contract and becomes eligible after settlement',
    () async {
      clock.value = DateTime(2026, 7, 26, 8);
      await harness.wellbeingUseCases().saveMorningCheckIn(
        _morningWith(
          LifeDay(2026, 7, 26),
          overall: MorningOverallState.good,
          sleep: SleepRecovery.good,
        ),
      );
      await harness.activityUseCases().create(
        ActivityDraft(
          operationId: 'contract-activity',
          category: ActivityCategory.study,
          subcategory: ActivitySubcategory.homework,
          duration: DurationSlot.minutes30,
          completedAt: DateTime(2026, 7, 26, 7),
        ),
      );
      clock.value = DateTime(2026, 7, 26, 12);

      final result = await harness.wellbeingUseCases().saveDailyAbsolute(
        observationId: 'contract-current',
        targetLifeDay: LifeDay(2026, 7, 26),
        referenceType: ObservationReferenceType.currentMoment,
        state: AbsoluteEnergyState.good,
        coverageState: ObservationCoverageState.confirmed,
      );
      final observation = result.observation;
      final expectedKey = const ModelRegimeKeyBuilder().build(
        referenceType: ObservationReferenceType.currentMoment,
        baseEnergy: 100,
        ruleVersion: energyRulesV2MvpAVersion,
        comparisonBandVersion: mvpBComparisonBandV1,
        effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
        modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
      );

      expect(observation.contractVersion, mvpBObservationContractV1);
      expect(observation.referenceType, ObservationReferenceType.currentMoment);
      expect(observation.estimateAtObservation, 98);
      expect(observation.initialEstimateAtObservation, 106);
      expect(observation.estimatedOrdinalAtObservation, 4);
      expect(observation.baseEnergyAtObservation, 100);
      expect(observation.ruleVersionAtObservation, energyRulesV2MvpAVersion);
      expect(observation.comparisonBandVersion, mvpBComparisonBandV1);
      expect(
        observation.personalizationVersionAtObservation,
        (await harness.versions.getActive()).id,
      );
      expect(
        observation.effectiveModelFingerprintAtObservation,
        fixedMvpAEffectiveModelFingerprint,
      );
      expect(
        observation.modelRegimeEpochAtObservation,
        fixedMvpAInitialModelRegimeEpoch,
      );
      expect(observation.activeActivityCountAtObservation, 1);
      expect(observation.coverageState, ObservationCoverageState.confirmed);
      expect(observation.modelRegimeKey, expectedKey);
      expect(observation.observedAt, DateTime(2026, 7, 26, 12).toUtc());

      final eligibilityService = const LearningEligibilityService();
      final beforeSettlement = eligibilityService.evaluate(
        observation: observation,
        hasMorningCheckIn: true,
        settled: false,
        expectedModelRegimeKey: expectedKey,
      );
      expect(beforeSettlement.eligible, isFalse);
      expect(beforeSettlement.reasonCodes, [
        LearningIneligibilityReason.unsettledLifeDay,
      ]);

      clock.value = DateTime(2026, 7, 27, 5);
      await harness.prepare(PreparationTrigger.lifeDayBoundary);
      final afterSettlement = eligibilityService.evaluate(
        observation: observation,
        hasMorningCheckIn: true,
        settled:
            await harness.summaries.findByLifeDay(LifeDay(2026, 7, 26)) != null,
        expectedModelRegimeKey: expectedKey,
      );
      expect(afterSettlement.eligible, isTrue);
      expect(afterSettlement.reasonCodes, isEmpty);
    },
  );

  test(
    'yesterday observation uses immutable summary context and current capture time',
    () async {
      final yesterday = LifeDay(2026, 7, 25);
      await harness.summaries.insertOrGet(
        _summary(yesterday, finalEstimate: 70),
      );
      await harness.activities.insert(
        _activity('yesterday-active', yesterday, minute: 10),
      );
      clock.value = DateTime(2026, 7, 26, 13, 30);

      final result = await harness.wellbeingUseCases().saveDailyAbsolute(
        observationId: 'yesterday-contract',
        targetLifeDay: yesterday,
        referenceType: ObservationReferenceType.previousLifeDayEnd,
        state: AbsoluteEnergyState.low,
        coverageState: ObservationCoverageState.confirmed,
      );

      expect(result.systemEstimate, 70);
      expect(result.observation.lifeDay, yesterday);
      expect(
        result.observation.referenceType,
        ObservationReferenceType.previousLifeDayEnd,
      );
      expect(result.observation.initialEstimateAtObservation, 100);
      expect(result.observation.baseEnergyAtObservation, 100);
      expect(
        result.observation.ruleVersionAtObservation,
        energyRulesV2MvpAVersion,
      );
      expect(result.observation.activeActivityCountAtObservation, 1);
      expect(
        result.observation.observedAt,
        DateTime(2026, 7, 26, 13, 30).toUtc(),
      );
    },
  );

  test(
    'a current-moment sheet crossing 04:00 is rejected atomically',
    () async {
      clock.value = DateTime(2026, 7, 26, 3, 59, 59);
      await harness.activityUseCases().create(
        ActivityDraft(
          operationId: 'before-boundary',
          category: ActivityCategory.study,
          subcategory: ActivitySubcategory.homework,
          duration: DurationSlot.minutes15,
          completedAt: DateTime(2026, 7, 25, 22),
        ),
      );
      clock.value = DateTime(2026, 7, 26, 4);

      await expectLater(
        harness.wellbeingUseCases().saveDailyAbsolute(
          observationId: 'stale-current-sheet',
          targetLifeDay: LifeDay(2026, 7, 25),
          referenceType: ObservationReferenceType.currentMoment,
          state: AbsoluteEnergyState.okay,
          coverageState: ObservationCoverageState.confirmed,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'staleSheet',
          ),
        ),
      );
      expect(await harness.observations.find('stale-current-sheet'), isNull);
      expect(
        await harness.summaries.findByLifeDay(LifeDay(2026, 7, 25)),
        isNull,
      );
    },
  );

  test('observation insert failure rolls back the complete record', () async {
    clock.value = DateTime(2026, 7, 26, 12);
    final failing = _InsertThenFailObservations(harness.observations);

    await expectLater(
      harness
          .wellbeingUseCases(observationsOverride: failing)
          .saveDailyAbsolute(
            observationId: 'rollback-observation',
            targetLifeDay: LifeDay(2026, 7, 26),
            referenceType: ObservationReferenceType.currentMoment,
            state: AbsoluteEnergyState.okay,
            coverageState: ObservationCoverageState.confirmed,
          ),
      throwsStateError,
    );
    expect(await harness.observations.find('rollback-observation'), isNull);
  });

  test('activity feedback saves and replaces one frozen active row', () async {
    clock.value = DateTime(2026, 7, 26, 12);
    final activity = (await harness.activityUseCases().create(
      ActivityDraft(
        operationId: 'feedback-activity',
        category: ActivityCategory.study,
        subcategory: ActivitySubcategory.homework,
        duration: DurationSlot.minutes30,
        completedAt: DateTime(2026, 7, 26, 10),
      ),
    )).activity;
    final useCases = harness.activityFeedbackUseCases();
    final first = await useCases.save(
      feedbackId: 'feedback-first',
      activityId: activity.id,
      expectedActivityUpdatedAt: activity.updatedAt,
      direction: ActivityFeedbackDirection.strongerImpact,
    );
    clock.value = DateTime(2026, 7, 26, 12, 5);
    final second = await useCases.save(
      feedbackId: 'feedback-ignored',
      activityId: activity.id,
      expectedActivityUpdatedAt: activity.updatedAt,
      direction: ActivityFeedbackDirection.aboutRight,
    );

    expect(first.wasUpdated, isFalse);
    expect(second.wasUpdated, isTrue);
    expect(second.feedback.id, 'feedback-first');
    expect(second.feedback.lifeDay, activity.lifeDay);
    expect(second.feedback.subcategorySnapshot, activity.subcategory);
    expect(second.feedback.durationSnapshot, activity.duration);
    expect(second.feedback.theoreticalDeltaSnapshot, activity.theoreticalDelta);
    expect(second.feedback.appliedDeltaSnapshot, activity.appliedDelta);
    expect(second.feedback.impactSignSnapshot, ActivityImpactSign.consumption);
    expect(second.feedback.ruleVersionSnapshot, activity.ruleVersion);
    expect(second.feedback.activityUpdatedAtSnapshot, activity.updatedAt);
    expect(second.feedback.status, ActivityFeedbackStatus.active);
    expect(second.feedback.invalidationReason, isNull);
    expect(await harness.feedback.listForActivity(activity.id), hasLength(1));
  });

  test('no-op edit preserves activity version and active feedback', () async {
    clock.value = DateTime(2026, 7, 26, 12);
    final activity = (await harness.activityUseCases().create(
      ActivityDraft(
        operationId: 'no-op-feedback',
        category: ActivityCategory.study,
        subcategory: ActivitySubcategory.homework,
        duration: DurationSlot.minutes30,
        completedAt: DateTime(2026, 7, 26, 10),
      ),
    )).activity;
    await harness.activityFeedbackUseCases().save(
      feedbackId: 'no-op-feedback-row',
      activityId: activity.id,
      expectedActivityUpdatedAt: activity.updatedAt,
      direction: ActivityFeedbackDirection.aboutRight,
    );
    clock.value = DateTime(2026, 7, 26, 13);

    final result = await harness.activityUseCases().edit(
      activityId: activity.id,
      category: activity.category,
      subcategory: activity.subcategory,
      duration: activity.duration,
      completedAt: activity.completedAt,
    );

    expect(result.wasAlreadyApplied, isTrue);
    expect(result.activity.updatedAt, activity.updatedAt);
    expect(
      await harness.feedback.findActiveForActivity(activity.id),
      isNotNull,
    );
  });

  test(
    'subcategory duration and completion edits invalidate each active feedback',
    () async {
      clock.value = DateTime(2026, 7, 26, 12);
      var activity = (await harness.activityUseCases().create(
        ActivityDraft(
          operationId: 'edited-feedback',
          category: ActivityCategory.study,
          subcategory: ActivitySubcategory.homework,
          duration: DurationSlot.minutes30,
          completedAt: DateTime(2026, 7, 26, 10),
        ),
      )).activity;
      final feedbackUseCases = harness.activityFeedbackUseCases();

      await feedbackUseCases.save(
        feedbackId: 'edited-feedback-subcategory',
        activityId: activity.id,
        expectedActivityUpdatedAt: activity.updatedAt,
        direction: ActivityFeedbackDirection.aboutRight,
      );
      activity = (await harness.activityUseCases().edit(
        activityId: activity.id,
        category: ActivityCategory.study,
        subcategory: ActivitySubcategory.selfStudyOrThesis,
        duration: activity.duration,
        completedAt: activity.completedAt,
      )).activity;
      await feedbackUseCases.save(
        feedbackId: 'edited-feedback-duration',
        activityId: activity.id,
        expectedActivityUpdatedAt: activity.updatedAt,
        direction: ActivityFeedbackDirection.weakerImpact,
      );
      activity = (await harness.activityUseCases().edit(
        activityId: activity.id,
        category: activity.category,
        subcategory: activity.subcategory,
        duration: DurationSlot.minutes45,
        completedAt: activity.completedAt,
      )).activity;
      await feedbackUseCases.save(
        feedbackId: 'edited-feedback-completion',
        activityId: activity.id,
        expectedActivityUpdatedAt: activity.updatedAt,
        direction: ActivityFeedbackDirection.strongerImpact,
      );
      activity = (await harness.activityUseCases().edit(
        activityId: activity.id,
        category: activity.category,
        subcategory: activity.subcategory,
        duration: activity.duration,
        completedAt: DateTime(2026, 7, 26, 10, 30),
      )).activity;

      final rows = await harness.feedback.listForActivity(activity.id);
      expect(rows, hasLength(3));
      expect(
        rows.map((item) => item.status),
        everyElement(ActivityFeedbackStatus.invalidated),
      );
      expect(
        rows.map((item) => item.invalidationReason),
        everyElement(ActivityFeedbackInvalidationReason.activityEdited),
      );
      expect(await harness.feedback.findActiveForActivity(activity.id), isNull);
    },
  );

  test(
    'another activity replay invalidates feedback and advances stale version',
    () async {
      clock.value = DateTime(2026, 7, 26, 12);
      final activities = harness.activityUseCases();
      final consumption = (await activities.create(
        ActivityDraft(
          operationId: 'feedback-consumption',
          category: ActivityCategory.study,
          subcategory: ActivitySubcategory.classAttendance,
          duration: DurationSlot.minutes60,
          completedAt: DateTime(2026, 7, 26, 8),
        ),
      )).activity;
      final recovery = (await activities.create(
        ActivityDraft(
          operationId: 'feedback-recovery',
          category: ActivityCategory.recovery,
          subcategory: ActivitySubcategory.nap,
          duration: DurationSlot.minutes60,
          completedAt: DateTime(2026, 7, 26, 9),
        ),
      )).activity;
      await harness.activityFeedbackUseCases().save(
        feedbackId: 'recovery-feedback',
        activityId: recovery.id,
        expectedActivityUpdatedAt: recovery.updatedAt,
        direction: ActivityFeedbackDirection.aboutRight,
      );
      clock.value = DateTime(2026, 7, 26, 12, 30);

      await activities.edit(
        activityId: consumption.id,
        category: consumption.category,
        subcategory: consumption.subcategory,
        duration: DurationSlot.minutes15,
        completedAt: consumption.completedAt,
      );
      final changedRecovery = (await harness.activities.find(recovery.id))!;
      final oldFeedback = (await harness.feedback.listForActivity(
        recovery.id,
      )).single;

      expect(changedRecovery.appliedDelta, 5);
      expect(changedRecovery.updatedAt.isAfter(recovery.updatedAt), isTrue);
      expect(oldFeedback.status, ActivityFeedbackStatus.invalidated);
      expect(
        oldFeedback.invalidationReason,
        ActivityFeedbackInvalidationReason.activityEdited,
      );
      await expectLater(
        harness.activityFeedbackUseCases().save(
          feedbackId: 'stale-recovery-feedback',
          activityId: recovery.id,
          expectedActivityUpdatedAt: recovery.updatedAt,
          direction: ActivityFeedbackDirection.aboutRight,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'staleActivity',
          ),
        ),
      );
    },
  );

  test('delete invalidates feedback and restore never revives it', () async {
    clock.value = DateTime(2026, 7, 26, 12);
    final activity = (await harness.activityUseCases().create(
      ActivityDraft(
        operationId: 'deleted-feedback',
        category: ActivityCategory.study,
        subcategory: ActivitySubcategory.homework,
        duration: DurationSlot.minutes30,
        completedAt: DateTime(2026, 7, 26, 10),
      ),
    )).activity;
    await harness.activityFeedbackUseCases().save(
      feedbackId: 'deleted-feedback-row',
      activityId: activity.id,
      expectedActivityUpdatedAt: activity.updatedAt,
      direction: ActivityFeedbackDirection.aboutRight,
    );

    await harness.activityUseCases().delete(activity.id);
    await harness.activityUseCases().restore(activity.id);
    final stored = (await harness.feedback.listForActivity(activity.id)).single;

    expect(stored.status, ActivityFeedbackStatus.invalidated);
    expect(
      stored.invalidationReason,
      ActivityFeedbackInvalidationReason.activityDeleted,
    );
    expect(await harness.feedback.findActiveForActivity(activity.id), isNull);
  });

  test(
    'feedback insert failure rolls back and never changes activity',
    () async {
      clock.value = DateTime(2026, 7, 26, 12);
      final activity = (await harness.activityUseCases().create(
        ActivityDraft(
          operationId: 'feedback-rollback',
          category: ActivityCategory.study,
          subcategory: ActivitySubcategory.homework,
          duration: DurationSlot.minutes30,
          completedAt: DateTime(2026, 7, 26, 10),
        ),
      )).activity;
      final failing = _InsertThenFailFeedback(harness.feedback);

      await expectLater(
        harness
            .activityFeedbackUseCases(feedbackOverride: failing)
            .save(
              feedbackId: 'feedback-rollback-row',
              activityId: activity.id,
              expectedActivityUpdatedAt: activity.updatedAt,
              direction: ActivityFeedbackDirection.aboutRight,
            ),
        throwsStateError,
      );

      expect(await harness.feedback.find('feedback-rollback-row'), isNull);
      final unchanged = (await harness.activities.find(activity.id))!;
      expect(unchanged.updatedAt, activity.updatedAt);
      expect(unchanged.subcategory, activity.subcategory);
      expect(unchanged.duration, activity.duration);
      expect(unchanged.appliedDelta, activity.appliedDelta);
      expect(unchanged.status, ActivityRecordStatus.active);
    },
  );

  test('relative correction snapshots estimate without changing it', () async {
    clock.value = DateTime(2026, 7, 26, 8);
    await harness.activityUseCases().create(
      ActivityDraft(
        operationId: 'before-correction',
        category: ActivityCategory.study,
        subcategory: ActivitySubcategory.homework,
        duration: DurationSlot.minutes30,
        completedAt: DateTime(2026, 7, 26, 7),
      ),
    );
    final before = await harness.prepare(PreparationTrigger.resumed);
    final observation = await harness
        .wellbeingUseCases()
        .saveRelativeCorrection(
          observationId: 'relative-1',
          correction: RelativeCorrection.lowerThanEstimate,
        );
    final after = await harness.prepare(PreparationTrigger.resumed);
    expect(observation.estimateAtObservation, 92);
    expect(observation.relativeState, RelativeCorrection.lowerThanEstimate);
    expect(
      after.current.projection.currentEstimate,
      before.current.projection.currentEstimate,
    );
  });

  test('alignment descriptions do not invent an actual numeric value', () {
    expect(
      describeAlignment(ObservationAlignmentDirection.lower),
      contains('低于'),
    );
    expect(
      describeAlignment(ObservationAlignmentDirection.aligned),
      contains('相同档位'),
    );
  });
}

final class MutableClock implements Clock {
  MutableClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

final class _Harness {
  _Harness(
    this.database,
    this.clock, [
    DailySummariesRepository? summaryOverride,
  ]) : settings = DriftAppSettingsRepository(database.appSettingsDao),
       rules = DriftRuleConfigVersionsRepository(
         database.ruleConfigVersionsDao,
       ),
       mornings = DriftMorningCheckInsRepository(database.morningCheckInsDao),
       activities = DriftActivityRecordsRepository(database.activityRecordsDao),
       observations = DriftEnergyObservationsRepository(
         database.energyObservationsDao,
       ),
       feedback = DriftActivityFeedbackRepository(database.activityFeedbackDao),
       learningRuns = DriftLearningRunsRepository(database.learningRunsDao),
       versions = DriftPersonalizationVersionsRepository(
         database.personalizationVersionsDao,
       ),
       consents = DriftLearningConsentsRepository(database.learningConsentsDao),
       notices = DriftLearningNoticesRepository(database.learningNoticesDao),
       receipts = DriftPromptReceiptsRepository(database.promptReceiptsDao),
       writeCoordinator = SerialBusinessWriteCoordinator(),
       summaries =
           summaryOverride ??
           DriftDailySummariesRepository(database.dailySummariesDao);

  final AppDatabase database;
  final MutableClock clock;
  final DriftAppSettingsRepository settings;
  final DriftRuleConfigVersionsRepository rules;
  final DriftMorningCheckInsRepository mornings;
  final DriftActivityRecordsRepository activities;
  final DriftEnergyObservationsRepository observations;
  final DriftActivityFeedbackRepository feedback;
  final DriftLearningRunsRepository learningRuns;
  final DriftPersonalizationVersionsRepository versions;
  final DriftLearningConsentsRepository consents;
  final DriftLearningNoticesRepository notices;
  final DriftPromptReceiptsRepository receipts;
  final DailySummariesRepository summaries;
  final BusinessWriteCoordinator writeCoordinator;

  ActivityFeedbackMaintenance get feedbackMaintenance =>
      ActivityFeedbackMaintenance(feedback);

  ModelActivationService get modelActivationService => ModelActivationService(
    transactionRunner: DriftTransactionRunner(database),
    settings: settings,
    versions: versions,
    learningRuns: learningRuns,
    consents: consents,
    notices: notices,
  );

  _Harness withSummaries(DailySummariesRepository replacement) {
    return _Harness(database, clock, replacement);
  }

  Future<OperationPreparationResult> prepare(PreparationTrigger trigger) {
    final projection = CurrentDayProjectionService(
      morningCheckIns: mornings,
      activities: activities,
      summaries: summaries,
    );
    return OperationPreparationService(
      clock: clock,
      lifeDayCalculator: LifeDayCalculator(),
      transactionRunner: DriftTransactionRunner(database),
      settings: settings,
      personalizationVersions: versions,
      modelActivationService: modelActivationService,
      settlementService: SettlementService(
        morningCheckIns: mornings,
        activities: activities,
        observations: observations,
        summaries: summaries,
        projectionService: projection,
      ),
      projectionService: projection,
    ).prepare(trigger);
  }

  ActivityUseCases activityUseCases() {
    final projection = CurrentDayProjectionService(
      morningCheckIns: mornings,
      activities: activities,
      summaries: summaries,
    );
    final preparer = OperationPreparationService(
      clock: clock,
      lifeDayCalculator: LifeDayCalculator(),
      transactionRunner: DriftTransactionRunner(database),
      settings: settings,
      personalizationVersions: versions,
      modelActivationService: modelActivationService,
      settlementService: SettlementService(
        morningCheckIns: mornings,
        activities: activities,
        observations: observations,
        summaries: summaries,
        projectionService: projection,
      ),
      projectionService: projection,
    );
    return ActivityUseCases(
      lifeDayCalculator: LifeDayCalculator(),
      writeCoordinator: writeCoordinator,
      transactionRunner: DriftTransactionRunner(database),
      preparer: preparer,
      activities: activities,
      rules: rules,
      summaries: summaries,
      projectionService: projection,
      feedbackMaintenance: feedbackMaintenance,
    );
  }

  ActivityFeedbackUseCases activityFeedbackUseCases({
    ActivityFeedbackRepository? feedbackOverride,
  }) {
    final projection = CurrentDayProjectionService(
      morningCheckIns: mornings,
      activities: activities,
      summaries: summaries,
    );
    final preparer = OperationPreparationService(
      clock: clock,
      lifeDayCalculator: LifeDayCalculator(),
      transactionRunner: DriftTransactionRunner(database),
      settings: settings,
      personalizationVersions: versions,
      modelActivationService: modelActivationService,
      settlementService: SettlementService(
        morningCheckIns: mornings,
        activities: activities,
        observations: observations,
        summaries: summaries,
        projectionService: projection,
      ),
      projectionService: projection,
    );
    return ActivityFeedbackUseCases(
      writeCoordinator: writeCoordinator,
      transactionRunner: DriftTransactionRunner(database),
      preparer: preparer,
      activities: activities,
      feedback: feedbackOverride ?? feedback,
      rules: rules,
      summaries: summaries,
    );
  }

  WellbeingUseCases wellbeingUseCases({
    EnergyObservationsRepository? observationsOverride,
  }) {
    final selectedObservations = observationsOverride ?? observations;
    final projection = CurrentDayProjectionService(
      morningCheckIns: mornings,
      activities: activities,
      summaries: summaries,
    );
    final preparer = OperationPreparationService(
      clock: clock,
      lifeDayCalculator: LifeDayCalculator(),
      transactionRunner: DriftTransactionRunner(database),
      settings: settings,
      personalizationVersions: versions,
      modelActivationService: modelActivationService,
      settlementService: SettlementService(
        morningCheckIns: mornings,
        activities: activities,
        observations: selectedObservations,
        summaries: summaries,
        projectionService: projection,
      ),
      projectionService: projection,
    );
    return WellbeingUseCases(
      writeCoordinator: writeCoordinator,
      transactionRunner: DriftTransactionRunner(database),
      preparer: preparer,
      mornings: mornings,
      activities: activities,
      observations: selectedObservations,
      personalizationVersions: versions,
      summaries: summaries,
      receipts: receipts,
      projectionService: projection,
      feedbackMaintenance: feedbackMaintenance,
    );
  }
}

final class _FailOnSecondInsertSummaries implements DailySummariesRepository {
  _FailOnSecondInsertSummaries(this.delegate);

  final DailySummariesRepository delegate;
  var insertCount = 0;

  @override
  Future<DailySummary?> findByLifeDay(LifeDay lifeDay) {
    return delegate.findByLifeDay(lifeDay);
  }

  @override
  Future<DailySummary> insertOrGet(DailySummary summary) {
    insertCount++;
    if (insertCount == 2) {
      throw StateError('simulated settlement failure');
    }
    return delegate.insertOrGet(summary);
  }

  @override
  Future<List<DailySummary>> list() => delegate.list();
}

final class _InsertThenFailObservations
    implements EnergyObservationsRepository {
  const _InsertThenFailObservations(this.delegate);

  final EnergyObservationsRepository delegate;

  @override
  Future<void> insert(EnergyObservation observation) async {
    await delegate.insert(observation);
    throw StateError('simulated observation insert failure');
  }

  @override
  Future<void> update(EnergyObservation observation) =>
      delegate.update(observation);

  @override
  Future<EnergyObservation?> find(String id) => delegate.find(id);

  @override
  Future<List<EnergyObservation>> list() => delegate.list();

  @override
  Future<List<EnergyObservation>> listForLifeDay(LifeDay lifeDay) =>
      delegate.listForLifeDay(lifeDay);
}

final class _InsertThenFailFeedback implements ActivityFeedbackRepository {
  const _InsertThenFailFeedback(this.delegate);

  final ActivityFeedbackRepository delegate;

  @override
  Future<void> insert(ActivityFeedback feedback) async {
    await delegate.insert(feedback);
    throw StateError('simulated feedback insert failure');
  }

  @override
  Future<void> update(ActivityFeedback feedback) => delegate.update(feedback);

  @override
  Future<ActivityFeedback?> find(String id) => delegate.find(id);

  @override
  Future<ActivityFeedback?> findActiveForActivity(String activityRecordId) =>
      delegate.findActiveForActivity(activityRecordId);

  @override
  Future<List<ActivityFeedback>> list() => delegate.list();

  @override
  Future<List<ActivityFeedback>> listForActivity(String activityRecordId) =>
      delegate.listForActivity(activityRecordId);
}

MorningCheckIn _morning(LifeDay day) {
  return MorningCheckIn(
    id: 'morning-$day',
    lifeDay: day,
    overallState: MorningOverallState.good,
    freeTimeLevel: FreeTimeLevel.medium,
    pressureSource: PressureSource.low,
    sleepRecovery: SleepRecovery.good,
    morningAdjustment: 6,
    completedAt: DateTime.utc(day.year, day.month, day.day, 5),
  );
}

MorningCheckIn _morningWith(
  LifeDay day, {
  required MorningOverallState overall,
  required SleepRecovery sleep,
}) {
  return MorningCheckIn(
    id: 'morning-$day',
    lifeDay: day,
    overallState: overall,
    freeTimeLevel: FreeTimeLevel.medium,
    pressureSource: PressureSource.low,
    sleepRecovery: sleep,
    morningAdjustment: overall.adjustment,
    completedAt: DateTime.utc(day.year, day.month, day.day, 5),
  );
}

StoredEstimatedActivity _activity(
  String id,
  LifeDay day, {
  required int minute,
}) {
  final completedAt = DateTime.utc(day.year, day.month, day.day, 8, minute);
  return StoredEstimatedActivity(
    id: id,
    lifeDay: day,
    completedAt: completedAt,
    createdAt: completedAt.add(const Duration(minutes: 1)),
    updatedAt: completedAt.add(const Duration(minutes: 1)),
    category: ActivityCategory.study,
    subcategory: ActivitySubcategory.classAttendance,
    duration: DurationSlot.minutes15,
    theoreticalDelta: -5,
    appliedDelta: -5,
    ruleVersion: energyRulesV2MvpAVersion,
    status: ActivityRecordStatus.active,
    deletedAt: null,
  );
}

DailySummary _summary(LifeDay day, {required int finalEstimate}) {
  return DailySummary(
    lifeDay: day,
    baseEstimatedEnergy: 100,
    ruleVersion: energyRulesV2MvpAVersion,
    morningAdjustment: 0,
    shortTermAdjustment: 0,
    initialEstimatedEnergy: 100,
    finalEstimatedEnergy: finalEstimate,
    totalConsumption: finalEstimate < 100 ? 100 - finalEstimate : 0,
    totalRecovery: finalEstimate > 100 ? finalEstimate - 100 : 0,
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
  );
}
