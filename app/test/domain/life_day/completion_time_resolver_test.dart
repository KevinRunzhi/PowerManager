import 'package:power_manager/domain/life_day/completion_time_resolver.dart';
import 'package:test/test.dart';

void main() {
  final resolver = CompletionTimeResolver();

  test('uses the selected time on the current calendar day after 04:00', () {
    expect(
      resolver.resolve(now: DateTime(2026, 8, 14, 12), hour: 10, minute: 30),
      DateTime(2026, 8, 14, 10, 30),
    );
  });

  test('maps a late-night selection to yesterday before 04:00', () {
    expect(
      resolver.resolve(now: DateTime(2026, 8, 14, 2), hour: 23, minute: 0),
      DateTime(2026, 8, 13, 23),
    );
  });

  test('maps across month and year boundaries', () {
    expect(
      resolver.resolve(now: DateTime(2026, 3, 1, 2), hour: 23, minute: 30),
      DateTime(2026, 2, 28, 23, 30),
    );
    expect(
      resolver.resolve(now: DateTime(2027, 1, 1, 2), hour: 23, minute: 30),
      DateTime(2026, 12, 31, 23, 30),
    );
  });

  test('rejects a future selection in the same life day', () {
    expect(
      () => resolver.resolve(now: DateTime(2026, 8, 14, 2), hour: 3, minute: 0),
      throwsA(
        isA<CompletionTimeResolutionException>().having(
          (error) => error.failure,
          'failure',
          CompletionTimeFailure.future,
        ),
      ),
    );
  });

  test('rejects a time outside the current life day', () {
    expect(
      () =>
          resolver.resolve(now: DateTime(2026, 8, 14, 12), hour: 3, minute: 0),
      throwsA(
        isA<CompletionTimeResolutionException>().having(
          (error) => error.failure,
          'failure',
          CompletionTimeFailure.outsideCurrentLifeDay,
        ),
      ),
    );
  });

  test('accepts the selected minute when now has later seconds', () {
    expect(
      resolver.resolve(
        now: DateTime(2026, 8, 14, 10, 15, 30),
        hour: 10,
        minute: 15,
      ),
      DateTime(2026, 8, 14, 10, 15),
    );
  });

  test('validates hour and minute', () {
    expect(
      () =>
          resolver.resolve(now: DateTime(2026, 8, 14, 12), hour: 24, minute: 0),
      throwsRangeError,
    );
    expect(
      () => resolver.resolve(
        now: DateTime(2026, 8, 14, 12),
        hour: 12,
        minute: 60,
      ),
      throwsRangeError,
    );
  });
}
