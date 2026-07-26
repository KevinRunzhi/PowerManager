import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/life_day/life_day_calculator.dart';
import 'package:test/test.dart';

void main() {
  group('LifeDay', () {
    test('parses, compares, and crosses month and year boundaries', () {
      final lastDayOfYear = LifeDay.parse('2025-12-31');

      expect(lastDayOfYear.toString(), '2025-12-31');
      expect(lastDayOfYear.next, LifeDay(2026, 1, 1));
      expect(LifeDay(2026, 3, 1).previous, LifeDay(2026, 2, 28));
      expect(lastDayOfYear.compareTo(lastDayOfYear.next), isNegative);
    });

    test('rejects non-canonical and impossible dates', () {
      expect(() => LifeDay.parse('2026-7-26'), throwsFormatException);
      expect(() => LifeDay.parse('2026-02-30'), throwsArgumentError);
    });

    test('remains stable after the source clock changes', () {
      final persisted = LifeDay.fromLocalDateTime(DateTime(2026, 7, 26, 18));
      final laterClockValue = DateTime(2026, 7, 27, 18);

      expect(persisted, LifeDay(2026, 7, 26));
      expect(laterClockValue.day, 27);
      expect(persisted.toString(), '2026-07-26');
    });
  });

  group('LifeDayCalculator', () {
    final calculator = LifeDayCalculator();

    test('03:59:59 belongs to the previous life day', () {
      expect(
        calculator.lifeDayFor(DateTime(2026, 7, 26, 3, 59, 59)),
        LifeDay(2026, 7, 25),
      );
    });

    test('04:00:00 starts the new life day', () {
      expect(
        calculator.lifeDayFor(DateTime(2026, 7, 26, 4)),
        LifeDay(2026, 7, 26),
      );
    });

    test('04:00:01 remains in the new life day', () {
      expect(
        calculator.lifeDayFor(DateTime(2026, 7, 26, 4, 0, 1)),
        LifeDay(2026, 7, 26),
      );
    });

    test('handles month-end and year-end before the boundary', () {
      expect(
        calculator.lifeDayFor(DateTime(2026, 3, 1, 1)),
        LifeDay(2026, 2, 28),
      );
      expect(
        calculator.lifeDayFor(DateTime(2026, 1, 1, 1)),
        LifeDay(2025, 12, 31),
      );
    });

    test('reads the current value from an injected clock', () {
      final clock = _FixedClock(DateTime(2026, 7, 26, 2));

      expect(calculator.currentLifeDay(clock), LifeDay(2026, 7, 25));
    });

    test(
      'a wall-clock rollback never mutates an already captured life day',
      () {
        final clock = _MutableClock(DateTime(2026, 7, 26, 4, 0, 1));
        final captured = calculator.currentLifeDay(clock);

        clock.value = DateTime(2026, 7, 26, 3, 59, 59);

        expect(captured, LifeDay(2026, 7, 26));
        expect(calculator.currentLifeDay(clock), LifeDay(2026, 7, 25));
        expect(captured, LifeDay(2026, 7, 26));
      },
    );

    test('supports an explicit alternative boundary', () {
      final midnightBoundary = LifeDayCalculator(boundaryHour: 0);

      expect(
        midnightBoundary.lifeDayFor(DateTime(2026, 7, 26)),
        LifeDay(2026, 7, 26),
      );
    });

    test('rejects an invalid boundary in every build mode', () {
      expect(() => LifeDayCalculator(boundaryHour: 24), throwsRangeError);
    });
  });
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

final class _MutableClock implements Clock {
  _MutableClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}
