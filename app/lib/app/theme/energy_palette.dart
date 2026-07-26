import 'package:flutter/material.dart';

typedef EnergyColors = ({Color primary, Color secondary});

final class EnergyPalette {
  const EnergyPalette._();

  static const dormant = (
    primary: Color(0xFF3A4152),
    secondary: Color(0xFF262C3A),
  );

  static const stops = <({double ratio, Color primary, Color secondary})>[
    (ratio: 1.00, primary: Color(0xFF5EEAD4), secondary: Color(0xFFA7F3D0)),
    (ratio: 0.80, primary: Color(0xFF5EEAD4), secondary: Color(0xFFA7F3D0)),
    (ratio: 0.65, primary: Color(0xFF7DD3FC), secondary: Color(0xFF5EEAD4)),
    (ratio: 0.50, primary: Color(0xFF7DD3FC), secondary: Color(0xFF5EEAD4)),
    (ratio: 0.37, primary: Color(0xFFFCD34D), secondary: Color(0xFF7DD3FC)),
    (ratio: 0.25, primary: Color(0xFFFCD34D), secondary: Color(0xFF7DD3FC)),
    (ratio: 0.12, primary: Color(0xFFF0A868), secondary: Color(0xFFB08968)),
    (ratio: 0.00, primary: Color(0xFFF0A868), secondary: Color(0xFFB08968)),
    (ratio: -0.30, primary: Color(0xFF9B8AB8), secondary: Color(0xFF6E6284)),
  ];

  static bool shouldActivate({
    required bool morningHandled,
    required bool hasActivities,
  }) => morningHandled || hasActivities;

  static EnergyColors forRatio(double ratio) {
    if (ratio >= stops.first.ratio) {
      return (primary: stops.first.primary, secondary: stops.first.secondary);
    }
    for (var index = 0; index < stops.length - 1; index++) {
      final upper = stops[index];
      final lower = stops[index + 1];
      if (ratio <= upper.ratio && ratio >= lower.ratio) {
        final distance = upper.ratio - lower.ratio;
        final interpolation = distance == 0
            ? 0.0
            : (upper.ratio - ratio) / distance;
        return (
          primary: _lerpRgb(upper.primary, lower.primary, interpolation),
          secondary: _lerpRgb(upper.secondary, lower.secondary, interpolation),
        );
      }
    }
    return (primary: stops.last.primary, secondary: stops.last.secondary);
  }

  static Color _lerpRgb(Color from, Color to, double amount) {
    final fromArgb = from.toARGB32();
    final toArgb = to.toARGB32();
    return Color.fromARGB(
      _lerpChannel(fromArgb >> 24, toArgb >> 24, amount),
      _lerpChannel(fromArgb >> 16, toArgb >> 16, amount),
      _lerpChannel(fromArgb >> 8, toArgb >> 8, amount),
      _lerpChannel(fromArgb, toArgb, amount),
    );
  }

  static int _lerpChannel(int from, int to, double amount) =>
      ((from & 0xFF) + ((to & 0xFF) - (from & 0xFF)) * amount).round();
}
