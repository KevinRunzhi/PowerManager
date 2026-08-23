import 'dart:collection';

import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

final class CorrectionCounts {
  const CorrectionCounts({
    required this.lower,
    required this.aboutRight,
    required this.higher,
  });

  final int lower;
  final int aboutRight;
  final int higher;

  int get total => lower + aboutRight + higher;
}

final class HistoricalDayReview {
  HistoricalDayReview({
    required this.summary,
    required this.actualState,
    required this.corrections,
  }) : categories = _sortedCategories(summary);

  final DailySummary summary;
  final AbsoluteEnergyState? actualState;
  final CorrectionCounts corrections;
  final List<CategoryEstimatedSummary> categories;

  String titleFor(LifeDay currentLifeDay) =>
      summary.lifeDay == currentLifeDay.previous ? '昨日总结' : '上次记录日总结';

  String get actualStateLabel => switch (actualState) {
    AbsoluteEnergyState.exhausted => '耗尽',
    AbsoluteEnergyState.low => '偏低',
    AbsoluteEnergyState.okay => '尚可',
    AbsoluteEnergyState.good => '良好',
    AbsoluteEnergyState.full => '充足',
    null => '未确认',
  };

  static List<CategoryEstimatedSummary> _sortedCategories(
    DailySummary summary,
  ) {
    final result =
        summary.categorySummaries.values
            .where((item) => item.durationMinutes > 0)
            .toList()
          ..sort(_compareHistoricalCategories);
    return List.unmodifiable(result);
  }
}

final class RollingReview {
  RollingReview({
    required Iterable<HistoricalDayReview> days,
    required this.totalConsumption,
    required this.totalRecovery,
    required this.corrections,
    required Map<ActivityCategory, CategoryEstimatedSummary> categorySummaries,
  }) : days = List.unmodifiable(days),
       categorySummaries = UnmodifiableMapView(
         Map.unmodifiable(categorySummaries),
       );

  final List<HistoricalDayReview> days;
  final int totalConsumption;
  final int totalRecovery;
  final CorrectionCounts corrections;
  final Map<ActivityCategory, CategoryEstimatedSummary> categorySummaries;

  int get confirmedActualDays =>
      days.where((day) => day.actualState != null).length;

  String get windowLabel =>
      days.length == 7 ? '最近 7 个有效日' : '最近 ${days.length} 个有效日（数据积累中）';
}

final class HistoryReview {
  const HistoryReview({required this.latest, required this.rolling});

  final HistoricalDayReview? latest;
  final RollingReview rolling;
}

final class HistoryReviewService {
  const HistoryReviewService({
    required this.summaries,
    required this.observations,
  });

  final DailySummariesRepository summaries;
  final EnergyObservationsRepository observations;

  Future<HistoryReview> load({required LifeDay currentLifeDay}) async {
    final results = await Future.wait<Object>([
      summaries.list(),
      observations.list(),
    ]);
    final historicalSummaries =
        (results[0] as List<DailySummary>)
            .where((summary) => summary.lifeDay.compareTo(currentLifeDay) < 0)
            .toList()
          ..sort((left, right) => right.lifeDay.compareTo(left.lifeDay));
    final historicalObservations = results[1] as List<EnergyObservation>;
    final byLifeDay = <LifeDay, List<EnergyObservation>>{};
    for (final observation in historicalObservations) {
      if (observation.lifeDay.compareTo(currentLifeDay) < 0) {
        byLifeDay.putIfAbsent(observation.lifeDay, () => []).add(observation);
      }
    }

    HistoricalDayReview review(DailySummary summary) {
      final dayObservations =
          byLifeDay[summary.lifeDay] ?? const <EnergyObservation>[];
      final actual = dayObservations
          .where((item) => item.type == EnergyObservationType.dailyAbsolute)
          .firstOrNull;
      return HistoricalDayReview(
        summary: summary,
        actualState: actual?.absoluteState,
        corrections: _countCorrections(dayObservations),
      );
    }

    final latest = historicalSummaries.isEmpty
        ? null
        : review(historicalSummaries.first);
    final effective = historicalSummaries
        .where(
          (summary) =>
              summary.isStandardEffectiveDay || summary.isWeakEffectiveDay,
        )
        .take(7)
        .map(review)
        .toList()
        .reversed
        .toList();
    return HistoryReview(latest: latest, rolling: _buildRolling(effective));
  }

  static RollingReview _buildRolling(List<HistoricalDayReview> days) {
    final categories = <ActivityCategory, _MutableCategorySummary>{};
    var consumption = 0;
    var recovery = 0;
    var lower = 0;
    var aboutRight = 0;
    var higher = 0;
    for (final day in days) {
      consumption += day.summary.totalConsumption;
      recovery += day.summary.totalRecovery;
      lower += day.corrections.lower;
      aboutRight += day.corrections.aboutRight;
      higher += day.corrections.higher;
      for (final item in day.categories) {
        final total = categories.putIfAbsent(
          item.category,
          _MutableCategorySummary.new,
        );
        total.durationMinutes += item.durationMinutes;
        total.netDelta += item.netDelta;
        total.grossDelta += item.grossDelta;
      }
    }
    return RollingReview(
      days: days,
      totalConsumption: consumption,
      totalRecovery: recovery,
      corrections: CorrectionCounts(
        lower: lower,
        aboutRight: aboutRight,
        higher: higher,
      ),
      categorySummaries: {
        for (final entry in categories.entries)
          entry.key: CategoryEstimatedSummary(
            category: entry.key,
            durationMinutes: entry.value.durationMinutes,
            netDelta: entry.value.netDelta,
            grossDelta: entry.value.grossDelta,
          ),
      },
    );
  }

  static CorrectionCounts _countCorrections(
    Iterable<EnergyObservation> observations,
  ) {
    var lower = 0;
    var aboutRight = 0;
    var higher = 0;
    for (final observation in observations.where(
      (item) => item.type == EnergyObservationType.relativeCorrection,
    )) {
      switch (observation.relativeState) {
        case RelativeCorrection.lowerThanEstimate:
          lower++;
        case RelativeCorrection.aboutRight:
          aboutRight++;
        case RelativeCorrection.higherThanEstimate:
          higher++;
        case null:
          break;
      }
    }
    return CorrectionCounts(
      lower: lower,
      aboutRight: aboutRight,
      higher: higher,
    );
  }
}

final class _MutableCategorySummary {
  int durationMinutes = 0;
  int netDelta = 0;
  int grossDelta = 0;
}

int _compareHistoricalCategories(
  CategoryEstimatedSummary left,
  CategoryEstimatedSummary right,
) {
  final gross = right.grossDelta.compareTo(left.grossDelta);
  return gross != 0
      ? gross
      : left.category.index.compareTo(right.category.index);
}
