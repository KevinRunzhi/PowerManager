import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/data_health_service.dart';
import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/application/mvp_b_upgrade_readiness_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/backup/local_backup_store.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/learning_eligibility_service.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';
import 'package:test/test.dart';

import '../support/backup_fixture.dart';

void main() {
  final day1 = LifeDay(2026, 8, 1);
  final day2 = LifeDay(2026, 8, 2);
  final day3 = LifeDay(2026, 8, 3);
  final day4 = LifeDay(2026, 8, 4);

  test('counts effective coverage and observation types separately', () async {
    final report = await _service(
      summaries: [
        _summary(day1, standard: true),
        _summary(day2, weak: true),
        _summary(day3, standard: true),
        _summary(day4),
      ],
      observations: [
        _actual(day1, 'actual-effective'),
        _actual(day4, 'actual-non-effective'),
        _correction(day2),
      ],
      activities: [
        _activity(day1, 'active'),
        _activity(day1, 'deleted', deleted: true),
      ],
      feedback: [_feedback(active: true), _feedback(active: false)],
    ).check();

    expect(report.integrityPassed, isTrue);
    expect(report.settledDays, 4);
    expect(report.standardEffectiveDays, 2);
    expect(report.weakEffectiveDays, 1);
    expect(report.effectiveDaysWithActualState, 1);
    expect(report.coveragePercent, 33);
    expect(report.dailyActualStates, 2);
    expect(report.relativeCorrections, 1);
    expect(report.activityRecords, 2);
    expect(report.deletedActivityRecords, 1);
    expect(report.schemaVersion, 5);
    expect(report.legacyObservations, 3);
    expect(report.contractObservations, 0);
    expect(report.activityFeedback, 2);
    expect(report.activeActivityFeedback, 1);
    expect(report.invalidatedActivityFeedback, 1);
    expect(report.daysUntilLegacyDiscussionCount, 13);
    expect(
      report.mvpBUpgradeReadiness.status,
      MvpBUpgradeReadinessStatus.notChecked,
    );
  });

  test('zero effective days has a safe zero coverage', () async {
    final report = await _service(
      summaries: [_summary(day1)],
      observations: [_actual(day1, 'actual')],
    ).check();

    expect(report.effectiveDays, 0);
    expect(report.effectiveDaysWithActualState, 0);
    expect(report.coveragePercent, 0);
    expect(report.daysUntilLegacyDiscussionCount, 14);
  });

  test('integrity failure returns a safe aggregate result', () async {
    final report = await _service(
      summaries: [_summary(day1, standard: true)],
      observations: const [],
      exportContents: '{"schemaVersion":1}',
    ).check();

    expect(report.integrityPassed, isFalse);
    expect(report.effectiveDays, 1);
  });

  test(
    'aggregates B0-3 evidence through the shared eligibility service',
    () async {
      final report = await _service(
        summaries: [
          _summary(day1, standard: true),
          _summary(day2, standard: true),
          _summary(day4),
        ],
        mornings: [_morning(day1), _morning(day2)],
        observations: [
          _contractActual(
            day1,
            'eligible-current',
            referenceType: ObservationReferenceType.currentMoment,
          ),
          _contractActual(
            day2,
            'uncertain-yesterday',
            referenceType: ObservationReferenceType.previousLifeDayEnd,
            coverageState: ObservationCoverageState.uncertain,
          ),
          _contractActual(
            day3,
            'unsettled-current',
            referenceType: ObservationReferenceType.currentMoment,
          ),
          _actual(day4, 'legacy-daily'),
        ],
      ).check();

      expect(report.currentMomentContractObservations, 2);
      expect(report.previousLifeDayEndContractObservations, 1);
      expect(report.contractObservations, 3);
      expect(report.eligibleCurrentRegimeObservations, 1);
      expect(report.earliestEligibleLifeDay, day1);
      expect(report.latestEligibleLifeDay, day1);
      expect(report.unsettledContractObservations, 1);
      expect(
        report.exclusionCount(LearningIneligibilityReason.legacyContract),
        1,
      );
      expect(
        report.exclusionCount(LearningIneligibilityReason.coverageUncertain),
        1,
      );
      expect(
        report.exclusionCount(
          LearningIneligibilityReason.missingMorningCheckIn,
        ),
        1,
      );
      expect(report.automaticLearningProgress, hasLength(2));
      final current = report.automaticLearningProgress.singleWhere(
        (item) => item.referenceType == ObservationReferenceType.currentMoment,
      );
      final previous = report.automaticLearningProgress.singleWhere(
        (item) =>
            item.referenceType == ObservationReferenceType.previousLifeDayEnd,
      );
      expect(current.eligibleTotal, 1);
      expect(current.missingToMinimum, 13);
      expect(current.firstWindowSize, 1);
      expect(previous.eligibleTotal, 0);
      expect(
        previous.exclusionCounts[LearningIneligibilityReason.coverageUncertain],
        1,
      );
    },
  );

  test('fourteen observations only reaches the discussion count', () {
    final report = DataHealthReport(
      checkedAt: backupFixtureNow,
      schemaVersion: 3,
      integrityPassed: true,
      settledDays: 14,
      standardEffectiveDays: 14,
      weakEffectiveDays: 0,
      effectiveDaysWithActualState: 14,
      morningCheckIns: 14,
      activityRecords: 14,
      deletedActivityRecords: 0,
      dailyActualStates: 14,
      relativeCorrections: 0,
      localBackup: null,
      mvpBUpgradeReadiness: _notCheckedReadiness,
    );

    expect(report.daysUntilLegacyDiscussionCount, 0);
    expect(report.reachedLegacyDiscussionCount, isTrue);
  });

  test(
    'reports the latest current-regime run without exposing its hash',
    () async {
      final observation = _contractActual(
        day1,
        'run-evidence',
        referenceType: ObservationReferenceType.currentMoment,
      );
      final evidence = const ShadowEvidenceBuilder()
          .buildAll(
            observations: [observation],
            morningLifeDays: {day1},
            settledLifeDays: {day1},
            config: ShadowLearningConfig.evidenceReadinessV1(),
          )
          .single;
      final run = LearningRun(
        id: 'safe-test-run',
        parameterFamily: LearningParameterFamily.baseline,
        sourceModelIdentity: evidence.sourceModelIdentity,
        sourcePersonalizationVersionId: null,
        status: LearningRunStatus.retryableFailure,
        result: null,
        evidenceSnapshotJson: evidence.evidenceSnapshotJson,
        evidenceHash: evidence.evidenceHash,
        evidenceHashVersion: canonicalEvidenceHashV1,
        algorithmVersion: shadowLearningAlgorithmV1,
        configVersion: shadowLearningConfigV1,
        currentValuesJson: evidence.currentValuesJson,
        candidateValuesJson: null,
        reasonCodesJson: '["retryableLearningFailure"]',
        triggeredAt: backupFixtureNow,
        completedAt: backupFixtureNow,
      );

      final report = await _service(
        summaries: [_summary(day1)],
        observations: [observation],
        mornings: [_morning(day1)],
        learningRuns: [run],
      ).check();
      final progress = report.automaticLearningProgress.singleWhere(
        (item) => item.referenceType == ObservationReferenceType.currentMoment,
      );

      expect(report.learningRuns, 1);
      expect(report.retryableLearningRuns, 1);
      expect(progress.latestRunStatus, LearningRunStatus.retryableFailure);
      expect(progress.latestRunMatchesCurrentEvidence, isTrue);
      expect(progress.latestRunAt, backupFixtureNow);
    },
  );
}

