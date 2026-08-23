import 'dart:math';

/// Generates opaque record identifiers without relying on wall-clock uniqueness.
///
/// The timestamp remains useful when inspecting a backup, while the process-local
/// sequence and random suffix keep IDs distinct under frozen or backward clocks
/// and across process restarts.
final class RecordIdGenerator {
  RecordIdGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;
  var _sequence = 0;

  String next({required String prefix, required DateTime now}) {
    if (prefix.isEmpty || !RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(prefix)) {
      throw ArgumentError.value(
        prefix,
        'prefix',
        'Must be a lowercase ID token',
      );
    }
    final entropy = List<int>.generate(
      12,
      (_) => _random.nextInt(256),
      growable: false,
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    final sequence = _sequence++;
    return '$prefix-${now.toUtc().microsecondsSinceEpoch}-'
        '${sequence.toRadixString(36)}-$entropy';
  }
}
