import 'dart:io';

import 'package:power_manager/data/backup/local_backup_safety_store.dart';
import 'package:test/test.dart';

void main() {
  test('safety store replaces the previous snapshot completely', () async {
    final directory = await Directory.systemTemp.createTemp(
      'powermanager-safety-store-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = LocalBackupSafetyStore(
      directoryLoader: () async => directory,
    );

    await store.save('first');
    await store.save('second');

    final path = await store.existingPath();
    expect(path, isNotNull);
    expect(await File(path!).readAsString(), 'second');
    expect(File('$path.tmp').existsSync(), isFalse);
  });
}
