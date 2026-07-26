import 'dart:math' as math;

import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';

final class EnergyCalculator {
  const EnergyCalculator();

  int calculateMorningAdjustment(MorningOverallState state) {
    return state.adjustment;
  }

  int calculateInitialEstimate({
    required int baseEstimatedEnergy,
    required MorningOverallState morningState,
    required int shortTermAdjustment,
  }) {
    return baseEstimatedEnergy +
        calculateMorningAdjustment(morningState) +
        shortTermAdjustment;
  }

  int calculateTheoreticalDelta({
    required EnergyRuleConfig config,
    required ActivitySubcategory subcategory,
    required DurationSlot duration,
  }) {
    return config.theoreticalDelta(subcategory, duration);
  }

  int calculateAppliedDelta({
    required int theoreticalDelta,
    required int currentEstimate,
    required int initialEstimate,
  }) {
    if (theoreticalDelta <= 0) {
      return theoreticalDelta;
    }

    final availableRecovery = math.max(0, initialEstimate - currentEstimate);
    return math.min(theoreticalDelta, availableRecovery);
  }

  EstimatedEnergyBand calculateBand({
    required int currentEstimate,
    required int initialEstimate,
  }) {
    if (initialEstimate <= 0) {
      throw ArgumentError.value(
        initialEstimate,
        'initialEstimate',
        'Band thresholds require a positive initial estimate',
      );
    }
    if (currentEstimate < 0) {
      return EstimatedEnergyBand.estimatedOverdraft;
    }
    if (currentEstimate * 4 < initialEstimate) {
      return EstimatedEnergyBand.estimatedLow;
    }
    if (currentEstimate * 2 < initialEstimate) {
      return EstimatedEnergyBand.estimatedMediumLow;
    }
    return EstimatedEnergyBand.estimatedNormal;
  }

  int calculateShortTermAdjustment(int? previousFinalEstimate) {
    if (previousFinalEstimate == null || previousFinalEstimate >= 0) {
      return 0;
    }
    if (previousFinalEstimate >= -5) {
      return -1;
    }
    if (previousFinalEstimate >= -10) {
      return -2;
    }
    if (previousFinalEstimate >= -20) {
      return -3;
    }
    return -4;
  }
}