DataHealthService _service({
  required List<DailySummary> summaries,
  required List<EnergyObservation> observations,
  List<StoredEstimatedActivity> activities = const [],
  List<ActivityFeedback> feedback = const [],
  List<MorningCheckIn> mornings = const [],
  List<LearningRun> learningRuns = const [],
  String? exportContents,
}) {
  return DataHealthService(
    exportService: _Exporter(
      exportContents ?? jsonEncode(backupFixture().toJson()),
    ),
    codec: const JsonBackupCodec(),
    clock: const _Clock(),
    settings: const _Settings(),
    mornings: _Mornings(mornings),
    activities: _Activities(activities),
    observations: _Observations(observations),
    feedback: _Feedback(feedback),
    learningRuns: _LearningRuns(learningRuns),
    personalizationVersions: const _Versions(),
    summaries: _Summaries(summaries),
    localBackupStore: _BackupStore(),
    upgradeReadiness: const _ReadinessChecker(),
  );
}

final _notCheckedReadiness = MvpBUpgradeReadinessReport(
  status: MvpBUpgradeReadinessStatus.notChecked,
  checkedAt: backupFixtureNow,
);

DailySummary _summary(
  LifeDay day, {
  bool standard = false,
  bool weak = false,
}) => DailySummary(
  lifeDay: day,
  baseEstimatedEnergy: 100,
  ruleVersion: 'test',
  morningAdjustment: 0,
  shortTermAdjustment: 0,
  initialEstimatedEnergy: 100,
  finalEstimatedEnergy: 90,
  totalConsumption: 10,
  totalRecovery: 0,
  categorySummaries: const {
    ActivityCategory.study: CategoryEstimatedSummary(
      category: ActivityCategory.study,
      durationMinutes: 30,
      netDelta: -10,
      grossDelta: 10,
    ),
  },
  isStandardEffectiveDay: standard,
  isWeakEffectiveDay: weak,
  settledAt: DateTime.utc(2026, 8, 9),
);

