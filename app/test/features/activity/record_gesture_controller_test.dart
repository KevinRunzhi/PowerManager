import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/features/activity/application/record_gesture_controller.dart';

void main() {
  test('a hot preview does not advance until dwell confirmation', () {
    final controller = RecordGestureController()..start();

    controller.setHotIndex(0);
    expect(controller.state.phase, RecordGesturePhase.selectingCategory);
    expect(controller.state.category, isNull);
    expect(controller.finish(), isNull);

    controller.start();
    controller.setHotIndex(0);
    controller.confirmHot();
    expect(controller.state.phase, RecordGesturePhase.selectingSubcategory);
    expect(controller.state.category, ActivityCategory.study);
  });

  test('only a confirmed three-layer selection can finish', () {
    final controller = RecordGestureController()..start();
    _confirm(controller, 0);
    _confirm(controller, 0);
    controller.setHotIndex(0);
    expect(controller.finish(), isNull);

    controller.start();
    _confirm(controller, 0);
    _confirm(controller, 0);
    _confirm(controller, 0);
    final result = controller.finish();

    expect(result, isNotNull);
    expect(result!.category, ActivityCategory.study);
    expect(result.subcategory, ActivitySubcategory.classAttendance);
    expect(result.duration, DurationSlot.minutes15);
    expect(controller.state.phase, RecordGesturePhase.idle);
  });

  test('clearing a hot target prevents a stale dwell confirmation', () {
    final controller = RecordGestureController()
      ..start()
      ..setHotIndex(2)
      ..setHotIndex(null)
      ..confirmHot();

    expect(controller.state.phase, RecordGesturePhase.selectingCategory);
    expect(controller.state.category, isNull);
  });

  test('backslide clears one committed layer at a time', () {
    final controller = RecordGestureController()..start();
    _confirm(controller, 0);
    _confirm(controller, 0);
    _confirm(controller, 0);
    expect(controller.state.phase, RecordGesturePhase.ready);

    expect(controller.back(), isTrue);
    expect(controller.state.phase, RecordGesturePhase.selectingSubcategory);
    expect(controller.state.category, ActivityCategory.study);
    expect(controller.state.subcategory, isNull);

    expect(controller.back(), isTrue);
    expect(controller.state.phase, RecordGesturePhase.selectingCategory);
    expect(controller.state.category, isNull);
    expect(controller.back(), isFalse);
  });

  test('moving from a ready duration requires reconfirmation', () {
    final controller = RecordGestureController()..start();
    _confirm(controller, 0);
    _confirm(controller, 0);
    _confirm(controller, 0);

    controller.setHotIndex(5);
    expect(controller.state.phase, RecordGesturePhase.selectingDuration);
    expect(controller.state.duration, isNull);
    expect(controller.finish(), isNull);
  });

  test('cancel and incomplete release never produce a selection', () {
    final controller = RecordGestureController()
      ..start()
      ..setHotIndex(1)
      ..cancel();
    expect(controller.state.phase, RecordGesturePhase.cancelled);
    expect(controller.finish(), isNull);

    controller.start();
    _confirm(controller, 1);
    expect(controller.finish(), isNull);
  });

  test('all categories, subcategories and durations remain reachable', () {
    final categories = <ActivityCategory>{};
    final subcategories = <ActivitySubcategory>{};
    final durations = <DurationSlot>{};

    for (var categoryIndex = 0; categoryIndex < 4; categoryIndex++) {
      for (var subcategoryIndex = 0; subcategoryIndex < 6; subcategoryIndex++) {
        for (var durationIndex = 0; durationIndex < 6; durationIndex++) {
          final controller = RecordGestureController()..start();
          _confirm(controller, categoryIndex);
          categories.add(controller.state.category!);
          _confirm(controller, subcategoryIndex);
          subcategories.add(controller.state.subcategory!);
          _confirm(controller, durationIndex);
          durations.add(controller.state.duration!);
        }
      }
    }

    expect(categories, containsAll(ActivityCategory.values));
    expect(subcategories, containsAll(ActivitySubcategory.values));
    expect(durations, containsAll(DurationSlot.values));
  });
}

void _confirm(RecordGestureController controller, int index) {
  controller
    ..setHotIndex(index)
    ..confirmHot();
}
