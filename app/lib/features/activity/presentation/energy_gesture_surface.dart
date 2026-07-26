import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/features/activity/application/record_gesture_controller.dart';

typedef GestureRecordCallback =
    Future<void> Function(RecordGestureSelection selection);

class EnergyGestureSurface extends StatefulWidget {
  const EnergyGestureSurface({
    required this.child,
    required this.onConfirmed,
    super.key,
  });

  final Widget child;
  final GestureRecordCallback onConfirmed;

  @override
  State<EnergyGestureSurface> createState() => _EnergyGestureSurfaceState();
}

class _EnergyGestureSurfaceState extends State<EnergyGestureSurface> {
  static const _categoryDwell = Duration(milliseconds: 280);
  static const _durationDwell = Duration(milliseconds: 160);
  static const _backCooldown = Duration(milliseconds: 220);

  final _controller = RecordGestureController();
  OverlayEntry? _overlay;
  Timer? _timeout;
  Timer? _dwell;
  Timer? _cleanupTimer;
  Offset _center = Offset.zero;
  double _ballRadius = 116;
  int? _hotIndex;
  DateTime _lastLayerChange = DateTime.fromMillisecondsSinceEpoch(0);
  bool _visible = true;
  Offset? _completionOrigin;
  RecordGestureState _displayState = const RecordGestureState.idle();

  @override
  void dispose() {
    _timeout?.cancel();
    _dwell?.cancel();
    _cleanupTimer?.cancel();
    _overlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      key: const Key('energy-gesture-surface'),
      behavior: HitTestBehavior.opaque,
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: const Duration(milliseconds: 120),
              ),
              (recognizer) {
                recognizer
                  ..onLongPressStart = _start
                  ..onLongPressMoveUpdate = _update
                  ..onLongPressEnd = _finish
                  ..onLongPressCancel = _cancel;
              },
            ),
      },
      child: widget.child,
    );
  }

  void _start(LongPressStartDetails details) {
    if (_overlay != null) {
      _cleanup();
    }
    final box = context.findRenderObject()! as RenderBox;
    _center = box.localToGlobal(box.size.center(Offset.zero));
    _ballRadius = math
        .min(box.size.width * 0.29, box.size.height * 0.5)
        .clamp(66, 130);
    _controller.start();
    _displayState = _controller.state;
    _hotIndex = null;
    _visible = true;
    _completionOrigin = null;
    _lastLayerChange = DateTime.now();
    HapticFeedback.lightImpact();
    _overlay = OverlayEntry(
      builder: (overlayContext) => IgnorePointer(
        child: _GestureOverlay(
          key: const Key('record-gesture-overlay'),
          center: _center,
          ballRadius: _ballRadius,
          state: _displayState,
          hotIndex: _hotIndex,
          dwellDuration: _dwellDuration,
          visible: _visible,
          completionOrigin: _completionOrigin,
          reduceMotion:
              MediaQuery.maybeOf(overlayContext)?.disableAnimations ?? false,
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
    _restartTimeout();
  }

  Duration get _dwellDuration =>
      _displayState.phase == RecordGesturePhase.selectingDuration ||
          _displayState.phase == RecordGesturePhase.ready
      ? _durationDwell
      : _categoryDwell;

  void _update(LongPressMoveUpdateDetails details) {
    if (_overlay == null) {
      return;
    }
    final pointer = details.globalPosition;
    final distanceFromCenter = (pointer - _center).distance;
    final canGoBack =
        DateTime.now().difference(_lastLayerChange) >= _backCooldown;
    if (distanceFromCenter < _ballRadius * 0.55 && canGoBack) {
      if (_controller.back()) {
        _dwell?.cancel();
        _hotIndex = null;
        _displayState = _controller.state;
        _lastLayerChange = DateTime.now();
        HapticFeedback.selectionClick();
        _overlay?.markNeedsBuild();
      }
      _restartTimeout();
      return;
    }

    final nodes = _RecordGestureLayout.nodes(
      state: _controller.state,
      center: _center,
      ballRadius: _ballRadius,
      viewport: MediaQuery.sizeOf(context),
    );
    final nextHot = _hitTest(pointer, nodes);
    if (nextHot != _hotIndex) {
      _setHot(nextHot);
    }
    _restartTimeout();
  }

  int? _hitTest(Offset pointer, List<_GestureNode> nodes) {
    final current = _hotIndex;
    if (current != null && current < nodes.length) {
      final stickyNode = nodes[current];
      if ((pointer - stickyNode.center).distance <=
          stickyNode.diameter / 2 + 30) {
        return current;
      }
    }
    for (final node in nodes) {
      if ((pointer - node.center).distance <= node.diameter / 2 + 16) {
        return node.index;
      }
    }
    return null;
  }

  void _setHot(int? index) {
    _dwell?.cancel();
    _hotIndex = index;
    _controller.setHotIndex(index);
    _displayState = _controller.state;
    _overlay?.markNeedsBuild();
    if (index == null) {
      return;
    }
    HapticFeedback.selectionClick();
    final phaseAtStart = _controller.state.phase;
    final duration = _dwellDuration;
    _dwell = Timer(duration, () {
      if (_hotIndex != index || _controller.state.phase != phaseAtStart) {
        return;
      }
      _controller.confirmHot();
      _displayState = _controller.state;
      if (_controller.state.phase != RecordGesturePhase.ready) {
        _hotIndex = null;
        _lastLayerChange = DateTime.now();
      }
      _overlay?.markNeedsBuild();
      HapticFeedback.selectionClick();
    });
  }

  void _finish(LongPressEndDetails details) {
    _dwell?.cancel();
    final stateBeforeFinish = _controller.state;
    final nodes = _RecordGestureLayout.nodes(
      state: stateBeforeFinish,
      center: _center,
      ballRadius: _ballRadius,
      viewport: MediaQuery.sizeOf(context),
    );
    final origin = _hotIndex != null && _hotIndex! < nodes.length
        ? nodes[_hotIndex!].center
        : null;
    final selection = _controller.finish();
    if (selection == null || origin == null) {
      _dismissAnimated();
      return;
    }
    _displayState = stateBeforeFinish;
    _completionOrigin = origin;
    _overlay?.markNeedsBuild();
    HapticFeedback.mediumImpact();
    unawaited(widget.onConfirmed(selection));
    _cleanupTimer = Timer(const Duration(milliseconds: 540), _cleanup);
  }

  void _cancel() {
    _controller.cancel();
    _dismissAnimated();
  }

  void _restartTimeout() {
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 10), () {
      _controller.cancel();
      _dismissAnimated();
    });
  }

  void _dismissAnimated() {
    _dwell?.cancel();
    _timeout?.cancel();
    _visible = false;
    _overlay?.markNeedsBuild();
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer(const Duration(milliseconds: 240), _cleanup);
  }

  void _cleanup() {
    _timeout?.cancel();
    _dwell?.cancel();
    _cleanupTimer?.cancel();
    _timeout = null;
    _dwell = null;
    _cleanupTimer = null;
    _overlay?.remove();
    _overlay = null;
    _controller.reset();
    _displayState = const RecordGestureState.idle();
    _hotIndex = null;
    _completionOrigin = null;
  }
}