EnergyObservation _actual(LifeDay day, String id) => EnergyObservation(
  id: id,
  lifeDay: day,
  type: EnergyObservationType.dailyAbsolute,
  absoluteState: AbsoluteEnergyState.okay,
  relativeState: null,
  estimateAtObservation: null,
  observedAt: DateTime.utc(2026, 8, 9),
);

EnergyObservation _correction(LifeDay day) => EnergyObservation(
  id: 'correction',
  lifeDay: day,
  type: EnergyObservationType.relativeCorrection,
  absoluteState: null,
  relativeState: RelativeCorrection.aboutRight,
  estimateAtObservation: 90,
  observedAt: DateTime.utc(2026, 8, 9),
);

EnergyObservation _contractActual(
  LifeDay day,
  String id, {
  required ObservationReferenceType referenceType,
  ObservationCoverageState coverageState = ObservationCoverageState.confirmed,
}) {
  final key = const ModelRegimeKeyBuilder().build(
    referenceType: referenceType,
    baseEnergy: 100,
    ruleVersion: 'test',
    comparisonBandVersion: mvpBComparisonBandV1,
    effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
    modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
  );
  return EnergyObservation(
    id: id,
    lifeDay: day,
    type: EnergyObservationType.dailyAbsolute,
    absoluteState: AbsoluteEnergyState.okay,
    relativeState: null,
    estimateAtObservation: 90,
    observedAt: DateTime.utc(2026, 8, 9),
    contractVersion: mvpBObservationContractV1,
    referenceType: referenceType,
    initialEstimateAtObservation: 100,
    estimatedOrdinalAtObservation: 4,
    baseEnergyAtObservation: 100,
    ruleVersionAtObservation: 'test',
    comparisonBandVersion: mvpBComparisonBandV1,
    personalizationVersionAtObservation: fixedMvpAPersonalizationVersion,
    effectiveModelFingerprintAtObservation: fixedMvpAEffectiveModelFingerprint,
    modelRegimeEpochAtObservation: fixedMvpAInitialModelRegimeEpoch,
    activeActivityCountAtObservation: 1,
    coverageState: coverageState,
    modelRegimeKey: key,
  );
}

MorningCheckIn _morning(LifeDay day) => MorningCheckIn(
  id: 'morning-$day',
  lifeDay: day,
  overallState: MorningOverallState.normal,
  freeTimeLevel: FreeTimeLevel.medium,
  pressureSource: PressureSource.low,
  sleepRecovery: SleepRecovery.good,
  morningAdjustment: 0,
  completedAt: DateTime.utc(day.year, day.month, day.day, 5),
);

