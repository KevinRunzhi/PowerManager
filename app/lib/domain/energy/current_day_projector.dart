import 'dart:collection';

import 'package:power_manager/domain/energy/energy_calculator.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/estimated_activity.dart';

enum EffectiveDayKind { none, standard, weak }

final class CategoryEstimatedSummary {
  const CategoryEstimatedSummary({
    required this.category,
    required this.durationMinutes,
    required this.netDelta,
    required this.grossDelta,
  });

  final ActivityCategory category;
  final int durationMinutes;
  final int netDelta;
  final int grossDelta;
}

final class EstimatedDayProjection {
  EstimatedDayProjection({
    required this.initialEstimate,
    required this.currentEstimate,
    required this.band,
    required Iterable<ProjectedEstimatedActivity> activities,
    required this.totalConsumption,
    required this.totalRecovery,
    required Map<ActivityCategory, CategoryEstimatedSummary> categorySummaries,
    required this.effectiveDayKind,
  }) : activities = List.unmodifiable(activities),
       categorySummaries = UnmodifiableMapView(Map.of(categorySummaries));

  final int initialEstimate;
  final int currentEstimate;
  final EstimatedEnergyBand band;
  final List<ProjectedEstimatedActivity> activities;
  final int totalConsumption;
  final int totalRecovery;
  final Map<ActivityCategory, CategoryEstimatedSummary> categorySummaries;
  final EffectiveDayKind effectiveDayKind;

  bool get isStandardEffectiveDay =>
      effectiveDayKind == EffectiveDayKind.standard;
  bool get isWeakEffectiveDay => effectiveDayKind == EffectiveDayKind.weak;
}

final class CurrentDayProjector {
  const CurrentDayProjector({this.calculator = const EnergyCalculator()});

  final EnergyCalculator calculator;

  EstimatedDayProjection project({
    required int initialEstimate,
    required Iterable<EstimatedActivityRecord> records,
    required bool morningCheckInCompleted,
  }) {
    final activeRecords = records.where((record) => record.isActive).toList()
      ..sort(_compareRecords);

    var currentEstimate = initialEstimate;
    var totalConsumption = 0;
    var totalRecovery = 0;
    final projectedActivities = <ProjectedEstimatedActivity>[];
    final mutableSummaries = {
      for (final category in ActivityCategory.values)
        category: _MutableCategorySummary(),
    };

    for (final record in activeRecords) {
      final appliedDelta = calculator.calculateAppliedDelta(
        theoreticalDelta: record.theoreticalDelta,
        currentEstimate: currentEstimate,
        initialEstimate: initialEstimate,
      );
      currentEstimate += appliedDelta;

      if (appliedDelta < 0) {
        totalConsumption += appliedDelta.abs();
      } else if (appliedDelta > 0) {
        totalRecovery += appliedDelta;
      }

      final summary = mutableSummaries[record.category]!;
      summary.durationMinutes += record.duration.minutes;
      summary.netDelta += appliedDelta;
      summary.grossDelta += appliedDelta.abs();

      projectedActivities.add(
        ProjectedEstimatedActivity(
          record: record,
          appliedDelta: appliedDelta,
          estimateAfter: currentEstimate,
        ),
      );
    }

    return EstimatedDayProjection(
      initialEstimate: initialEstimate,
      currentEstimate: currentEstimate,
      band: calculator.calculateBand(
        currentEstimate: currentEstimate,
        initialEstimate: initialEstimate,
      ),
      activities: projectedActivities,
      totalConsumption: totalConsumption,
      totalRecovery: totalRecovery,
      categorySummaries: {
        for (final entry in mutableSummaries.entries)
          entry.key: CategoryEstimatedSummary(
            category: entry.key,
            durationMinutes: entry.value.durationMinutes,
            netDelta: entry.value.netDelta,
            grossDelta: entry.value.grossDelta,
          ),
      },
      effectiveDayKind: _effectiveDayKind(
        morningCheckInCompleted: morningCheckInCompleted,
        activeActivityCount: activeRecords.length,
      ),
    );
  }

  static int _compareRecords(
    EstimatedActivityRecord left,
    EstimatedActivityRecord right,
  ) {
    final completedComparison = left.completedAt.compareTo(right.completedAt);
    if (completedComparison != 0) {
      return completedComparison;
    }

    final createdComparison = left.createdAt.compareTo(right.createdAt);
    if (createdComparison != 0) {
      return createdComparison;
    }

    return left.id.compareTo(right.id);
  }

  static EffectiveDayKind _effectiveDayKind({
    required bool morningCheckInCompleted,
    required int activeActivityCount,
  }) {
    if (morningCheckInCompleted && activeActivityCount >= 1) {
      return EffectiveDayKind.standard;
    }
    if (!morningCheckInCompleted && activeActivityCount >= 2) {
      return EffectiveDayKind.weak;
    }
    return EffectiveDayKind.none;
  }
}

final class _MutableCategorySummary {
  int durationMinutes = 0;
  int netDelta = 0;
  int grossDelta = 0;
}