final class _GestureNode {
  const _GestureNode({
    required this.index,
    required this.label,
    required this.center,
    required this.diameter,
  });

  final int index;
  final String label;
  final Offset center;
  final double diameter;
}

final class _RecordGestureLayout {
  static List<_GestureNode> nodes({
    required RecordGestureState state,
    required Offset center,
    required double ballRadius,
    required Size viewport,
  }) {
    final (labels, diameter, radialOffset, spread) = _items(state);
    final radius = ballRadius + radialOffset;
    return List.generate(labels.length, (index) {
      final fraction = labels.length == 1 ? 0.5 : index / (labels.length - 1);
      final angle = (-90 - spread / 2 + spread * fraction) * math.pi / 180;
      final raw = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final point = Offset(
        raw.dx.clamp(diameter / 2 + 8, viewport.width - diameter / 2 - 8),
        raw.dy.clamp(diameter / 2 + 10, viewport.height - diameter / 2 - 10),
      );
      return _GestureNode(
        index: index,
        label: labels[index],
        center: point,
        diameter: diameter,
      );
    });
  }

  static (List<String>, double, double, double) _items(
    RecordGestureState state,
  ) {
    if (state.phase == RecordGesturePhase.selectingCategory) {
      return (
        ActivityCategory.values.map((item) => item.label).toList(),
        66,
        78,
        150,
      );
    }
    if (state.phase == RecordGesturePhase.selectingSubcategory) {
      final items = ActivitySubcategory.values
          .where((item) => item.category == state.category)
          .toList();
      return (items.map((item) => item.label).toList(), 58, 92, 172);
    }
    return (
      DurationSlot.values.map((item) => '${item.minutes} 分').toList(),
      54,
      96,
      172,
    );
  }
}

class _GestureOverlay extends StatelessWidget {
  const _GestureOverlay({
    required this.center,
    required this.ballRadius,
    required this.state,
    required this.hotIndex,
    required this.dwellDuration,
    required this.visible,
    required this.completionOrigin,
    required this.reduceMotion,
    super.key,
  });