StoredEstimatedActivity _activity(
  LifeDay day,
  String id, {
  bool deleted = false,
}) => StoredEstimatedActivity(
  id: id,
  lifeDay: day,
  completedAt: DateTime.utc(2026, 8, 1, 8),
  createdAt: DateTime.utc(2026, 8, 1, 8),
  updatedAt: DateTime.utc(2026, 8, 1, 8),
  category: ActivityCategory.study,
  subcategory: ActivitySubcategory.homework,
  duration: DurationSlot.minutes30,
  theoreticalDelta: -8,
  appliedDelta: -8,
  ruleVersion: 'test',
  status: deleted ? ActivityRecordStatus.deleted : ActivityRecordStatus.active,
  deletedAt: deleted ? DateTime.utc(2026, 8, 1, 9) : null,
);

final class _Exporter implements JsonExporter {
  const _Exporter(this.contents);
  final String contents;

  @override
  Future<JsonExportResult> create({required DateTime exportedAt}) async =>
      JsonExportResult(fileName: 'health.json', contents: contents);
}

final class _Clock implements Clock {
  const _Clock();
  @override
  DateTime now() => backupFixtureNow;
}

final class _ReadinessChecker implements MvpBUpgradeReadinessChecker {
  const _ReadinessChecker();

  @override
  Future<MvpBUpgradeReadinessReport> check() async => _notCheckedReadiness;
}

final class _Settings implements AppSettingsRepository {
  const _Settings();

  @override
  Future<AppSettings> get() async => AppSettings(
    activeRuleVersion: 'test',
    pendingRuleVersion: null,
    pendingRuleEffectiveLifeDay: null,
    onboardingCompleted: true,
    createdAt: backupFixtureNow,
    updatedAt: backupFixtureNow,
  );

  @override
  Future<void> save(AppSettings settings) => throw UnimplementedError();
}

final class _Versions implements PersonalizationVersionsRepository {
  const _Versions();

  PersonalizationVersion get _active => PersonalizationVersion(
    id: fixedMvpAPersonalizationVersion,
    parentVersionId: null,
    effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
    modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
    creationSource: PersonalizationCreationSource.initial,
    scheduleSource: null,
    sourceLearningRunId: null,
    algorithmVersion: initialPersonalizationAlgorithmV1,
    configVersion: initialPersonalizationConfigV1,
    changedParameterFamily: PersonalizationChangedParameterFamily.none,
    baseEnergy: 100,
    baselineAnchorEnergy: 100,
    status: PersonalizationVersionStatus.active,
    effectiveLifeDay: null,
    createdAt: backupFixtureNow,
    activatedAt: backupFixtureNow,
    endedAt: null,
    transitionReason: 'testInitial',
  );

  @override
  Future<PersonalizationVersion> getActive() async => _active;
  @override
  Future<List<PersonalizationVersion>> list() async => [_active];
  @override
  Future<PersonalizationVersion?> find(String id) async =>
      id == _active.id ? _active : null;
  @override
  Future<PersonalizationVersion?> findPending() async => null;
  @override
  Future<void> insert(PersonalizationVersion version) =>
      throw UnimplementedError();
  @override
  Future<void> update(PersonalizationVersion version) =>
      throw UnimplementedError();
  @override
  Future<bool> updateIfStatus(
    PersonalizationVersion version,
    PersonalizationVersionStatus expectedStatus,
  ) => throw UnimplementedError();
}

final class _BackupStore implements LocalBackupStore {
  @override
  Future<LocalBackupMetadata?> metadata() async => null;
  @override
  Future<Uint8List> readBytes() => throw UnimplementedError();
  @override
  Future<LocalBackupMetadata> save(String contents) =>
      throw UnimplementedError();
}

final class _Mornings implements MorningCheckInsRepository {
  const _Mornings(this.items);

  final List<MorningCheckIn> items;

  @override
  Future<List<MorningCheckIn>> list() async => items;
  @override
  Future<void> delete(String id) => throw UnimplementedError();
  @override
  Future<MorningCheckIn?> findByLifeDay(LifeDay lifeDay) =>
      throw UnimplementedError();
  @override
  Future<void> insert(MorningCheckIn checkIn) => throw UnimplementedError();
  @override
  Future<void> update(MorningCheckIn checkIn) => throw UnimplementedError();
}

