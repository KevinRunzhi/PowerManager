import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/data_health_service.dart';
import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_export_service.dart';
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
    expect(report.daysUntilMvpBDiscussion, 13);
  });

  test('zero effective days has a safe zero coverage', () async {
    final report = await _service(
      summaries: [_summary(day1)],
      observations: [_actual(day1, 'actual')],
    ).check();

    expect(report.effectiveDays, 0);
    expect(report.effectiveDaysWithActualState, 0);
    expect(report.coveragePercent, 0);
    expect(report.daysUntilMvpBDiscussion, 14);
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
    );

    expect(report.daysUntilMvpBDiscussion, 0);
    expect(report.reachedMvpBDiscussionCount, isTrue);
  });
}

DataHealthService _service({
  required List<DailySummary> summaries,
  required List<EnergyObservation> observations,
  List<StoredEstimatedActivity> activities = const [],
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
    summaries: _Summaries(summaries),
    localBackupStore: _BackupStore(),
  );
}

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
