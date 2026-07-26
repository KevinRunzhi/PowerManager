import 'package:power_manager/domain/energy/energy_calculator.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:test/test.dart';

void main() {
  const calculator = EnergyCalculator();

  group('initial estimate', () {
    test('morning states map to -6, 0, and +6; skipped is neutral', () {
      expect(
        calculator.calculateMorningAdjustment(MorningOverallState.bad),
        -6,
      );
      expect(
        calculator.calculateMorningAdjustment(MorningOverallState.normal),
        0,
      );
      expect(
        calculator.calculateMorningAdjustment(MorningOverallState.good),
        6,
      );
      expect(
        calculator.calculateMorningAdjustment(MorningOverallState.skipped),
        0,
      );
    });

    test(
      'combines base estimate, morning state, and short-term adjustment',
      () {
        expect(
          calculator.calculateInitialEstimate(
            baseEstimatedEnergy: 100,
            morningState: MorningOverallState.good,
            shortTermAdjustment: -3,
          ),
          103,
        );
      },
    );

    test('does not treat 100 as an upper limit', () {
      expect(
        calculator.calculateInitialEstimate(
          baseEstimatedEnergy: 140,
          morningState: MorningOverallState.good,
          shortTermAdjustment: 0,
        ),
        146,
      );
    });
  });

  group('short-term overdraft adjustment', () {
    test('is neutral without an adjacent previous summary', () {
      expect(calculator.calculateShortTermAdjustment(null), 0);
    });

    test('covers all five intervals and their boundaries', () {
      final examples = <int, int>{
        12: 0,
        0: 0,
        -1: -1,
        -5: -1,
        -6: -2,
        -10: -2,
        -11: -3,
        -20: -3,
        -21: -4,
        -100: -4,
      };

      for (final MapEntry(key: finalEstimate, value: expected)
          in examples.entries) {
        expect(
          calculator.calculateShortTermAdjustment(finalEstimate),
          expected,
          reason: 'previous final estimate $finalEstimate',
        );
      }
    });
  });

  group('activity deltas', () {
    test('reads theoretical delta from the selected rule version', () {
      expect(
        calculator.calculateTheoreticalDelta(
          config: EnergyRuleConfig.v2MvpA(),
          subcategory: ActivitySubcategory.nap,
          duration: DurationSlot.minutes30,
        ),
        10,
      );
    });

    test('recovery at the initial estimate is fully capped', () {
      expect(
        calculator.calculateAppliedDelta(
          theoreticalDelta: 10,
          currentEstimate: 100,
          initialEstimate: 100,
        ),
        0,
      );
    });

    test('recovery is partially capped at the initial estimate', () {
      expect(
        calculator.calculateAppliedDelta(
          theoreticalDelta: 10,
          currentEstimate: 96,
          initialEstimate: 100,
        ),
        4,
      );
    });

    test('a defensive cap never converts recovery into consumption', () {
      expect(
        calculator.calculateAppliedDelta(
          theoreticalDelta: 10,
          currentEstimate: 104,
          initialEstimate: 100,
        ),
        0,
      );
    });

    test('consumption is not capped and can enter negative estimates', () {
      expect(
        calculator.calculateAppliedDelta(
          theoreticalDelta: -30,
          currentEstimate: 10,
          initialEstimate: 100,
        ),
        -30,
      );
    });
  });

  group('estimated energy bands', () {
    test('uses exact overdraft, 25%, and 50% boundaries', () {
      expect(
        calculator.calculateBand(currentEstimate: -1, initialEstimate: 100),
        EstimatedEnergyBand.estimatedOverdraft,
      );
      expect(
        calculator.calculateBand(currentEstimate: 0, initialEstimate: 100),
        EstimatedEnergyBand.estimatedLow,
      );
      expect(
        calculator.calculateBand(currentEstimate: 24, initialEstimate: 100),
        EstimatedEnergyBand.estimatedLow,
      );
      expect(
        calculator.calculateBand(currentEstimate: 25, initialEstimate: 100),
        EstimatedEnergyBand.estimatedMediumLow,
      );
      expect(
        calculator.calculateBand(currentEstimate: 49, initialEstimate: 100),
        EstimatedEnergyBand.estimatedMediumLow,
      );
      expect(
        calculator.calculateBand(currentEstimate: 50, initialEstimate: 100),
        EstimatedEnergyBand.estimatedNormal,
      );
    });

    test('uses integer cross multiplication for non-divisible estimates', () {
      expect(
        calculator.calculateBand(currentEstimate: 25, initialEstimate: 101),
        EstimatedEnergyBand.estimatedLow,
      );
      expect(
        calculator.calculateBand(currentEstimate: 26, initialEstimate: 101),
        EstimatedEnergyBand.estimatedMediumLow,
      );
      expect(
        calculator.calculateBand(currentEstimate: 50, initialEstimate: 101),
        EstimatedEnergyBand.estimatedMediumLow,
      );
      expect(
        calculator.calculateBand(currentEstimate: 51, initialEstimate: 101),
        EstimatedEnergyBand.estimatedNormal,
      );
    });
  });
}