final class _Activities implements ActivityRecordsRepository {
  const _Activities(this.items);
  final List<StoredEstimatedActivity> items;
  @override
  Future<List<StoredEstimatedActivity>> listAllForExport() async => items;
  @override
  Future<StoredEstimatedActivity?> find(String id) =>
      throw UnimplementedError();
  @override
  Future<void> insert(StoredEstimatedActivity activity) =>
      throw UnimplementedError();
  @override
  Future<List<StoredEstimatedActivity>> listActiveForLifeDay(LifeDay lifeDay) =>
      throw UnimplementedError();
  @override
  Future<List<StoredEstimatedActivity>> listAllForLifeDay(LifeDay lifeDay) =>
      throw UnimplementedError();
  @override
  Future<void> logicallyDelete(String id, DateTime deletedAt) =>
      throw UnimplementedError();
  @override
  Future<void> update(StoredEstimatedActivity activity) =>
      throw UnimplementedError();
}

final class _Observations implements EnergyObservationsRepository {
  const _Observations(this.items);
  final List<EnergyObservation> items;
  @override
  Future<List<EnergyObservation>> list() async => items;
  @override
  Future<EnergyObservation?> find(String id) => throw UnimplementedError();
  @override
  Future<void> insert(EnergyObservation observation) =>
      throw UnimplementedError();
  @override
  Future<List<EnergyObservation>> listForLifeDay(LifeDay lifeDay) =>
      throw UnimplementedError();
  @override
  Future<void> update(EnergyObservation observation) =>
      throw UnimplementedError();
}

final class _Feedback implements ActivityFeedbackRepository {
  const _Feedback(this.items);

  final List<ActivityFeedback> items;

  @override
  Future<List<ActivityFeedback>> list() async => items;
  @override
  Future<ActivityFeedback?> find(String id) => throw UnimplementedError();
  @override
  Future<ActivityFeedback?> findActiveForActivity(String activityRecordId) =>
      throw UnimplementedError();
  @override
  Future<void> insert(ActivityFeedback feedback) => throw UnimplementedError();
  @override
  Future<List<ActivityFeedback>> listForActivity(String activityRecordId) =>
      throw UnimplementedError();
  @override
  Future<void> update(ActivityFeedback feedback) => throw UnimplementedError();
}

final class _LearningRuns implements LearningRunsRepository {
  const _LearningRuns(this.items);

  final List<LearningRun> items;

  @override
  Future<List<LearningRun>> list() async => items;
  @override
  Future<LearningRun?> find(String id) => throw UnimplementedError();
  @override
  Future<LearningRun?> findByIdempotency({
    required LearningParameterFamily parameterFamily,
    required String sourceModelIdentity,
    required String algorithmVersion,
    required String configVersion,
    required String evidenceHash,
  }) => throw UnimplementedError();
  @override
  Future<void> insert(LearningRun run) => throw UnimplementedError();
  @override
  Future<void> update(LearningRun run) => throw UnimplementedError();
}

ActivityFeedback _feedback({required bool active}) {
  return ActivityFeedback(
    id: active ? 'active-feedback' : 'invalidated-feedback',
    activityRecordId: active ? 'active' : 'deleted',
    lifeDay: LifeDay(2026, 8, 1),
    subcategorySnapshot: ActivitySubcategory.homework,
    durationSnapshot: DurationSlot.minutes30,
    theoreticalDeltaSnapshot: -8,
    appliedDeltaSnapshot: -8,
    impactSignSnapshot: ActivityImpactSign.consumption,
    ruleVersionSnapshot: 'test',
    activityUpdatedAtSnapshot: DateTime.utc(2026, 8, 1, 8),
    direction: ActivityFeedbackDirection.aboutRight,
    status: active
        ? ActivityFeedbackStatus.active
        : ActivityFeedbackStatus.invalidated,
    invalidationReason: active
        ? null
        : ActivityFeedbackInvalidationReason.activityDeleted,
    observedAt: DateTime.utc(2026, 8, 1, 9),
  );
}

final class _Summaries implements DailySummariesRepository {
  const _Summaries(this.items);
  final List<DailySummary> items;
  @override
  Future<List<DailySummary>> list() async => items;
  @override
  Future<DailySummary?> findByLifeDay(LifeDay lifeDay) =>
      throw UnimplementedError();
  @override
  Future<DailySummary> insertOrGet(DailySummary summary) =>
      throw UnimplementedError();
}
