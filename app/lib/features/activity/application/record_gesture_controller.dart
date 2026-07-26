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
    this.hotIndex,
  });

  const RecordGestureState.idle()
    : phase = RecordGesturePhase.idle,
      category = null,
      subcategory = null,
      duration = null,
      hotIndex = null;

  final RecordGesturePhase phase;
  final ActivityCategory? category;
  final ActivitySubcategory? subcategory;
  final DurationSlot? duration;

  /// The node currently under the pointer. It is only a preview until
  /// [RecordGestureController.confirmHot] is called after the dwell window.
  final int? hotIndex;
}

/// Owns the three-step selection state, but deliberately knows nothing about
/// pointer geometry or timers. The presentation layer performs node hit tests
/// and only commits a preview after it has remained stable long enough.
final class RecordGestureController {
  RecordGestureState _state = const RecordGestureState.idle();

  RecordGestureState get state => _state;

  void start() {
    _state = const RecordGestureState(
      phase: RecordGesturePhase.selectingCategory,
    );
  }

  void setHotIndex(int? index) {
    final current = _state;
    if (current.phase == RecordGesturePhase.idle ||
        current.phase == RecordGesturePhase.cancelled) {
      return;
    }
    final phase = current.phase == RecordGesturePhase.ready
        ? RecordGesturePhase.selectingDuration
        : current.phase;
    final count = _itemCount(phase, current.category);
    if (index != null && (index < 0 || index >= count)) {
      throw RangeError.index(index, List<void>.filled(count, null));
    }
    _state = RecordGestureState(
      phase: phase,
      category: current.category,
      subcategory: current.subcategory,
      hotIndex: index,
    );
  }

  /// Commits the current preview and advances exactly one layer.
  ///
  /// Calling this without a hot node is intentionally a no-op, which keeps a
  /// timer racing with pointer exit from producing a write.
  void confirmHot() {
    final current = _state;
    final hotIndex = current.hotIndex;
    if (hotIndex == null) {
      return;
    }
    switch (current.phase) {
      case RecordGesturePhase.selectingCategory:
        _state = RecordGestureState(
          phase: RecordGesturePhase.selectingSubcategory,
          category: ActivityCategory.values[hotIndex],
        );
        return;
      case RecordGesturePhase.selectingSubcategory:
        final category = current.category;
        if (category == null) {
          return;
        }
        final items = _subcategories(category);
        _state = RecordGestureState(
          phase: RecordGesturePhase.selectingDuration,
          category: category,
          subcategory: items[hotIndex],
        );
        return;
      case RecordGesturePhase.selectingDuration:
        final category = current.category;
        final subcategory = current.subcategory;
        if (category == null || subcategory == null) {
          return;
        }
        _state = RecordGestureState(
          phase: RecordGesturePhase.ready,
          category: category,
          subcategory: subcategory,
          duration: DurationSlot.values[hotIndex],
          hotIndex: hotIndex,
        );
        return;
      case RecordGesturePhase.ready:
      case RecordGesturePhase.idle:
      case RecordGesturePhase.cancelled:
        return;
    }
  }

  /// Returns to the preceding layer and clears the choice made in that layer.
  bool back() {
    final current = _state;
    switch (current.phase) {
      case RecordGesturePhase.ready:
      case RecordGesturePhase.selectingDuration:
        _state = RecordGestureState(
          phase: RecordGesturePhase.selectingSubcategory,
          category: current.category,
        );
        return true;
      case RecordGesturePhase.selectingSubcategory:
        _state = const RecordGestureState(
          phase: RecordGesturePhase.selectingCategory,
        );
        return true;
      case RecordGesturePhase.selectingCategory:
      case RecordGesturePhase.idle:
      case RecordGesturePhase.cancelled:
        return false;
    }
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

  static int _itemCount(RecordGesturePhase phase, ActivityCategory? category) {
    return switch (phase) {
      RecordGesturePhase.selectingCategory => ActivityCategory.values.length,
      RecordGesturePhase.selectingSubcategory =>
        category == null ? 0 : _subcategories(category).length,
      RecordGesturePhase.selectingDuration ||
      RecordGesturePhase.ready => DurationSlot.values.length,
      RecordGesturePhase.idle || RecordGesturePhase.cancelled => 0,
    };
  }

  static List<ActivitySubcategory> _subcategories(ActivityCategory category) =>
      ActivitySubcategory.values
          .where((item) => item.category == category)
          .toList(growable: false);
}
