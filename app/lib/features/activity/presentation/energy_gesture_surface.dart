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
  final _controller = RecordGestureController();
  OverlayEntry? _overlay;
  Timer? _timeout;
  Offset _center = Offset.zero;
  String _selectionSignature = '';

  @override
  void dispose() {
    _timeout?.cancel();
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
    final box = context.findRenderObject()! as RenderBox;
    _center = box.localToGlobal(box.size.center(Offset.zero));
    _controller.start();
    _selectionSignature = '';
    HapticFeedback.lightImpact();
    _overlay = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: CustomPaint(
          key: const Key('record-gesture-overlay'),
          painter: _RecordGesturePainter(
            center: _center,
            state: _controller.state,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
    _restartTimeout();
  }

  void _update(LongPressMoveUpdateDetails details) {
    _controller.update(details.globalPosition - _center);
    final state = _controller.state;
    final signature =
        '${state.category?.code}:${state.subcategory?.code}:'
        '${state.duration?.minutes}';
    if (signature != _selectionSignature) {
      _selectionSignature = signature;
      HapticFeedback.selectionClick();
    }
    _overlay?.markNeedsBuild();
    _restartTimeout();
  }

  void _finish(LongPressEndDetails details) {
    final selection = _controller.finish();
    _cleanup();
    if (selection != null) {
      HapticFeedback.mediumImpact();
      unawaited(widget.onConfirmed(selection));
    }
  }

  void _cancel() {
    _controller.cancel();
    _cleanup();
  }

  void _restartTimeout() {
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 10), () {
      _controller.cancel();
      _cleanup();
    });
  }

  void _cleanup() {
    _timeout?.cancel();
    _timeout = null;
    _overlay?.remove();
    _overlay = null;
    _controller.reset();
  }
}

final class _RecordGesturePainter extends CustomPainter {
  const _RecordGesturePainter({required this.center, required this.state});

  final Offset center;
  final RecordGestureState state;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0x660D1017),
    );
    final (labels, radius, selectedIndex) = _items();
    final nodePaint = Paint()..color = const Color(0xE61C2230);
    final selectedPaint = Paint()..color = const Color(0xE65EEAD4);
    for (var index = 0; index < labels.length; index++) {
      final angle = index * math.pi * 2 / labels.length - math.pi / 2;
      final rawPoint =
          center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final point = Offset(
        rawPoint.dx.clamp(50, size.width - 50),
        rawPoint.dy.clamp(28, size.height - 28),
      );
      final rect = Rect.fromCenter(center: point, width: 92, height: 48);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(14)),
        index == selectedIndex ? selectedPaint : nodePaint,
      );
      final painter = TextPainter(
        text: TextSpan(
          text: labels[index],
          style: TextStyle(
            color: index == selectedIndex
                ? const Color(0xFF0D1017)
                : const Color(0xFFE8ECF4),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        maxLines: 2,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 82);
      painter.paint(
        canvas,
        point - Offset(painter.width / 2, painter.height / 2),
      );
    }
    final breadcrumb = [
      state.category?.label,
      state.subcategory?.label,
      state.duration == null ? null : '${state.duration!.minutes} 分钟',
    ].whereType<String>().join(' · ');
    if (breadcrumb.isNotEmpty) {
      final painter = TextPainter(
        text: TextSpan(
          text: breadcrumb,
          style: const TextStyle(color: Color(0xFFE8ECF4), fontSize: 13),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 260);
      painter.paint(canvas, center + Offset(-painter.width / 2, 28));
    }
  }

  (List<String>, double, int) _items() {
    if (state.phase == RecordGesturePhase.selectingCategory) {
      return (
        ActivityCategory.values.map((item) => item.label).toList(),
        104,
        -1,
      );
    }
    if (state.phase == RecordGesturePhase.selectingSubcategory) {
      final items = ActivitySubcategory.values
          .where((item) => item.category == state.category)
          .toList();
      return (items.map((item) => item.label).toList(), 124, -1);
    }
    final items = DurationSlot.values;
    return (
      items.map((item) => '${item.minutes} 分').toList(),
      166,
      state.duration == null ? -1 : items.indexOf(state.duration!),
    );
  }

  @override
  bool shouldRepaint(_RecordGesturePainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.center != center;
}
