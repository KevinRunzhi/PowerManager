import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:power_manager/app/theme/app_colors.dart';
import 'package:power_manager/app/theme/energy_palette.dart';

@immutable
class EnergyOrbParameters {
  const EnergyOrbParameters({
    required this.timeSeconds,
    required this.diameter,
    required this.ratio,
    required this.flowSpeed,
    required this.radiusScale,
    required this.activationProgress,
    required this.pulseAmount,
    required this.mistAmount,
    required this.glowAlpha,
    required this.noiseAmount,
    required this.overdrawn,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
  });

  factory EnergyOrbParameters.fromState({
    required double timeSeconds,
    required double diameter,
    required int estimate,
    required int initialEstimate,
    required bool energyActivated,
    required double activationProgress,
    required double pulseProgress,
    required bool reduceMotion,
  }) {
    final ratio = initialEstimate == 0 ? 0.0 : estimate / initialEstimate;
    final overdrawn = energyActivated && ratio < 0;
    final activation = energyActivated
        ? activationProgress.clamp(0.0, 1.0)
        : 0.0;
    final livePalette = energyActivated
        ? EnergyPalette.forRatio(ratio)
        : EnergyPalette.dormant;
    final primary = Color.lerp(
      EnergyPalette.dormant.primary,
      livePalette.primary,
      activation,
    )!;
    final secondary = Color.lerp(
      EnergyPalette.dormant.secondary,
      livePalette.secondary,
      activation,
    )!;
    final normalizedRatio = ratio.clamp(0.0, 1.0);
    final flowSpeed = reduceMotion
        ? 0.0
        : energyActivated
        ? 0.35 + 0.65 * normalizedRatio
        : 0.18;
    final breathPeriod = overdrawn ? 8.0 : 5.5;
    final breathAmplitude = reduceMotion ? 0.0 : (overdrawn ? 0.008 : 0.018);
    final pulseAmount = reduceMotion
        ? 0.0
        : math.sin(math.pi * pulseProgress.clamp(0.0, 1.0));
    final stableTime = reduceMotion ? 0.0 : timeSeconds;
    final radiusScale =
        1.0 +
        breathAmplitude * math.sin(stableTime * math.pi * 2 / breathPeriod) +
        0.03 * pulseAmount;
    final mistAmount = overdrawn ? 0.45 : 1.0;
    final baseGlow = energyActivated ? 0.12 + 0.23 * normalizedRatio : 0.10;
    final lightFactor = energyActivated ? 0.4 + 0.6 * activation : 1.0;
    final glowAlpha = (baseGlow * mistAmount * lightFactor + 0.14 * pulseAmount)
        .clamp(0.0, 0.48);

    return EnergyOrbParameters(
      timeSeconds: stableTime,
      diameter: diameter,
      ratio: ratio,
      flowSpeed: flowSpeed,
      radiusScale: radiusScale,
      activationProgress: activation,
      pulseAmount: pulseAmount,
      mistAmount: mistAmount,
      glowAlpha: glowAlpha,
      noiseAmount: overdrawn ? 0.045 : (energyActivated ? 0.075 : 0.025),
      overdrawn: overdrawn,
      primaryColor: primary,
      secondaryColor: secondary,
      backgroundColor: AppColors.backgroundBase,
    );
  }

  final double timeSeconds;
  final double diameter;
  final double ratio;
  final double flowSpeed;
  final double radiusScale;
  final double activationProgress;
  final double pulseAmount;
  final double mistAmount;
  final double glowAlpha;
  final double noiseAmount;
  final bool overdrawn;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;

  double get radius => diameter / 2 * radiusScale;
}
