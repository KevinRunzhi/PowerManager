import 'package:power_manager/application/history_review_service.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';
import 'package:test/test.dart';

void main() {
  test(
    'strict previous life day is yesterday and missing actual is explicit',
    () async {
      final current = LifeDay(2026, 7, 26);
      final service = _service(
        summaries: [_summary(current.previous)],
        observations: [],
      );

      final result = await service.load(currentLifeDay: current);

      expect(result.latest!.titleFor(current), '昨日总结');
      expect(result.latest!.actualState, isNull);
      expect(result.latest!.actualStateLabel, '未确认');
    },
  );

  test('older latest summary is labelled last recorded day', () async {
    final current = LifeDay(2026, 7, 26);
    final result = await _service(
      summaries: [_summary(LifeDay(2026, 7, 22))],
      observations: [],
    ).load(currentLifeDay: current);

    expect(result.latest!.titleFor(current), '上次记录日总结');
  });

  test(
    'late actual observation and correction directions join by life day',
    () async {
      final day = LifeDay(2026, 7, 25);
      final result = await _service(
        summaries: [_summary(day)],
        observations: [
          _actual(day, AbsoluteEnergyState.low),
          _correction(day, RelativeCorrection.lowerThanEstimate, 'lower'),
          _correction(day, RelativeCorrection.aboutRight, 'right'),
          _correction(day, RelativeCorrection.higherThanEstimate, 'higher'),
        ],
      ).load(currentLifeDay: LifeDay(2026, 7, 26));

      expect(result.latest!.actualStateLabel, '偏低');
      expect(result.latest!.corrections.total, 3);
      expect(result.latest!.corrections.lower, 1);
      expect(result.latest!.corrections.aboutRight, 1);
      expect(result.latest!.corrections.higher, 1);
    },
  );

  test(
    'partial rolling review includes one to six effective days only',
    () async {
      final current = LifeDay(2026, 7, 26);
      final summaries = [
        _summary(LifeDay(2026, 7, 20), standard: false, weak: false),
        for (var day = 21; day <= 25; day++)
          _summary(LifeDay(2026, 7, day), consumption: day),
        _summary(current, consumption: 999),
      ];

      final result = await _service(
        summaries: summaries,
        observations: [],
      ).load(currentLifeDay: current);

      expect(result.rolling.days, hasLength(5));
      expect(result.rolling.windowLabel, '最近 5 个有效日（数据积累中）');
      expect(result.rolling.days.first.summary.lifeDay, LifeDay(2026, 7, 21));
      expect(result.rolling.days.last.summary.lifeDay, LifeDay(2026, 7, 25));
      expect(result.rolling.totalConsumption, 21 + 22 + 23 + 24 + 25);
    },
  );

  test('rolling review keeps only the latest seven effective days', () async {
    final summaries = [
      for (var day = 1; day <= 9; day++)
        _summary(
          LifeDay(2026, 7, day),
          consumption: day,
          standard: day.isOdd,
          weak: day.isEven,
        ),
    ];

    final result = await _service(
      summaries: summaries,
      observations: [],
    ).load(currentLifeDay: LifeDay(2026, 7, 10));

    expect(result.rolling.days, hasLength(7));
    expect(result.rolling.windowLabel, '最近 7 个有效日');
    expect(result.rolling.days.first.summary.lifeDay, LifeDay(2026, 7, 3));
    expect(result.rolling.days.last.summary.lifeDay, LifeDay(2026, 7, 9));
    expect(result.rolling.totalConsumption, 3 + 4 + 5 + 6 + 7 + 8 + 9);
  });

  test('category distribution aggregates duration, net and gross', () async {
    final result = await _service(
      summaries: [
        _summary(LifeDay(2026, 7, 24), categoryNet: -4),
        _summary(LifeDay(2026, 7, 25), categoryNet: 6),
      ],
      observations: [],
    ).load(currentLifeDay: LifeDay(2026, 7, 26));

    final study = result.rolling.categorySummaries[ActivityCategory.study]!;
    expect(study.durationMinutes, 60);
    expect(study.netDelta, 2);
    expect(study.grossDelta, 10);
  });
}

HistoryReviewService _service({
  required List<DailySummary> summaries,
  required List<EnergyObservation> observations,
}) {
  return HistoryReviewService(
    summaries: _MemorySummaries(summaries),
    observations: _MemoryObservations(observations),
  );
}

DailySummary _summary(
  LifeDay day, {
  int consumption = 10,
  int categoryNet = -5,
  bool standard = true,
  bool weak = false,
}) {
  return DailySummary(
    lifeDay: day,
    baseEstimatedEnergy: 100,
    ruleVersion: 'test',
    morningAdjustment: 0,
    shortTermAdjustment: 0,
    initialEstimatedEnergy: 100,
    finalEstimatedEnergy: 95,
    totalConsumption: consumption,
    totalRecovery: 2,
    categorySummaries: {
      ActivityCategory.study: CategoryEstimatedSummary(
        category: ActivityCategory.study,
        durationMinutes: 30,
        netDelta: categoryNet,
        grossDelta: categoryNet.abs(),
      ),
    },
    isStandardEffectiveDay: standard,
    isWeakEffectiveDay: weak,
    settledAt: DateTime.utc(day.year, day.month, day.day + 1, 4),
  );
}

EnergyObservation _actual(LifeDay day, AbsoluteEnergyState state) {
  return EnergyObservation(
    id: 'actual-$day',
    lifeDay: day,
    type: EnergyObservationType.dailyAbsolute,
    absoluteState: state,
    relativeState: null,
    estimateAtObservation: null,
    observedAt: DateTime.utc(day.year, day.month, day.day, 12),
  );
}

EnergyObservation _correction(
  LifeDay day,
  RelativeCorrection correction,
  String suffix,
) {
  return EnergyObservation(
    id: 'correction-$day-$suffix',
    lifeDay: day,
    type: EnergyObservationType.relativeCorrection,
    absoluteState: null,
    relativeState: correction,
    estimateAtObservation: 95,
    observedAt: DateTime.utc(day.year, day.month, day.day, 14),
  );
}

final class _MemorySummaries implements DailySummariesRepository {
  _MemorySummaries(this.values);

  final List<DailySummary> values;

  @override
  Future<DailySummary?> findByLifeDay(LifeDay lifeDay) async =>
      values.where((item) => item.lifeDay == lifeDay).firstOrNull;

  @override
  Future<DailySummary> insertOrGet(DailySummary summary) async => summary;

  @override
  Future<List<DailySummary>> list() async => List.unmodifiable(values);
}

final class _MemoryObservations implements EnergyObservationsRepository {
  _MemoryObservations(this.values);

  final List<EnergyObservation> values;

  @override
  Future<EnergyObservation?> find(String id) async =>
      values.where((item) => item.id == id).firstOrNull;

  @override
  Future<void> insert(EnergyObservation observation) async {
    values.add(observation);
  }

  @override
  Future<List<EnergyObservation>> list() async => List.unmodifiable(values);

  @override
  Future<List<EnergyObservation>> listForLifeDay(LifeDay lifeDay) async =>
      values.where((item) => item.lifeDay == lifeDay).toList();

  @override
  Future<void> update(EnergyObservation observation) async {}
}
