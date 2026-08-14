import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:power_manager/application/activity_impact_preview_service.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/features/activity/application/record_gesture_controller.dart';
import 'package:power_manager/features/activity/application/record_gesture_tuning.dart';

typedef GestureRecordCallback =
    Future<void> Function(RecordGestureSelection selection);

class EnergyGestureSurface extends StatefulWidget {
  const EnergyGestureSurface({
    required this.child,
    required this.onConfirmed,
    required this.accentColor,
    this.impactPreviews = const {},
    this.tuning = RecordGestureTuning.defaults,
    super.key,
  });

  final Widget child;
  final GestureRecordCallback onConfirmed;
  final Color accentColor;
  final ActivityImpactCatalog impactPreviews;
  final RecordGestureTuning tuning;

  @override
  State<EnergyGestureSurface> createState() => _EnergyGestureSurfaceState();
}

class _EnergyGestureSurfaceState extends State<EnergyGestureSurface> {
  final _controller = RecordGestureController();
  OverlayEntry? _overlay;
  Timer? _timeout;
  Timer? _dwell;
  Timer? _stabilization;
  Timer? _backCooldownTimer;
  Timer? _cleanupTimer;
  Offset _center = Offset.zero;
  double _ballRadius = 116;
  int? _hotIndex;
  String? _announcedHotKey;
  bool _dwellActive = false;
  int _dwellCycle = 0;
  Offset? _lastPointer;
  DateTime? _lastPointerTime;
  bool _canGoBack = false;
  bool _visible = true;
  bool _reduceMotion = false;
  Offset? _completionOrigin;
  RecordGestureState _displayState = const RecordGestureState.idle();

