import 'package:drift_flutter/drift_flutter.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';

AppDatabase openAppDatabase({Clock clock = const SystemClock()}) {
  return AppDatabase.forExecutor(
    driftDatabase(name: 'power_manager'),
    clock: clock,
  );
}
