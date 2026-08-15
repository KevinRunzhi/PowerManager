/// A replaceable source of wall-clock time.
///
/// Domain code receives a [Clock] instead of reading [DateTime.now] directly,
/// which keeps life-day boundary behavior deterministic in tests.
abstract interface class Clock {
  DateTime now();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

final class FixedClock implements Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

Clock createAppClock({
  required bool allowFixedOverride,
  required String fixedNow,
}) {
  if (!allowFixedOverride || fixedNow.isEmpty) {
    return const SystemClock();
  }
  final parsed = DateTime.tryParse(fixedNow);
  if (parsed == null) {
    throw StateError('POWER_MANAGER_FIXED_NOW must be an ISO-8601 timestamp');
  }
  return FixedClock(parsed);
}