  @override
  void dispose() {
    _timeout?.cancel();
    _dwell?.cancel();
    _stabilization?.cancel();
    _backCooldownTimer?.cancel();
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
                duration: widget.tuning.activationDelay,
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
    _announcedHotKey = null;
    _dwellActive = false;
    _lastPointer = details.globalPosition;
    _lastPointerTime = DateTime.now();
    _visible = true;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _completionOrigin = null;
    _armBackCooldown();
    _overlay = OverlayEntry(
      builder: (overlayContext) => IgnorePointer(
        child: _GestureOverlay(
          key: const Key('record-gesture-overlay'),
          center: _center,
          ballRadius: _ballRadius,
          state: _displayState,
          hotIndex: _hotIndex,
          dwellDuration: _dwellDuration,
          dwellActive: _dwellActive,
          dwellCycle: _dwellCycle,
          visible: _visible,
          completionOrigin: _completionOrigin,
          reduceMotion: _reduceMotion,
          accentColor: widget.accentColor,
          impactPreviews: widget.impactPreviews,
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
    _restartTimeout();
  }

  Duration get _dwellDuration =>
      _displayState.phase == RecordGesturePhase.selectingDuration ||
          _displayState.phase == RecordGesturePhase.ready
      ? widget.tuning.durationDwell
      : widget.tuning.categoryDwell;

  void _update(LongPressMoveUpdateDetails details) {
    if (_overlay == null) {
      return;
    }
    final pointer = details.globalPosition;
    final movingFast = _isMovingFast(pointer);
    final distanceFromCenter = (pointer - _center).distance;
    if (distanceFromCenter < _ballRadius * widget.tuning.centerBackRatio &&
        _canGoBack) {
      if (_controller.back()) {
        _dwell?.cancel();
        _stabilization?.cancel();
        _dwellActive = false;
        _hotIndex = null;
        _announcedHotKey = null;
        _displayState = _controller.state;
        _armBackCooldown();
        _overlay?.markNeedsBuild();
      } else if (_controller.state.phase ==
          RecordGesturePhase.selectingCategory) {
        _controller.cancel();
        _dismissAnimated();
      }
      _restartTimeout();
      return;
    }

    final nodes = _RecordGestureLayout.nodes(
      state: _controller.state,
      center: _center,
      ballRadius: _ballRadius,
      viewport: MediaQuery.sizeOf(context),
      impactPreviews: widget.impactPreviews,
    );
    final nextHot = _hitTest(pointer, nodes);
    if (nextHot != _hotIndex) {
      _setHot(nextHot, deferDwell: movingFast);
    } else if (nextHot != null && movingFast) {
      _deferDwell(nextHot);
    } else if (nextHot != null &&
        _dwell == null &&
        _stabilization == null &&
        _controller.state.phase != RecordGesturePhase.ready) {
      _startDwell(nextHot);
    }
    _restartTimeout();
  }

  bool _isMovingFast(Offset pointer) {
    final now = DateTime.now();
    final previousPointer = _lastPointer;
    final previousTime = _lastPointerTime;
    _lastPointer = pointer;
    _lastPointerTime = now;
    if (previousPointer == null || previousTime == null) {
      return false;
    }
    final elapsedMicros = now.difference(previousTime).inMicroseconds;
    final distance = (pointer - previousPointer).distance;
    if (distance == 0) {
      return false;
    }
    if (elapsedMicros <= 0) {
      return true;
    }
    final logicalPixelsPerMillisecond = distance * 1000 / elapsedMicros;
    return logicalPixelsPerMillisecond > widget.tuning.maxDwellStartSpeed;
  }

  int? _hitTest(Offset pointer, List<_GestureNode> nodes) {
    final current = _hotIndex;
    if (current != null && current < nodes.length) {
      final stickyNode = nodes[current];
      if ((pointer - stickyNode.center).distance <=
          stickyNode.diameter / 2 + widget.tuning.stickyNodeHitSlop) {
        return current;
      }
    }
    for (final node in nodes) {
      if ((pointer - node.center).distance <=
          node.diameter / 2 + widget.tuning.newNodeHitSlop) {
        return node.index;
      }
    }
    return null;
  }

  void _setHot(int? index, {required bool deferDwell}) {
    _dwell?.cancel();
    _stabilization?.cancel();
    _dwell = null;
    _stabilization = null;
    _dwellActive = false;
    _hotIndex = index;
    _controller.setHotIndex(index);
    _displayState = _controller.state;
    _overlay?.markNeedsBuild();
    if (index == null) {
      _announcedHotKey = null;
      return;
    }
    if (deferDwell) {
      _scheduleStabilization(index);
    } else {
      _startDwell(index);
    }
  }

  void _deferDwell(int index) {
    if (_controller.state.phase == RecordGesturePhase.ready) {
      return;
    }
    _dwell?.cancel();
    _dwell = null;
    _dwellActive = false;
    _scheduleStabilization(index);
    _overlay?.markNeedsBuild();
  }

  void _scheduleStabilization(int index) {
    _stabilization?.cancel();
    final phaseAtStart = _controller.state.phase;
    _stabilization = Timer(widget.tuning.stabilizationDelay, () {
      _stabilization = null;
      if (_hotIndex != index || _controller.state.phase != phaseAtStart) {
        return;
      }
      _startDwell(index);
    });
  }

  void _startDwell(int index) {
    _stabilization?.cancel();
    _stabilization = null;
    _dwell?.cancel();
    _dwellActive = true;
    _dwellCycle += 1;
    final hotKey = '${_controller.state.phase.name}:$index';
    if (_announcedHotKey != hotKey) {
      _announcedHotKey = hotKey;
      HapticFeedback.selectionClick();
    }
    _overlay?.markNeedsBuild();
    final phaseAtStart = _controller.state.phase;
    final duration = _dwellDuration;
    _dwell = Timer(duration, () {
      _dwell = null;
      if (_hotIndex != index || _controller.state.phase != phaseAtStart) {
        return;
      }
      _controller.confirmHot();
      _displayState = _controller.state;
      _dwellActive = false;
      if (_controller.state.phase != RecordGesturePhase.ready) {
        _hotIndex = null;
        _announcedHotKey = null;
        _armBackCooldown();
      }
      _overlay?.markNeedsBuild();
    });
  }

  void _finish(LongPressEndDetails details) {
    _dwell?.cancel();
    _stabilization?.cancel();
    final stateBeforeFinish = _controller.state;
    final nodes = _RecordGestureLayout.nodes(
      state: stateBeforeFinish,
      center: _center,
      ballRadius: _ballRadius,
      viewport: MediaQuery.sizeOf(context),
      impactPreviews: widget.impactPreviews,
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
    _cleanupTimer = Timer(
      _reduceMotion ? Duration.zero : const Duration(milliseconds: 540),
      _cleanup,
    );
  }

  void _cancel() {
    _controller.cancel();
    _dismissAnimated();
  }

  void _restartTimeout() {
    _timeout?.cancel();
    _timeout = Timer(widget.tuning.timeout, () {
      _controller.cancel();
      _dismissAnimated();
    });
  }

  void _armBackCooldown() {
    _backCooldownTimer?.cancel();
    _canGoBack = false;
    _backCooldownTimer = Timer(widget.tuning.backCooldown, () {
      _backCooldownTimer = null;
      _canGoBack = true;
    });
  }

  void _dismissAnimated() {
    _dwell?.cancel();
    _stabilization?.cancel();
    _backCooldownTimer?.cancel();
    _timeout?.cancel();
    _visible = false;
    _overlay?.markNeedsBuild();
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer(
      _reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
      _cleanup,
    );
  }

  void _cleanup() {
    _timeout?.cancel();
    _dwell?.cancel();
    _stabilization?.cancel();
    _backCooldownTimer?.cancel();
    _cleanupTimer?.cancel();
    _timeout = null;
    _dwell = null;
    _stabilization = null;
    _backCooldownTimer = null;
    _cleanupTimer = null;
    _overlay?.remove();
    _overlay = null;
    _controller.reset();
    _displayState = const RecordGestureState.idle();
    _hotIndex = null;
    _announcedHotKey = null;
    _dwellActive = false;
    _lastPointer = null;
    _lastPointerTime = null;
    _canGoBack = false;
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
    ActivityImpactCatalog impactPreviews = const {},
  }) {
    final (labels, diameter, radialOffset, spread) = _items(
      state,
      impactPreviews,
    );
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
    ActivityImpactCatalog impactPreviews,
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
      DurationSlot.values.map((item) {
        final preview = state.subcategory == null
            ? null
            : impactPreviews[state.subcategory]?[item];
        final impact = preview == null
            ? '—'
            : _signed(preview.projectedAppliedDelta);
        return '${item.minutes} 分\n$impact';
      }).toList(),
      54,
      96,
      172,
    );
  }

  static String _signed(int value) => value > 0 ? '+$value' : '$value';
}

class _GestureOverlay extends StatelessWidget {
  const _GestureOverlay({
    required this.center,
    required this.ballRadius,
    required this.state,
    required this.hotIndex,
    required this.dwellDuration,
    required this.dwellActive,
    required this.dwellCycle,
    required this.visible,
    required this.completionOrigin,
    required this.reduceMotion,
    required this.accentColor,
    required this.impactPreviews,
    super.key,
  });

  final Offset center;
  final double ballRadius;
  final RecordGestureState state;
  final int? hotIndex;
  final Duration dwellDuration;
  final bool dwellActive;
  final int dwellCycle;
  final bool visible;
  final Offset? completionOrigin;
  final bool reduceMotion;
  final Color accentColor;
  final ActivityImpactCatalog impactPreviews;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final nodes = _RecordGestureLayout.nodes(
      state: state,
      center: center,
      ballRadius: ballRadius,
      viewport: viewport,
      impactPreviews: impactPreviews,
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
            reduceMotion: reduceMotion,
          ),
          AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 350),
            // Opacity animations must stay in [0, 1]. The individual nodes
            // retain the overshooting scale, so the menu still feels springy.
            switchInCurve: Curves.easeOutCubic,
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
              dwellActive: dwellActive,
              dwellCycle: dwellCycle,
              reduceMotion: reduceMotion,
              accentColor: accentColor,
              ready: state.phase == RecordGesturePhase.ready,
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
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _stageTip(state, hotIndex, impactPreviews),
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
          ),
          if (completionOrigin != null)
            _FlyingDot(
              origin: completionOrigin!,
              target: center,
              reduceMotion: reduceMotion,
              color: accentColor,
            ),
        ],
      ),
    );
  }

  static String _stageTip(
    RecordGestureState state,
    int? hotIndex,
    ActivityImpactCatalog impactPreviews,
  ) {
    if ((state.phase == RecordGesturePhase.selectingDuration ||
            state.phase == RecordGesturePhase.ready) &&
        state.subcategory != null &&
        hotIndex != null &&
        hotIndex >= 0 &&
        hotIndex < DurationSlot.values.length) {
      final duration = DurationSlot.values[hotIndex];
      final preview = impactPreviews[state.subcategory]?[duration];
      if (preview != null) {
        final value = preview.projectedAppliedDelta > 0
            ? '+${preview.projectedAppliedDelta}'
            : '${preview.projectedAppliedDelta}';
        final limited = preview.isRecoveryLimited ? ' · 受恢复上限影响' : '';
        return '${state.subcategory!.label} ${duration.minutes} 分钟'
            ' · 估计 $value$limited';
      }
    }
    return switch (state.phase) {
      RecordGesturePhase.selectingCategory => '滑向大类，停留确认',
      RecordGesturePhase.selectingSubcategory => '滑向子类，停留确认',
      RecordGesturePhase.selectingDuration => '滑向时长，停稳后松手',
      RecordGesturePhase.ready => '松手完成 · 滑回球心返回上一层',
      _ => '',
    };
  }
}

