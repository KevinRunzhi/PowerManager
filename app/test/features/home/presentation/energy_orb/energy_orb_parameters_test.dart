import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/app/theme/energy_palette.dart';
import 'package:power_manager/features/home/presentation/energy_orb/energy_orb_parameters.dart';

void main() {
  group('EnergyOrbParameters', () {
    const ratios = <double>[
      1.20,
      1.00,
      0.80,
      0.65,
      0.50,
      0.37,
      0.25,
      0.12,
      0.00,
      -0.10,
      -0.30,
    ];

    for (final ratio in ratios) {
      test('uses the shared palette at ratio $ratio', () {
        final estimate = (ratio * 100).round();
        final parameters = _parameters(
          estimate: estimate,
          activationProgress: 1,
        );
        final expected = EnergyPalette.forRatio(estimate / 100);

        expect(parameters.primaryColor, expected.primary);
        expect(parameters.secondaryColor, expected.secondary);
      });
    }

    test('keeps initial estimate zero finite', () {
      final parameters = _parameters(estimate: 60, initialEstimate: 0);

      expect(parameters.ratio, 0);
      expect(parameters.flowSpeed, closeTo(0.35, 0.0001));
      expect(parameters.radius.isFinite, isTrue);
      expect(parameters.glowAlpha.isFinite, isTrue);
    });

    test('dormant state is dim and slow', () {
      final parameters = _parameters(
        estimate: 80,
        energyActivated: false,
        activationProgress: 0,
      );

      expect(parameters.primaryColor, EnergyPalette.dormant.primary);
      expect(parameters.secondaryColor, EnergyPalette.dormant.secondary);
      expect(parameters.flowSpeed, 0.18);
      expect(parameters.activationProgress, 0);
      expect(parameters.glowAlpha, closeTo(0.1, 0.0001));
    });

    test('overdraft uses slow mist state and shallow breath', () {
      final parameters = _parameters(estimate: -20, timeSeconds: 2);

      expect(parameters.overdrawn, isTrue);
      expect(parameters.flowSpeed, 0.35);
      expect(parameters.mistAmount, 0.45);
      expect(parameters.noiseAmount, 0.045);
      expect((parameters.radiusScale - 1).abs(), lessThanOrEqualTo(0.0081));
    });

    test('reduced motion freezes phase, breath, and pulse', () {
      final parameters = _parameters(
        timeSeconds: 123,
        pulseProgress: 0.5,
        reduceMotion: true,
      );

      expect(parameters.timeSeconds, 0);
      expect(parameters.flowSpeed, 0);
      expect(parameters.radiusScale, 1);
      expect(parameters.pulseAmount, 0);
    });

    test('pulse is bounded to a three percent expansion', () {
      final parameters = _parameters(pulseProgress: 0.5);
      final breathOnly = 0.018 * math.sin(0);

      expect(parameters.pulseAmount, closeTo(1, 0.0001));
      expect(parameters.radiusScale, closeTo(1.03 + breathOnly, 0.0001));
    });
  });
}

EnergyOrbParameters _parameters({
  double timeSeconds = 0,
  double diameter = 200,
  int estimate = 80,
  int initialEstimate = 100,
  bool energyActivated = true,
  double activationProgress = 1,
  double pulseProgress = 0,
  bool reduceMotion = false,
}) => EnergyOrbParameters.fromState(
  timeSeconds: timeSeconds,
  diameter: diameter,
  estimate: estimate,
  initialEstimate: initialEstimate,
  energyActivated: energyActivated,
  activationProgress: activationProgress,
  pulseProgress: pulseProgress,
  reduceMotion: reduceMotion,
);
