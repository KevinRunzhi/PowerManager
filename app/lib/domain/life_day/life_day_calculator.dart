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

  static int _validateBoundaryHour(int boundaryHour) {
    if (boundaryHour < 0 || boundaryHour > 23) {
      throw RangeError.range(boundaryHour, 0, 23, 'boundaryHour');
    }
    return boundaryHour;
  }
}
