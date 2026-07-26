import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

final class SettlementService {
  const SettlementService({
    required this.morningCheckIns,
    required this.activities,
    required this.observations,
    required this.summaries,
    required this.projectionService,
  });

  final MorningCheckInsRepository morningCheckIns;
  final ActivityRecordsRepository activities;
  final EnergyObservationsRepository observations;
  final DailySummariesRepository summaries;
  final CurrentDayProjectionService projectionService;

  Future<List<DailySummary>> settleBefore({
    required LifeDay currentLifeDay,
    required int baseEstimatedEnergy,
    required String ruleVersion,
    required DateTime settledAt,
  }) async {
    final candidateDays = <LifeDay>{
      for (final checkIn in await morningCheckIns.list()) checkIn.lifeDay,
      for (final activity in await activities.listAllForExport())
        if (activity.status == ActivityRecordStatus.active) activity.lifeDay,
      for (final observation in await observations.list()) observation.lifeDay,
    }.where((day) => day.compareTo(currentLifeDay) < 0).toList()..sort();
    final existingDays = {
      for (final summary in await summaries.list()) summary.lifeDay,
    };

    final settled = <DailySummary>[];
    for (final lifeDay in candidateDays) {
      if (existingDays.contains(lifeDay)) {
        continue;
      }
      final result = await projectionService.project(
        lifeDay: lifeDay,
        baseEstimatedEnergy: baseEstimatedEnergy,
        ruleVersion: ruleVersion,
      );
      final projection = result.projection;
      final summary = await summaries.insertOrGet(
        DailySummary(
          lifeDay: lifeDay,
          baseEstimatedEnergy: baseEstimatedEnergy,
          ruleVersion: ruleVersion,
          morningAdjustment: result.morningAdjustment,
          shortTermAdjustment: result.shortTermAdjustment,
          initialEstimatedEnergy: projection.initialEstimate,
          finalEstimatedEnergy: projection.currentEstimate,
          totalConsumption: projection.totalConsumption,
          totalRecovery: projection.totalRecovery,
          categorySummaries: projection.categorySummaries,
          isStandardEffectiveDay: projection.isStandardEffectiveDay,
          isWeakEffectiveDay: projection.isWeakEffectiveDay,
          settledAt: settledAt,
        ),
      );
      settled.add(summary);
      existingDays.add(lifeDay);
    }
    return settled;
  }
}
