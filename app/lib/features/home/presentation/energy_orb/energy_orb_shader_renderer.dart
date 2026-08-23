import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:power_manager/features/home/presentation/energy_orb/energy_orb_fallback_painter.dart';
import 'package:power_manager/features/home/presentation/energy_orb/energy_orb_parameters.dart';

final class EnergyOrbShaderProgram {
  EnergyOrbShaderProgram._();

  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram>? _loading;

  static Future<ui.FragmentProgram> load() {
    final cached = _program;
    if (cached != null) {
      return Future.value(cached);
    }
    return _loading ??= ui.FragmentProgram.fromAsset('shaders/energy_orb.frag')
        .then((program) {
          _program = program;
          _loading = null;
          return program;
        })
        .catchError((Object error) {
          _loading = null;
          throw error;
        });
  }
}

class EnergyOrbShaderPainter extends CustomPainter {
  EnergyOrbShaderPainter({
    required Listenable repaint,
    required this.shader,
    required this.resolveParameters,
  }) : _fallback = EnergyOrbFallbackPainter(
         repaint: repaint,
         resolveParameters: resolveParameters,
       ),
       super(repaint: repaint);

  final ui.FragmentShader shader;
  final EnergyOrbParameterResolver resolveParameters;
  final EnergyOrbFallbackPainter _fallback;
  bool _shaderFailed = false;

  @override
  void paint(Canvas canvas, Size size) {
    final parameters = resolveParameters(size);
    if (_shaderFailed) {
      _fallback.paintFrame(canvas, size, parameters);
      return;
    }

    try {
      _writeUniforms(shader, size, parameters);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..isAntiAlias = true
          ..shader = shader,
      );
    } catch (error, stackTrace) {
      _shaderFailed = true;
      if (kDebugMode) {
        debugPrint('Energy orb shader paint failed; using fallback: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      _fallback.paintFrame(canvas, size, parameters);
    }
  }

  // Keep this order identical to app/shaders/energy_orb.frag.
  void _writeUniforms(
    ui.FragmentShader target,
    Size size,
    EnergyOrbParameters parameters,
  ) {
    var index = 0;
    target
      ..setFloat(index++, size.width)
      ..setFloat(index++, size.height)
      ..setFloat(index++, parameters.timeSeconds)
      ..setFloat(index++, size.width / 2)
      ..setFloat(index++, size.height / 2)
      ..setFloat(index++, parameters.radius)
      ..setFloat(index++, parameters.flowSpeed)
      ..setFloat(index++, parameters.activationProgress)
      ..setFloat(index++, parameters.pulseAmount)
      ..setFloat(index++, parameters.mistAmount)
      ..setFloat(index++, parameters.overdrawn ? 1.0 : 0.0);
    index = _writeColor(target, index, parameters.primaryColor);
    index = _writeColor(target, index, parameters.secondaryColor);
    index = _writeColor(target, index, parameters.backgroundColor);
    target
      ..setFloat(index++, parameters.glowAlpha)
      ..setFloat(index, parameters.noiseAmount);
  }

  int _writeColor(ui.FragmentShader target, int start, Color color) {
    target
      ..setFloat(start, color.r)
      ..setFloat(start + 1, color.g)
      ..setFloat(start + 2, color.b)
      ..setFloat(start + 3, color.a);
    return start + 4;
  }

  @override
  bool shouldRepaint(EnergyOrbShaderPainter oldDelegate) =>
      oldDelegate.shader != shader ||
      oldDelegate.resolveParameters != resolveParameters;
}
