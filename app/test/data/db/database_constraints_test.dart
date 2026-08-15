import 'package:drift/drift.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

import '../../support/backup_fixture.dart';
import 'test_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  test('morning lifeDay is unique and adjustment must match state', () async {
    final repository = DriftMorningCheckInsRepository(
      MorningCheckInsDao(database),
    );
    await repository.insert(_checkIn(id: 'morning-1'));

    await expectLater(
      repository.insert(_checkIn(id: 'morning-2')),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database
          .into(database.morningCheckInsTable)
          .insert(
            MorningCheckInsTableCompanion.insert(
              id: 'wrong-adjustment',
              lifeDay: LifeDay(2026, 7, 27),
              overallState: MorningOverallState.good,
              freeTimeLevel: FreeTimeLevel.medium,
              pressureSource: PressureSource.low,
              sleepRecovery: SleepRecovery.normal,
              morningAdjustment: -6,
              completedAt: testNow,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('only one daily absolute observation exists per lifeDay', () async {
    final repository = DriftEnergyObservationsRepository(
      EnergyObservationsDao(database),
    );
    await repository.insert(_dailyObservation(id: 'daily-1'));

    await expectLater(
      repository.insert(_dailyObservation(id: 'daily-2')),
      throwsA(isA<Exception>()),
    );
    await repository.insert(_relativeObservation(id: 'relative-1'));
    await repository.insert(_relativeObservation(id: 'relative-2'));

    expect(await repository.listForLifeDay(LifeDay(2026, 7, 26)), hasLength(3));
  });

  test('observation type-specific fields are enforced', () async {
    await expectLater(
      database
          .into(database.energyObservationsTable)
          .insert(
            EnergyObservationsTableCompanion.insert(
              id: 'invalid-relative',
              lifeDay: LifeDay(2026, 7, 26),
              type: EnergyObservationType.relativeCorrection,
              relativeState: const Value(RelativeCorrection.aboutRight),
              estimateAtObservation: const Value.absent(),
              observedAt: testNow,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test(
    'schema v2 observation contract is complete or explicitly legacy',
    () async {
      final repository = DriftEnergyObservationsRepository(
        EnergyObservationsDao(database),
      );
      await database.appSettingsDao.getSettings();
      await repository.insert(_contractObservation(id: 'contract-valid'));

      final stored = await repository.find('contract-valid');
      expect(stored!.contractVersion, mvpBObservationContractV1);
      expect(stored.referenceType, ObservationReferenceType.currentMoment);
      expect(stored.coverageState, ObservationCoverageState.confirmed);

      await expectLater(
        database
            .into(database.energyObservationsTable)
            .insert(
              EnergyObservationsTableCompanion.insert(
                id: 'contract-incomplete',
                lifeDay: LifeDay(2026, 7, 27),
                type: EnergyObservationType.dailyAbsolute,
                absoluteState: const Value(AbsoluteEnergyState.good),
                estimateAtObservation: const Value(80),
                contractVersion: const Value(mvpBObservationContractV1),
                referenceType: const Value(
                  ObservationReferenceType.currentMoment,
                ),
                observedAt: testNow,
              ),
            ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        database.customStatement(
          '''
        INSERT INTO energy_observations (
          id, life_day, type, absolute_state, relative_state,
          estimate_at_observation, contract_version, coverage_state, observed_at
        ) VALUES (?, ?, ?, ?, NULL, ?, NULL, ?, ?)
      ''',
          [
            'legacy-with-confirmed-coverage',
            '2026-07-28',
            'dailyAbsolute',
            'good',
            80,
            'confirmed',
            testNow.millisecondsSinceEpoch ~/ 1000,
          ],
        ),
        throwsA(isA<Exception>()),
      );
    },
  );

  test(
    'activity feedback enforces snapshots, state shape, FK, and one active',
    () async {
      await database.appSettingsDao.getSettings();
      final activities = DriftActivityRecordsRepository(
        ActivityRecordsDao(database),
      );
      final feedback = DriftActivityFeedbackRepository(
        ActivityFeedbackDao(database),
      );
      final activity = _feedbackActivity();
      await activities.insert(activity);
      await feedback.insert(
        _feedback(id: 'feedback-active', activity: activity),
      );

      await expectLater(
        feedback.insert(
          _feedback(id: 'feedback-duplicate', activity: activity),
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        feedback.insert(
          _feedback(
            id: 'feedback-wrong-sign',
            activity: activity,
            impactSign: ActivityImpactSign.recovery,
          ),
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        feedback.insert(
          _feedback(
            id: 'feedback-invalid-state',
            activity: activity,
            status: ActivityFeedbackStatus.invalidated,
          ),
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        database.customStatement(
          "DELETE FROM activity_records WHERE id = 'feedback-activity'",
        ),
        throwsA(isA<Exception>()),
      );

      final original = (await feedback.find('feedback-active'))!;
      await feedback.update(
        ActivityFeedback(
          id: original.id,
          activityRecordId: original.activityRecordId,
          lifeDay: original.lifeDay,
          subcategorySnapshot: original.subcategorySnapshot,
          durationSnapshot: original.durationSnapshot,
          theoreticalDeltaSnapshot: original.theoreticalDeltaSnapshot,
          appliedDeltaSnapshot: original.appliedDeltaSnapshot,
          impactSignSnapshot: original.impactSignSnapshot,
          ruleVersionSnapshot: original.ruleVersionSnapshot,
          activityUpdatedAtSnapshot: original.activityUpdatedAtSnapshot,
          direction: original.direction,
          status: ActivityFeedbackStatus.invalidated,
          invalidationReason: ActivityFeedbackInvalidationReason.activityEdited,
          observedAt: original.observedAt,
        ),
      );
      await feedback.insert(
        _feedback(id: 'feedback-replacement', activity: activity),
      );
      expect(await feedback.listForActivity(activity.id), hasLength(2));
    },
  );

  test(
    'activity duration, status, category pairing, and rule FK are enforced',
    () async {
      final unixSeconds = testNow.millisecondsSinceEpoch ~/ 1000;
      const insertSql = '''
      INSERT INTO activity_records (
        id, life_day, completed_at, created_at, updated_at,
        category, subcategory, duration_minutes,
        theoretical_delta, applied_delta, rule_version, status, deleted_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''';

      Future<void> rawInsert({
        required String id,
        String category = 'study',
        String subcategory = 'classAttendance',
        int duration = 15,
        String ruleVersion = energyRulesV2MvpAVersion,
        String status = 'active',
        int? deletedAt,
      }) {
        return database.customStatement(insertSql, [
          id,
          '2026-07-26',
          unixSeconds,
          unixSeconds,
          unixSeconds,
          category,
          subcategory,
          duration,
          -5,
          -5,
          ruleVersion,
          status,
          deletedAt,
        ]);
      }

      await database.appSettingsDao.getSettings();
      await expectLater(
        rawInsert(id: 'invalid-duration', duration: 20),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        rawInsert(
          id: 'category-mismatch',
          category: 'study',
          subcategory: 'nap',
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        rawInsert(id: 'invalid-status', status: 'removed'),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        rawInsert(id: 'active-with-deleted-at', deletedAt: unixSeconds),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        rawInsert(id: 'deleted-without-time', status: 'deleted'),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        rawInsert(id: 'unknown-rule', ruleVersion: 'missing-rule'),
        throwsA(isA<Exception>()),
      );
    },
  );

  test(
    'learning run state, JSON, candidate, uniqueness, and finality hold',
    () async {
      final repository = DriftLearningRunsRepository(LearningRunsDao(database));
      final fixture = backupFixtureV3().learningRuns.single;
      final pending = _learningRunState(
        fixture,
        status: LearningRunStatus.pending,
        result: null,
        reasonCodesJson: '[]',
        completedAt: null,
      );
      await repository.insert(pending);

      await expectLater(
        database.learningRunsDao.updateById(
          pending.id,
          const LearningRunsTableCompanion(candidateValuesJson: Value('{}')),
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        database.learningRunsDao.updateById(
          pending.id,
          const LearningRunsTableCompanion(
            currentValuesJson: Value('{"baseEnergy":100,"extra":1}'),
          ),
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        database.learningRunsDao.updateById(
          pending.id,
          const LearningRunsTableCompanion(
            status: Value(LearningRunStatus.completed),
          ),
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(repository.insert(pending), throwsA(isA<Exception>()));

      final running = _learningRunState(
        pending,
        status: LearningRunStatus.running,
        result: null,
        reasonCodesJson: '[]',
        completedAt: null,
      );
      await repository.update(running);
      final retryable = _learningRunState(
        running,
        status: LearningRunStatus.retryableFailure,
        result: null,
        reasonCodesJson: '["retryableLearningFailure"]',
        completedAt: backupFixtureNow.add(const Duration(seconds: 1)),
      );
      await repository.update(retryable);
      await repository.update(running);
      final completed = _learningRunState(
        running,
        status: LearningRunStatus.completed,
        result: LearningRunResult.insufficientEvidence,
        reasonCodesJson: fixture.reasonCodesJson,
        completedAt: backupFixtureNow.add(const Duration(seconds: 2)),
      );
      await repository.update(completed);
      await expectLater(
        repository.update(completed),
        throwsA(isA<Exception>()),
      );
    },
  );

  test('daily summaries are unique and reject update or delete', () async {
    final repository = DriftDailySummariesRepository(
      DailySummariesDao(database),
    );
    final first = await repository.insertOrGet(_summary(finalEstimate: 72));
    final second = await repository.insertOrGet(_summary(finalEstimate: 10));

    expect(first.finalEstimatedEnergy, 72);
    expect(second.finalEstimatedEnergy, 72);
    await expectLater(
      (database.update(
        database.dailySummariesTable,
      )..where((row) => row.lifeDay.equalsValue(LifeDay(2026, 7, 26)))).write(
        const DailySummariesTableCompanion(finalEstimatedEnergy: Value(1)),
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      (database.delete(
        database.dailySummariesTable,
      )..where((row) => row.lifeDay.equalsValue(LifeDay(2026, 7, 26)))).go(),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database
          .into(database.dailySummariesTable)
          .insert(
            DailySummariesTableCompanion.insert(
              lifeDay: LifeDay(2026, 7, 27),
              baseEstimatedEnergy: 100,
              ruleVersion: energyRulesV2MvpAVersion,
              morningAdjustment: 0,
              shortTermAdjustment: 0,
              initialEstimatedEnergy: 100,
              finalEstimatedEnergy: 80,
              totalConsumption: 20,
              totalRecovery: 0,
              categorySummaryJson: '{}',
              isStandardEffectiveDay: true,
              isWeakEffectiveDay: true,
              settledAt: testNow,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('referenced rule versions reject every update', () async {
    await database.appSettingsDao.getSettings();

    await expectLater(
      database.ruleConfigVersionsDao.insertVersion(
        RuleConfigVersionsTableCompanion.insert(
          version: 'invalid-json-rule',
          valuesJson: '{not-json',
          createdAt: testNow,
        ),
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      (database.update(
        database.ruleConfigVersionsTable,
      )..where((row) => row.version.equals(energyRulesV2MvpAVersion))).write(
        const RuleConfigVersionsTableCompanion(
          valuesJson: Value('{"changed":true}'),
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('prompt receipt scope is non-empty and triple is unique', () async {
    final repository = DriftPromptReceiptsRepository(
      PromptReceiptsDao(database),
    );
    final receipt = _receipt(id: 'receipt-1');
    await repository.insert(receipt);

    await expectLater(
      repository.insert(_receipt(id: 'receipt-2')),
      throwsA(isA<Exception>()),
    );
    await repository.insert(
      PromptReceipt(
        id: 'receipt-3',
        type: receipt.type,
        scopeKey: receipt.scopeKey,
        action: PromptReceiptAction.dismissed,
        occurredAt: testNow,
      ),
    );
    await expectLater(
      repository.insert(
        PromptReceipt(
          id: 'empty-scope',
          type: PromptReceiptType.morning,
          scopeKey: ' ',
          action: PromptReceiptAction.shown,
          occurredAt: testNow,
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('app settings enforce singleton id and base estimate range', () async {
    await database.appSettingsDao.getSettings();
    await expectLater(
      database
          .into(database.appSettingsTable)
          .insert(
            AppSettingsTableCompanion.insert(
              id: const Value(2),
              activeRuleVersion: energyRulesV2MvpAVersion,
              createdAt: testNow,
              updatedAt: testNow,
            ),
          ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database.appSettingsDao.updateSettings(
        const AppSettingsTableCompanion(baseEstimatedEnergy: Value(141)),
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database.appSettingsDao.updateSettings(
        const AppSettingsTableCompanion(pendingBaseEstimatedEnergy: Value(105)),
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database.appSettingsDao.updateSettings(
        const AppSettingsTableCompanion(
          pendingRuleVersion: Value(energyRulesV2MvpAVersion),
        ),
      ),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database.delete(database.appSettingsTable).go(),
      throwsA(isA<Exception>()),
    );
  });

  test('transaction failures roll back every write', () async {
    final repository = DriftMorningCheckInsRepository(
      MorningCheckInsDao(database),
    );

    await expectLater(
      database.transaction(() async {
        await repository.insert(_checkIn(id: 'rolled-back'));
        throw StateError('force rollback');
      }),
      throwsStateError,
    );

    expect(await repository.list(), isEmpty);
  });
}

LearningRun _learningRunState(
  LearningRun source, {
  required LearningRunStatus status,
  required LearningRunResult? result,
  required String reasonCodesJson,
  required DateTime? completedAt,
}) {
  return LearningRun(
    id: source.id,
    parameterFamily: source.parameterFamily,
    sourceModelIdentity: source.sourceModelIdentity,
    sourcePersonalizationVersionId: source.sourcePersonalizationVersionId,
    status: status,
    result: result,
    evidenceSnapshotJson: source.evidenceSnapshotJson,
    evidenceHash: source.evidenceHash,
    evidenceHashVersion: source.evidenceHashVersion,
    algorithmVersion: source.algorithmVersion,
    configVersion: source.configVersion,
    currentValuesJson: source.currentValuesJson,
    candidateValuesJson: source.candidateValuesJson,
    reasonCodesJson: reasonCodesJson,
    triggeredAt: source.triggeredAt,
    completedAt: completedAt,
  );
}

MorningCheckIn _checkIn({required String id}) {
  return MorningCheckIn(
    id: id,
    lifeDay: LifeDay(2026, 7, 26),
    overallState: MorningOverallState.good,
    freeTimeLevel: FreeTimeLevel.medium,
    pressureSource: PressureSource.low,
    sleepRecovery: SleepRecovery.normal,
    morningAdjustment: 6,
    completedAt: testNow,
  );
}

EnergyObservation _dailyObservation({required String id}) {
  return EnergyObservation(
    id: id,
    lifeDay: LifeDay(2026, 7, 26),
    type: EnergyObservationType.dailyAbsolute,
    absoluteState: AbsoluteEnergyState.good,
    relativeState: null,
    estimateAtObservation: 72,
    observedAt: testNow,
  );
}

EnergyObservation _relativeObservation({required String id}) {
  return EnergyObservation(
    id: id,
    lifeDay: LifeDay(2026, 7, 26),
    type: EnergyObservationType.relativeCorrection,
    absoluteState: null,
    relativeState: RelativeCorrection.aboutRight,
    estimateAtObservation: 72,
    observedAt: testNow,
  );
}

EnergyObservation _contractObservation({required String id}) {
  return EnergyObservation(
    id: id,
    lifeDay: LifeDay(2026, 7, 26),
    type: EnergyObservationType.dailyAbsolute,
    absoluteState: AbsoluteEnergyState.good,
    relativeState: null,
    estimateAtObservation: 80,
    observedAt: testNow,
    contractVersion: mvpBObservationContractV1,
    referenceType: ObservationReferenceType.currentMoment,
    initialEstimateAtObservation: 100,
    estimatedOrdinalAtObservation: 4,
    baseEnergyAtObservation: 100,
    ruleVersionAtObservation: energyRulesV2MvpAVersion,
    comparisonBandVersion: 'estimate-actual-ordinal-v1',
    personalizationVersionAtObservation: 'fixed-mvp-a',
    effectiveModelFingerprintAtObservation: 'fixed-mvp-a',
    modelRegimeEpochAtObservation: 'fixed-mvp-a-initial',
    activeActivityCountAtObservation: 1,
    coverageState: ObservationCoverageState.confirmed,
    modelRegimeKey: 'regime-key',
  );
}

StoredEstimatedActivity _feedbackActivity() {
  final delta = EnergyRuleConfig.v2MvpA().theoreticalDelta(
    ActivitySubcategory.homework,
    DurationSlot.minutes30,
  );
  return StoredEstimatedActivity(
    id: 'feedback-activity',
    lifeDay: LifeDay(2026, 7, 26),
    completedAt: testNow.subtract(const Duration(hours: 1)),
    createdAt: testNow.subtract(const Duration(hours: 2)),
    updatedAt: testNow.subtract(const Duration(minutes: 30)),
    category: ActivityCategory.study,
    subcategory: ActivitySubcategory.homework,
    duration: DurationSlot.minutes30,
    theoreticalDelta: delta,
    appliedDelta: delta,
    ruleVersion: energyRulesV2MvpAVersion,
    status: ActivityRecordStatus.active,
    deletedAt: null,
  );
}

ActivityFeedback _feedback({
  required String id,
  required StoredEstimatedActivity activity,
  ActivityImpactSign impactSign = ActivityImpactSign.consumption,
  ActivityFeedbackStatus status = ActivityFeedbackStatus.active,
}) {
  return ActivityFeedback(
    id: id,
    activityRecordId: activity.id,
    lifeDay: activity.lifeDay,
    subcategorySnapshot: activity.subcategory,
    durationSnapshot: activity.duration,
    theoreticalDeltaSnapshot: activity.theoreticalDelta,
    appliedDeltaSnapshot: activity.appliedDelta,
    impactSignSnapshot: impactSign,
    ruleVersionSnapshot: activity.ruleVersion,
    activityUpdatedAtSnapshot: activity.updatedAt,
    direction: ActivityFeedbackDirection.aboutRight,
    status: status,
    invalidationReason: null,
    observedAt: testNow,
  );
}

DailySummary _summary({required int finalEstimate}) {
  return DailySummary(
    lifeDay: LifeDay(2026, 7, 26),
    baseEstimatedEnergy: 100,
    ruleVersion: energyRulesV2MvpAVersion,
    morningAdjustment: 0,
    shortTermAdjustment: 0,
    initialEstimatedEnergy: 100,
    finalEstimatedEnergy: finalEstimate,
    totalConsumption: 28,
    totalRecovery: 0,
    categorySummaries: {
      ActivityCategory.study: const CategoryEstimatedSummary(
        category: ActivityCategory.study,
        durationMinutes: 60,
        netDelta: -28,
        grossDelta: 28,
      ),
    },
    isStandardEffectiveDay: true,
    isWeakEffectiveDay: false,
    settledAt: testNow,
  );
}

PromptReceipt _receipt({required String id}) {
  return PromptReceipt(
    id: id,
    type: PromptReceiptType.energyBand,
    scopeKey: '2026-07-26:estimatedLow',
    action: PromptReceiptAction.shown,
    occurredAt: testNow,
  );
}
