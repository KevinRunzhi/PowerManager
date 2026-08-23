import 'dart:math';

import 'package:power_manager/core/ids/record_id_generator.dart';
import 'package:test/test.dart';

void main() {
  test('fixed clock still produces unique opaque IDs', () {
    final generator = RecordIdGenerator(random: Random(42));
    final now = DateTime.utc(2026, 8, 13, 12);

    final ids = List.generate(
      100,
      (_) => generator.next(prefix: 'daily', now: now),
    );

    expect(ids.toSet(), hasLength(ids.length));
    expect(
      ids.every(
        (id) => RegExp(
          r'^daily-1786622400000000-[0-9a-z]+-[0-9a-f]{24}$',
        ).hasMatch(id),
      ),
      isTrue,
    );
  });

  test('new generator instance remains distinct at the same timestamp', () {
    final now = DateTime.utc(2026, 8, 13, 12);
    final first = RecordIdGenerator(
      random: Random(1),
    ).next(prefix: 'feedback', now: now);
    final second = RecordIdGenerator(
      random: Random(2),
    ).next(prefix: 'feedback', now: now);

    expect(first, isNot(second));
  });

  test('rejects malformed prefixes', () {
    final generator = RecordIdGenerator(random: Random(1));

    expect(
      () => generator.next(prefix: '../daily', now: DateTime.utc(2026)),
      throwsArgumentError,
    );
  });
}
