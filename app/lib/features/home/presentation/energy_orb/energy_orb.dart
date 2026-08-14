import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:power_manager/app/theme/app_spacing.dart';
import 'package:power_manager/features/home/presentation/energy_orb/energy_orb_fallback_painter.dart';
import 'package:power_manager/features/home/presentation/energy_orb/energy_orb_parameters.dart';
import 'package:power_manager/features/home/presentation/energy_orb/energy_orb_shader_renderer.dart';

class EnergyOrb extends StatefulWidget {
  const EnergyOrb({
    super.key,
    required this.estimate,
    required this.initialEstimate,
    required this.energyActivated,
    required this.morningCompleted,
    this.shaderEnabled = true,
    this.diameterOverride,
    this.timeOverride,
  });

  final int estimate;
  final int initialEstimate;
  final bool energyActivated;
  final bool morningCompleted;
  final bool shaderEnabled;
  final double? diameterOverride;
  final double? timeOverride;

  @override
  State<EnergyOrb> createState() => _EnergyOrbState();
}

class _EnergyOrbState extends State<EnergyOrb>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _flow;
  late final AnimationController _activation;
  late final AnimationController _pulse;
  late final Listenable _repaint;
  ui.FragmentShader? _shader;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _flow = AnimationController(
      vsync: this,
      duration: const Duration(hours: 24),
    )..repeat();
    _activation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: widget.energyActivated ? 1 : 0,
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _repaint = Listenable.merge([_flow, _activation, _pulse]);
    if (widget.shaderEnabled) {
      unawaited(_loadShader());
    }
  }

  Future<void> _loadShader() async {
    try {
      final program = await EnergyOrbShaderProgram.load();
      if (!mounted || !widget.shaderEnabled) {
        return;
      }
      setState(() => _shader = program.fragmentShader());
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Energy orb shader unavailable; using fallback: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) {
      return;
    }
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _flow
        ..stop()
        ..value = 0;
      _activation
        ..stop()
        ..value = widget.energyActivated ? 1 : 0;
      _pulse
        ..stop()
        ..value = 0;
    } else {
      _flow.repeat();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_reduceMotion) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _flow.repeat();
      if (_activation.value < 1 && widget.energyActivated) {
        _activation.forward();
      }
      if (_pulse.value > 0 && _pulse.value < 1) {
        _pulse.forward();
      }
      return;
    }
    _flow.stop();
    _activation.stop();
    _pulse.stop();
  }

  @override
  void didUpdateWidget(EnergyOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shaderEnabled != widget.shaderEnabled) {
      if (widget.shaderEnabled && _shader == null) {
        unawaited(_loadShader());
      } else if (!widget.shaderEnabled) {
        _shader = null;
      }
    }
    if (oldWidget.energyActivated != widget.energyActivated) {
      if (_reduceMotion) {
        _activation.value = widget.energyActivated ? 1 : 0;
      } else if (widget.energyActivated) {
        _activation.forward(from: 0);
      } else {
        _activation.value = 0;
      }
    }
    if (oldWidget.estimate != widget.estimate && widget.energyActivated) {
      if (_reduceMotion) {
        _pulse.value = 0;
      } else {
        _pulse.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flow.dispose();
    _activation.dispose();
    _pulse.dispose();
    super.dispose();
  }

  EnergyOrbParameters _resolveParameters(Size size, double diameter) {
    return EnergyOrbParameters.fromState(
      timeSeconds:
          widget.timeOverride ??
          _flow.value * _flow.duration!.inMilliseconds / 1000,
      diameter: diameter,
      estimate: widget.estimate,
      initialEstimate: widget.initialEstimate,
      energyActivated: widget.energyActivated,
      activationProgress: _activation.value,
      pulseProgress: _pulse.value,
      reduceMotion: _reduceMotion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final diameter =
        widget.diameterOverride ??
        math
            .min(viewport.width * 0.58, viewport.height * 0.34)
            .clamp(132.0, 260.0);
    final shader = _shader;
    EnergyOrbParameters resolveParameters(Size size) =>
        _resolveParameters(size, diameter);
    final painter = shader == null
        ? EnergyOrbFallbackPainter(
            repaint: _repaint,
            resolveParameters: resolveParameters,
          )
        : EnergyOrbShaderPainter(
            repaint: _repaint,
            shader: shader,
            resolveParameters: resolveParameters,
          );

    return Center(
      child: Semantics(
        label: '估计精力 ${widget.estimate}',
        readOnly: true,
        child: SizedBox(
          width: viewport.width,
          height: diameter,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: -diameter * 0.38,
                bottom: -diameter * 0.38,
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const Key('energy-orb-renderer'),
                    painter: painter,
                  ),
                ),
              ),
              SizedBox(
                width: diameter * 0.82,
                height: diameter * 0.62,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.morningCompleted ? '估计精力' : '估计精力 · 未晨间确认',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(letterSpacing: 2.2),
                      ),
                      const SizedBox(height: AppSpacing.unit),
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: widget.estimate.toDouble()),
                        duration: _reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 620),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => Text(
                          '${value.round()}',
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(fontSize: diameter < 160 ? 42 : 64),
                        ),
                      ),
                      if (widget.estimate < 0) ...[
                        const SizedBox(height: 6),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0x669B8AB8)),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            child: Text(
                              '估计透支',
                              style: TextStyle(
                                color: Color(0xFF9B8AB8),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
