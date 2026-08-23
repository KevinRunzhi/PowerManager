import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:power_manager/features/home/presentation/energy_orb/energy_orb_parameters.dart';

typedef EnergyOrbParameterResolver = EnergyOrbParameters Function(Size size);

class EnergyOrbFallbackPainter extends CustomPainter {
  EnergyOrbFallbackPainter({
    required Listenable repaint,
    required this.resolveParameters,
  }) : super(repaint: repaint);

  final EnergyOrbParameterResolver resolveParameters;

  @override
  void paint(Canvas canvas, Size size) {
    paintFrame(canvas, size, resolveParameters(size));
  }

  void paintFrame(Canvas canvas, Size size, EnergyOrbParameters parameters) {
    final center = size.center(Offset.zero);
    final radius = parameters.radius;
    final time = parameters.timeSeconds;
    final flow = parameters.flowSpeed;
    final primary = parameters.primaryColor;
    final secondary = parameters.secondaryColor;

    final glowRect = Rect.fromCircle(center: center, radius: radius * 1.65);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            primary.withValues(alpha: parameters.glowAlpha),
            primary.withValues(alpha: 0),
          ],
        ).createShader(glowRect),
    );

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Color.lerp(
          parameters.backgroundColor,
          primary,
          0.08 + 0.08 * parameters.activationProgress,
        )!,
    );

    final phase = time * flow;
    _drawBlob(
      canvas,
      center +
          Offset(
            radius * 0.38 * math.cos(phase * 0.9),
            radius * 0.30 * math.sin(phase * 1.25),
          ),
      radius * (parameters.overdrawn ? 1.1 : 0.95),
      primary,
      0.50 * parameters.mistAmount,
    );
    _drawBlob(
      canvas,
      center -
          Offset(
            radius * 0.32 * math.cos(phase * 0.7 + 2),
            radius * 0.36 * math.sin(phase * 0.95 + 1),
          ),
      radius * (parameters.overdrawn ? 1.05 : 0.9),
      secondary,
      0.42 * parameters.mistAmount,
    );
    _drawBlob(
      canvas,
      center +
          Offset(
            radius * 0.15 * math.sin(phase * 0.5),
            radius * 0.42 * math.cos(phase * 0.62),
          ),
      radius * 0.7,
      secondary,
      0.25 * parameters.mistAmount,
    );
    canvas.restore();

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = primary.withValues(
          alpha:
              (0.08 + 0.14 * parameters.activationProgress) *
              parameters.mistAmount,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawBlob(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double alpha,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(EnergyOrbFallbackPainter oldDelegate) =>
      oldDelegate.resolveParameters != resolveParameters;
}
