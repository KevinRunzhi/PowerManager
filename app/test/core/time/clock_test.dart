import 'package:power_manager/core/time/clock.dart';
import 'package:test/test.dart';

void main() {
  test('non-release engineering build accepts an explicit ISO clock', () {
    final clock = createAppClock(
      allowFixedOverride: true,
      fixedNow: '2026-08-13T12:00:00Z',
    );

    expect(clock, isA<FixedClock>());
    expect(clock.now(), DateTime.utc(2026, 8, 13, 12));
  });

  test('release mode always ignores a fixed clock override', () {
    final clock = createAppClock(
      allowFixedOverride: false,
      fixedNow: 'not-a-timestamp',
    );

    expect(clock, isA<SystemClock>());
  });

  test('invalid engineering timestamp fails instead of guessing', () {
    expect(
      () =>
          createAppClock(allowFixedOverride: true, fixedNow: 'not-a-timestamp'),
      throwsStateError,
    );
  });
}