  final Offset center;
  final double ballRadius;
  final RecordGestureState state;
  final int? hotIndex;
  final Duration dwellDuration;
  final bool visible;
  final Offset? completionOrigin;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final nodes = _RecordGestureLayout.nodes(
      state: state,
      center: center,
      ballRadius: ballRadius,
      viewport: viewport,
    );
    final layerKey =
        '${state.phase.name}:${state.category?.code}:${state.subcategory?.code}';
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: const Color(0x260D1017)),
          _BreadcrumbRing(
            center: center,
            radius: switch (state.phase) {
              RecordGesturePhase.selectingSubcategory => ballRadius + 36,
              RecordGesturePhase.selectingDuration ||
              RecordGesturePhase.ready => ballRadius + 52,
              _ => ballRadius,
            },
            visible:
                state.phase == RecordGesturePhase.selectingSubcategory ||
                state.phase == RecordGesturePhase.selectingDuration ||
                state.phase == RecordGesturePhase.ready,
          ),
          AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: _GestureLayer(
              key: ValueKey(layerKey),
              nodes: nodes,
              hotIndex: hotIndex,
              dwellDuration: dwellDuration,
              reduceMotion: reduceMotion,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: center.dy + ballRadius + 8,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xE60D1017),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Text(
                    _stageTip(state.phase),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      inherit: false,
                      color: Color(0xFF8A93A6),
                      fontSize: 12.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (completionOrigin != null)
            _FlyingDot(
              origin: completionOrigin!,
              target: center,
              reduceMotion: reduceMotion,
            ),
        ],
      ),
    );
  }

  static String _stageTip(RecordGesturePhase phase) => switch (phase) {
    RecordGesturePhase.selectingCategory => '滑向大类，停留确认',
    RecordGesturePhase.selectingSubcategory => '滑向子类，停留确认',
    RecordGesturePhase.selectingDuration => '滑向时长，短暂停留后松手',
    RecordGesturePhase.ready => '松手完成 · 滑回球心返回上一层',
    _ => '',
  };
}

class _GestureLayer extends StatefulWidget {
  const _GestureLayer({
    required this.nodes,
    required this.hotIndex,
    required this.dwellDuration,
    required this.reduceMotion,
    super.key,
  });

  final List<_GestureNode> nodes;
  final int? hotIndex;
  final Duration dwellDuration;
  final bool reduceMotion;

  @override
  State<_GestureLayer> createState() => _GestureLayerState();
}

class _GestureLayerState extends State<_GestureLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: widget.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 480),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: [for (final node in widget.nodes) _buildNode(node)],
      ),
    );
  }

  Widget _buildNode(_GestureNode node) {
    final start = node.index * 0.065;
    final raw = ((_entrance.value - start) / (0.76 - start)).clamp(0.0, 1.0);
    final entrance = Curves.easeOutBack.transform(raw);
    final hot = widget.hotIndex == node.index;
    final faded = widget.hotIndex != null && !hot;
    return Positioned(
      key: Key('gesture-node-${node.index}'),
      left: node.center.dx - node.diameter / 2,
      top: node.center.dy - node.diameter / 2,
      width: node.diameter,
      height: node.diameter,
      child: Opacity(
        opacity: entrance * (faded ? 0.56 : 1),
        child: Transform.scale(
          scale: entrance * (hot ? 1.11 : 1),
          child: AnimatedContainer(
            duration: widget.reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hot ? const Color(0xFF232B3C) : const Color(0xF21C2230),
              border: Border.all(
                color: hot ? const Color(0xFF7DD3FC) : const Color(0x14FFFFFF),
              ),
              boxShadow: [
                BoxShadow(
                  color: hot
                      ? const Color(0x667DD3FC)
                      : const Color(0x59000000),
                  blurRadius: hot ? 22 : 18,
                  offset: hot ? Offset.zero : const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hot)
                  TweenAnimationBuilder<double>(
                    key: ValueKey('dwell-${node.index}'),
                    tween: Tween(begin: 0, end: 1),
                    duration: widget.reduceMotion
                        ? Duration.zero
                        : widget.dwellDuration,
                    builder: (context, progress, child) =>
                        CustomPaint(painter: _DwellRingPainter(progress)),
                  ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      node.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        inherit: false,
                        color: Color(0xFFE8ECF4),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DwellRingPainter extends CustomPainter {
  const _DwellRingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
      Offset.zero & size,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = const Color(0xFF7DD3FC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DwellRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BreadcrumbRing extends StatelessWidget {
  const _BreadcrumbRing({
    required this.center,
    required this.radius,
    required this.visible,
  });

  final Offset center;
  final double radius;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      left: center.dx - radius,
      top: center.dy - radius,
      width: radius * 2,
      height: radius * 2,
      child: AnimatedOpacity(
        opacity: visible ? 0.6 : 0,
        duration: const Duration(milliseconds: 260),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x24FFFFFF), width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _FlyingDot extends StatefulWidget {
  const _FlyingDot({
    required this.origin,
    required this.target,
    required this.reduceMotion,
  });

  final Offset origin;
  final Offset target;
  final bool reduceMotion;

  @override
  State<_FlyingDot> createState() => _FlyingDotState();
}

class _FlyingDotState extends State<_FlyingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final travel = Curves.easeInOutCubic.transform(_controller.value);
        final scale = 1 + math.sin(_controller.value * math.pi) * 0.8;
        final point = Offset.lerp(widget.origin, widget.target, travel)!;
        return Positioned(
          left: point.dx - 7,
          top: point.dy - 7,
          width: 14,
          height: 14,
          child: Transform.scale(
            scale: scale,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7DD3FC),
                boxShadow: [
                  BoxShadow(color: Color(0xAA7DD3FC), blurRadius: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
