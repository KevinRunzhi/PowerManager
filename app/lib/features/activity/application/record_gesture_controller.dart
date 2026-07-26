import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';

enum RecordGesturePhase {
  idle,
  selectingCategory,
  selectingSubcategory,
  selectingDuration,
  ready,
  cancelled,
}

final class RecordGestureSelection {
  const RecordGestureSelection({
    required this.category,
    required this.subcategory,
    required this.duration,
  });

  final ActivityCategory category;
  final ActivitySubcategory subcategory;
  final DurationSlot duration;
}

final class RecordGestureState {
  const RecordGestureState({
    required this.phase,
    this.category,
    this.subcategory,
    this.duration,
  });

  const RecordGestureState.idle()
    : phase = RecordGesturePhase.idle,
      category = null,
      subcategory = null,
      duration = null;

  final RecordGesturePhase phase;
  final ActivityCategory? category;
  final ActivitySubcategory? subcategory;
  final DurationSlot? duration;
}

final class RecordGestureController {
  static const categoryInnerRadius = 34.0;
  static const subcategoryInnerRadius = 88.0;
  static const durationInnerRadius = 148.0;

  RecordGestureState _state = const RecordGestureState.idle();

  RecordGestureState get state => _state;

  void start() {
    _state = const RecordGestureState(
      phase: RecordGesturePhase.selectingCategory,
    );
  }

  void update(Offset displacement) {
    if (_state.phase == RecordGesturePhase.idle ||
        _state.phase == RecordGesturePhase.cancelled) {
      return;
    }
    final radius = displacement.distance;
    if (radius < categoryInnerRadius) {
      _state = const RecordGestureState(
        phase: RecordGesturePhase.selectingCategory,
      );
      return;
    }
    if (radius < subcategoryInnerRadius) {
      _state = RecordGestureState(
        phase: RecordGesturePhase.selectingSubcategory,
        category: _pick(ActivityCategory.values, displacement),
      );
      return;
    }
    final category = _state.category;
    if (category == null) {
      return;
    }
    if (radius < durationInnerRadius) {
      final subcategories = ActivitySubcategory.values
          .where((item) => item.category == category)
          .toList(growable: false);
      _state = RecordGestureState(
        phase: RecordGesturePhase.selectingDuration,
        category: category,
        subcategory: _pick(subcategories, displacement),
      );
      return;
    }
    final subcategory = _state.subcategory;
    if (subcategory == null) {
      return;
    }
    _state = RecordGestureState(
      phase: RecordGesturePhase.ready,
      category: category,
      subcategory: subcategory,
      duration: _pick(DurationSlot.values, displacement),
    );
  }

  RecordGestureSelection? finish() {
    final current = _state;
    final result =
        current.phase == RecordGesturePhase.ready &&
            current.category != null &&
            current.subcategory != null &&
            current.duration != null
        ? RecordGestureSelection(
            category: current.category!,
            subcategory: current.subcategory!,
            duration: current.duration!,
          )
        : null;
    _state = const RecordGestureState.idle();
    return result;
  }

  void cancel() {
    _state = const RecordGestureState(phase: RecordGesturePhase.cancelled);
  }

  void reset() {
    _state = const RecordGestureState.idle();
  }

  static T _pick<T>(List<T> values, Offset displacement) {
    final angleFromTop =
        (math.atan2(displacement.dy, displacement.dx) + math.pi / 2) %
        (math.pi * 2);
    final sector = math.pi * 2 / values.length;
    final index =
        ((angleFromTop + sector / 2) / sector).floor() % values.length;
    return values[index];
  }
}
