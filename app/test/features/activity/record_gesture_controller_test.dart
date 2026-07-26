import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/features/activity/application/record_gesture_controller.dart';

void main() {
  test('only a complete three-ring selection can finish', () {
    final controller = RecordGestureController()..start();
    expect(controller.finish(), isNull);

    controller.start();
    controller.update(const Offset(0, -60));
    expect(controller.state.category, ActivityCategory.study);
    expect(controller.finish(), isNull);

    controller.start();
    controller.update(const Offset(0, -60));
    controller.update(const Offset(0, -110));
    expect(controller.state.subcategory, ActivitySubcategory.classAttendance);
    expect(controller.finish(), isNull);

    controller.start();
    controller.update(const Offset(0, -60));
    controller.update(const Offset(0, -110));
    controller.update(const Offset(0, -180));
    final result = controller.finish();
    expect(result, isNotNull);
    expect(result!.category, ActivityCategory.study);
    expect(result.subcategory, ActivitySubcategory.classAttendance);
    expect(result.duration, DurationSlot.minutes15);
    expect(controller.state.phase, RecordGesturePhase.idle);
  });

  test('backslide clears deeper selections one ring at a time', () {
    final controller = RecordGestureController()
      ..start()
      ..update(const Offset(0, -60))
      ..update(const Offset(0, -110))
      ..update(const Offset(0, -180));
    expect(controller.state.phase, RecordGesturePhase.ready);

    controller.update(const Offset(0, -120));
    expect(controller.state.phase, RecordGesturePhase.selectingDuration);
    expect(controller.state.duration, isNull);
    expect(controller.state.subcategory, isNotNull);

    controller.update(const Offset(0, -60));
    expect(controller.state.phase, RecordGesturePhase.selectingSubcategory);
    expect(controller.state.subcategory, isNull);

    controller.update(const Offset(0, -10));
    expect(controller.state.phase, RecordGesturePhase.selectingCategory);
    expect(controller.state.category, isNull);
    expect(controller.finish(), isNull);
  });

  test('cancel and incomplete release never produce a selection', () {
    final controller = RecordGestureController()
      ..start()
      ..update(const Offset(60, 0))
      ..cancel();
    expect(controller.state.phase, RecordGesturePhase.cancelled);
    expect(controller.finish(), isNull);

    controller.start();
    controller.update(const Offset(60, 0));
    controller.update(const Offset(110, 0));
    expect(controller.finish(), isNull);
  });

  test('all categories, six subcategories and durations are reachable', () {
    final categories = <ActivityCategory>{};
    final subcategories = <ActivitySubcategory>{};
    final durations = <DurationSlot>{};
    for (var index = 0; index < 24; index++) {
      final angle = index * 2 * math.pi / 24 - math.pi / 2;
      final direction = Offset(60 * math.cos(angle), 60 * math.sin(angle));
      final controller = RecordGestureController()
        ..start()
        ..update(direction);
      categories.add(controller.state.category!);
    }
    for (var categoryIndex = 0; categoryIndex < 4; categoryIndex++) {
      final categoryAngle = categoryIndex * 2 * math.pi / 4 - math.pi / 2;
      final categoryUnit = Offset(
        math.cos(categoryAngle),
        math.sin(categoryAngle),
      );
      for (var index = 0; index < 6; index++) {
        final angle = index * 2 * math.pi / 6 - math.pi / 2;
        final unit = Offset(math.cos(angle), math.sin(angle));
        final controller = RecordGestureController()
          ..start()
          ..update(categoryUnit * 60)
          ..update(unit * 110);
        subcategories.add(controller.state.subcategory!);
        controller.update(unit * 180);
        durations.add(controller.state.duration!);
      }
    }
    expect(categories, containsAll(ActivityCategory.values));
    expect(subcategories, containsAll(ActivitySubcategory.values));
    expect(durations, containsAll(DurationSlot.values));
  });
}
