import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

final class LifeDayCalculator {
  LifeDayCalculator({int boundaryHour = 4})
    : boundaryHour = _validateBoundaryHour(boundaryHour);

  final int boundaryHour;

  LifeDay lifeDayFor(DateTime dateTime) {
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final calendarDay = LifeDay.fromLocalDateTime(localDateTime);

    return localDateTime.hour < boundaryHour
        ? calendarDay.previous
        : calendarDay;
  }

  LifeDay currentLifeDay(Clock clock) => lifeDayFor(clock.now());

  DateTime nextBoundaryAfter(DateTime dateTime) {
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final todayBoundary = DateTime(
      localDateTime.year,
      localDateTime.month,
      localDateTime.day,
      boundaryHour,
    );
    if (localDateTime.isBefore(todayBoundary)) {
      return todayBoundary;
    }
    return DateTime(
      localDateTime.year,
      localDateTime.month,
      localDateTime.day + 1,
      boundaryHour,
    );
  }

  static int _validateBoundaryHour(int boundaryHour) {
    if (boundaryHour < 0 || boundaryHour > 23) {
      throw RangeError.range(boundaryHour, 0, 23, 'boundaryHour');
    }
    return boundaryHour;
  }
}
