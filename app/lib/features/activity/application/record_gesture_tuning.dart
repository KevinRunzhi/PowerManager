final class RecordGestureTuning {
  const RecordGestureTuning({
    this.activationDelay = const Duration(milliseconds: 200),
    this.categoryDwell = const Duration(milliseconds: 300),
    this.durationDwell = const Duration(milliseconds: 300),
    this.backCooldown = const Duration(milliseconds: 260),
    this.stabilizationDelay = const Duration(milliseconds: 90),
    this.timeout = const Duration(seconds: 10),
    this.newNodeHitSlop = 12,
    this.stickyNodeHitSlop = 28,
    this.centerBackRatio = 0.48,
    this.maxDwellStartSpeed = 0.65,
  });

  static const defaults = RecordGestureTuning();

  final Duration activationDelay;
  final Duration categoryDwell;
  final Duration durationDwell;
  final Duration backCooldown;
  final Duration stabilizationDelay;
  final Duration timeout;

  /// Extra logical pixels around a node when entering it for the first time.
  final double newNodeHitSlop;

  /// Extra logical pixels retained around the current node to prevent jitter.
  final double stickyNodeHitSlop;

  /// Radius relative to the energy ball that triggers one-layer backtracking.
  final double centerBackRatio;

  /// Logical pixels per millisecond above which dwell waits for stabilization.
  final double maxDwellStartSpeed;
}
