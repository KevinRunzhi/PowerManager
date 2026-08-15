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
import 'package:power_manager/domain/entities/persisted_entities.dart';
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
    expect(report.schemaVersion, 2);
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

  test('fourteen observations only reaches the discussion count', () {
    final report = DataHealthReport(
      checkedAt: backupFixtureNow,
      schemaVersion: 2,
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
}

DataHealthService _service({
  required List<DailySummary> summaries,
  required List<EnergyObservation> observations,
  List<StoredEstimatedActivity> activities = const [],
  List<ActivityFeedback> feedback = const [],
  String? exportContents,
}) {
  return DataHealthService(
    exportService: _Exporter(
      exportContents ?? jsonEncode(backupFixture().toJson()),
    ),
    codec: const JsonBackupCodec(),
    clock: const _Clock(),
    mornings: _Mornings(),
    activities: _Activities(activities),
    observations: _Observations(observations),
    feedback: _Feedback(feedback),
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
  @override
  Future<List<MorningCheckIn>> list() async => const [];
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
