import 'dart:io';

import 'package:drift/native.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/create_schema_snapshot_database.dart <sqlite-file>',
    );
    exitCode = 64;
    return;
  }

  final file = File(arguments.single).absolute;
  if (file.existsSync()) {
    stderr.writeln('Refusing to overwrite an existing file: ${file.path}');
    exitCode = 73;
    return;
  }
  await file.parent.create(recursive: true);

  final database = AppDatabase.forExecutor(
    NativeDatabase(file),
    clock: const SystemClock(),
  );
  try {
    await database.customSelect('PRAGMA user_version').getSingle();
  } finally {
    await database.close();
  }
}
