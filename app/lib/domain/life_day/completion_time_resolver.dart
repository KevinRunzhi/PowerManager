import 'package:power_manager/domain/life_day/life_day_calculator.dart';

enum CompletionTimeFailure { future, outsideCurrentLifeDay }

final class CompletionTimeResolutionException implements Exception {
  const CompletionTimeResolutionException(this.failure);

  final CompletionTimeFailure failure;

  @override
  String toString() => 'CompletionTimeResolutionException($failure)';
}

final class CompletionTimeResolver {
  CompletionTimeResolver({LifeDayCalculator? lifeDayCalculator})
    : lifeDayCalculator = lifeDayCalculator ?? LifeDayCalculator();

  final LifeDayCalculator lifeDayCalculator;

  DateTime resolve({
    required DateTime now,
    required int hour,
    required int minute,
  }) {
    RangeError.checkValueInInterval(hour, 0, 23, 'hour');
    RangeError.checkValueInInterval(minute, 0, 59, 'minute');

    final localNow = now.isUtc ? now.toLocal() : now;
    final currentLifeDay = lifeDayCalculator.lifeDayFor(localNow);
    final candidates = <DateTime>[
      DateTime(localNow.year, localNow.month, localNow.day, hour, minute),
      DateTime(localNow.year, localNow.month, localNow.day - 1, hour, minute),
    ];
    final sameLifeDay = candidates
        .where(
          (candidate) =>
              lifeDayCalculator.lifeDayFor(candidate) == currentLifeDay,
        )
        .toList();
    if (sameLifeDay.isEmpty) {
      throw const CompletionTimeResolutionException(
        CompletionTimeFailure.outsideCurrentLifeDay,
      );
    }
    final eligible =
        sameLifeDay.where((candidate) => !candidate.isAfter(localNow)).toList()
          ..sort();
    if (eligible.isEmpty) {
      throw const CompletionTimeResolutionException(
        CompletionTimeFailure.future,
      );
    }
    return eligible.last;
  }
}
