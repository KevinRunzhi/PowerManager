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
