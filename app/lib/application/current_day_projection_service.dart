import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_calculator.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

final class CurrentDayProjection {
  const CurrentDayProjection({
    required this.lifeDay,
    required this.baseEstimatedEnergy,
    required this.ruleVersion,
    this.personalizationVersionId = fixedMvpAPersonalizationVersion,
    this.effectiveModelFingerprint = fixedMvpAEffectiveModelFingerprint,
    this.modelRegimeEpoch = fixedMvpAInitialModelRegimeEpoch,
    required this.morningAdjustment,
    required this.shortTermAdjustment,
    required this.previousFinalEstimate,
    required this.morningCheckInCompleted,
    required this.projection,
  });

  final LifeDay lifeDay;
  final int baseEstimatedEnergy;
  final String ruleVersion;
  final String personalizationVersionId;
  final String effectiveModelFingerprint;
  final String modelRegimeEpoch;
  final int morningAdjustment;
  final int shortTermAdjustment;
  final int? previousFinalEstimate;
  final bool morningCheckInCompleted;
  final EstimatedDayProjection projection;
}

final class CurrentDayProjectionService {
  const CurrentDayProjectionService({
    required this.morningCheckIns,
    required this.activities,
    required this.summaries,
    this.calculator = const EnergyCalculator(),
    this.projector = const CurrentDayProjector(),
  });

  final MorningCheckInsRepository morningCheckIns;
  final ActivityRecordsRepository activities;
  final DailySummariesRepository summaries;
  final EnergyCalculator calculator;
  final CurrentDayProjector projector;

  Future<CurrentDayProjection> project({
    required LifeDay lifeDay,
    required int baseEstimatedEnergy,
    required String ruleVersion,
    String personalizationVersionId = fixedMvpAPersonalizationVersion,
    String effectiveModelFingerprint = fixedMvpAEffectiveModelFingerprint,
    String modelRegimeEpoch = fixedMvpAInitialModelRegimeEpoch,
  }) async {
    final morning = await morningCheckIns.findByLifeDay(lifeDay);
    final previous = await summaries.findByLifeDay(lifeDay.previous);
    final records = await activities.listActiveForLifeDay(lifeDay);

    final wrongVersion = records
        .where((record) => record.ruleVersion != ruleVersion)
        .firstOrNull;
    if (wrongVersion != null) {
      throw StateError(
        'Activity ${wrongVersion.id} uses rule ${wrongVersion.ruleVersion}, '
        'but $lifeDay uses $ruleVersion',
      );
    }

    final shortTermAdjustment = calculator.calculateShortTermAdjustment(
      previous?.finalEstimatedEnergy,
    );
    final morningAdjustment = morning?.morningAdjustment ?? 0;
    final initialEstimate =
        baseEstimatedEnergy + morningAdjustment + shortTermAdjustment;

    return CurrentDayProjection(
      lifeDay: lifeDay,
      baseEstimatedEnergy: baseEstimatedEnergy,
      ruleVersion: ruleVersion,
      personalizationVersionId: personalizationVersionId,
      effectiveModelFingerprint: effectiveModelFingerprint,
      modelRegimeEpoch: modelRegimeEpoch,
      morningAdjustment: morningAdjustment,
      shortTermAdjustment: shortTermAdjustment,
      previousFinalEstimate: previous?.finalEstimatedEnergy,
      morningCheckInCompleted: morning != null,
      projection: projector.project(
        initialEstimate: initialEstimate,
        records: records.map((record) => record.toReplayRecord()),
        morningCheckInCompleted: morning != null,
      ),
    );
  }
}
