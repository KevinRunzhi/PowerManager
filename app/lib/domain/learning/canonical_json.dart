import 'dart:convert';

/// Encodes the small JSON value set used by learning evidence.
///
/// Object keys are sorted recursively and floating-point values are rejected so
/// the same logical evidence always produces the same UTF-8 bytes.
final class CanonicalJsonEncoder {
  const CanonicalJsonEncoder();

  String encode(Object? value) {
    final buffer = StringBuffer();
    _write(value, buffer);
    return buffer.toString();
  }

  void _write(Object? value, StringBuffer buffer) {
    if (value == null) {
      buffer.write('null');
      return;
    }
    if (value is bool || value is int || value is String) {
      buffer.write(jsonEncode(value));
      return;
    }
    if (value is List<Object?>) {
      buffer.write('[');
      for (var index = 0; index < value.length; index++) {
        if (index > 0) buffer.write(',');
        _write(value[index], buffer);
      }
      buffer.write(']');
      return;
    }
    if (value is Map<String, Object?>) {
      final keys = value.keys.toList()..sort();
      buffer.write('{');
      for (var index = 0; index < keys.length; index++) {
        if (index > 0) buffer.write(',');
        final key = keys[index];
        buffer
          ..write(jsonEncode(key))
          ..write(':');
        _write(value[key], buffer);
      }
      buffer.write('}');
      return;
    }
    throw ArgumentError.value(
      value,
      'value',
      'Canonical JSON accepts only null, bool, int, string, list, and object',
    );
  }
}

String canonicalUtcIso8601Micros(DateTime value) {
  final utc = value.toUtc();
  String digits(int number, int width) => number.toString().padLeft(width, '0');
  final micros = utc.millisecond * 1000 + utc.microsecond;
  return '${digits(utc.year, 4)}-${digits(utc.month, 2)}-'
      '${digits(utc.day, 2)}T${digits(utc.hour, 2)}:'
      '${digits(utc.minute, 2)}:${digits(utc.second, 2)}.'
      '${digits(micros, 6)}Z';
}
