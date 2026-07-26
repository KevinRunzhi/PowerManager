import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/app/theme/energy_palette.dart';

void main() {
  test('matches every HTML palette stop exactly', () {
    const expected = <(double, int, int)>[
      (1.00, 0xFF5EEAD4, 0xFFA7F3D0),
      (0.80, 0xFF5EEAD4, 0xFFA7F3D0),
      (0.65, 0xFF7DD3FC, 0xFF5EEAD4),
      (0.50, 0xFF7DD3FC, 0xFF5EEAD4),
      (0.37, 0xFFFCD34D, 0xFF7DD3FC),
      (0.25, 0xFFFCD34D, 0xFF7DD3FC),
      (0.12, 0xFFF0A868, 0xFFB08968),
      (0.00, 0xFFF0A868, 0xFFB08968),
      (-0.30, 0xFF9B8AB8, 0xFF6E6284),
    ];

    for (final stop in expected) {
      final colors = EnergyPalette.forRatio(stop.$1);
      expect(colors.primary.toARGB32(), stop.$2);
      expect(colors.secondary.toARGB32(), stop.$3);
    }
  });

  test('uses the same per-channel interpolation as the HTML prototype', () {
    final colors = EnergyPalette.forRatio(0.725);

    expect(colors.primary, const Color(0xFF6EDFE8));
    expect(colors.secondary, const Color(0xFF82EFD2));
  });

  test('clamps ratios beyond the HTML palette range', () {
    expect(EnergyPalette.forRatio(1.4), EnergyPalette.forRatio(1));
    expect(EnergyPalette.forRatio(-1), EnergyPalette.forRatio(-0.3));
  });

  test('activates after morning handling or the first activity', () {
    expect(
      EnergyPalette.shouldActivate(morningHandled: false, hasActivities: false),
      isFalse,
    );
    expect(
      EnergyPalette.shouldActivate(morningHandled: true, hasActivities: false),
      isTrue,
    );
    expect(
      EnergyPalette.shouldActivate(morningHandled: false, hasActivities: true),
      isTrue,
    );
  });
}
