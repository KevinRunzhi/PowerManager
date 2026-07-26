/// A calendar date used as the stable identifier of a PowerManager life day.
///
/// It deliberately contains no time or time-zone component. Once persisted,
/// the value is not recalculated when the device time zone changes.
final class LifeDay implements Comparable<LifeDay> {
  LifeDay(int year, int month, int day)
    : _date = _validatedDate(year, month, day);

  factory LifeDay.fromLocalDateTime(DateTime localDateTime) {
    return LifeDay(localDateTime.year, localDateTime.month, localDateTime.day);
  }

  factory LifeDay.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw FormatException('Invalid life day: $value');
    }

    return LifeDay(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  final DateTime _date;

  int get year => _date.year;
  int get month => _date.month;
  int get day => _date.day;

  LifeDay get previous =>
      LifeDay.fromLocalDateTime(DateTime(year, month, day - 1));
  LifeDay get next => LifeDay.fromLocalDateTime(DateTime(year, month, day + 1));

  static DateTime _validatedDate(int year, int month, int day) {
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw ArgumentError.value(
        '$year-${_twoDigits(month)}-${_twoDigits(day)}',
        'date',
        'LifeDay must be a valid calendar date',
      );
    }
    return date;
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  int compareTo(LifeDay other) => _date.compareTo(other._date);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LifeDay && _date == other._date;

  @override
  int get hashCode => _date.hashCode;

  @override
  String toString() => '$year-${_twoDigits(month)}-${_twoDigits(day)}';
}