class _GestureLayer extends StatefulWidget {
  const _GestureLayer({
    required this.nodes,
    required this.hotIndex,
    required this.dwellDuration,
    required this.dwellActive,
    required this.dwellCycle,
    required this.reduceMotion,
    required this.accentColor,
    required this.ready,
    super.key,
  });

  final List<_GestureNode> nodes;
  final int? hotIndex;
  final Duration dwellDuration;
  final bool dwellActive;
  final int dwellCycle;
  final bool reduceMotion;
  final Color accentColor;
  final bool ready;

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
    final entranceOpacity = entrance.clamp(0.0, 1.0);
    final hot = widget.hotIndex == node.index;
    final faded = widget.hotIndex != null && !hot;
    return Positioned(
      key: Key('gesture-node-${node.index}'),
      left: node.center.dx - node.diameter / 2,
      top: node.center.dy - node.diameter / 2,
      width: node.diameter,
      height: node.diameter,
      child: Semantics(
        container: true,
        excludeSemantics: true,
        label: node.label.replaceAll('\n', '，'),
        selected: hot,
        value: hot
            ? widget.ready
                  ? '已确认，松手完成记录'
                  : widget.dwellActive
                  ? '已吸附，正在确认'
                  : '已命中，等待稳定'
            : null,
        child: Opacity(
          opacity: entranceOpacity * (faded ? 0.75 : 1),
          child: Transform.scale(
            scale: (0.6 + entrance * 0.4) * (hot ? 1.12 : 1),
            child: AnimatedContainer(
              duration: widget.reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hot ? const Color(0xFF232B3C) : const Color(0xF21C2230),
                border: Border.all(
                  color: hot ? widget.accentColor : const Color(0x14FFFFFF),
                ),
                boxShadow: [
                  BoxShadow(
                    color: hot
                        ? widget.accentColor.withValues(alpha: 0.4)
                        : const Color(0x59000000),
                    blurRadius: hot ? 22 : 18,
                    offset: hot ? Offset.zero : const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hot && widget.ready)
                    CustomPaint(
                      painter: _DwellRingPainter(1, widget.accentColor),
                    )
                  else if (hot && widget.dwellActive)
                    TweenAnimationBuilder<double>(
                      key: ValueKey('dwell-${node.index}-${widget.dwellCycle}'),
                      tween: Tween(begin: 0, end: 1),
                      duration: widget.reduceMotion
                          ? Duration.zero
                          : widget.dwellDuration,
                      builder: (context, progress, child) => CustomPaint(
                        painter: _DwellRingPainter(
                          progress,
                          widget.accentColor,
                        ),
                      ),
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
      ),
    );
  }
}

class _DwellRingPainter extends CustomPainter {
  const _DwellRingPainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
      Offset.zero & size,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DwellRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _BreadcrumbRing extends StatelessWidget {
  const _BreadcrumbRing({
    required this.center,
    required this.radius,
    required this.visible,
    required this.reduceMotion,
  });

  final Offset center;
  final double radius;
  final bool visible;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      left: center.dx - radius,
      top: center.dy - radius,
      width: radius * 2,
      height: radius * 2,
      child: AnimatedOpacity(
        opacity: visible ? 0.6 : 0,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 260),
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
    required this.color,
  });

  final Offset origin;
  final Offset target;
  final bool reduceMotion;
  final Color color;

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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.67),
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
