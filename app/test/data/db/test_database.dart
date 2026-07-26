import 'package:drift/native.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';

final testNow = DateTime.utc(2026, 7, 26, 12);

AppDatabase createTestDatabase() {
  return AppDatabase.forExecutor(
    NativeDatabase.memory(),
    clock: _FixedClock(testNow),
  );
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
