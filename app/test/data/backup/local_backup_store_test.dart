import 'dart:io';

import 'package:power_manager/data/backup/local_backup_store.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'powermanager-local-backup-',
    );
  });

  tearDown(() => directory.delete(recursive: true));

  test('latest backup saves metadata and replaces the previous file', () async {
    final store = FileLocalBackupStore(directoryLoader: () async => directory);

    await store.save('first');
    final metadata = await store.save('second version');

    expect(await File(metadata.path).readAsString(), 'second version');
    expect(metadata.byteLength, 'second version'.length);
    expect(metadata.modifiedAt, isNotNull);
    expect(File('${metadata.path}.tmp').existsSync(), isFalse);
  });

  test('failure before replace preserves the valid previous backup', () async {
    final normal = FileLocalBackupStore(directoryLoader: () async => directory);
    final previous = await normal.save('valid previous');
    final failing = FileLocalBackupStore(
      directoryLoader: () async => directory,
      beforeReplace: (_, _) async => throw StateError('injected failure'),
    );

    await expectLater(failing.save('incomplete next'), throwsStateError);

    expect(await File(previous.path).readAsString(), 'valid previous');
    expect(File('${previous.path}.tmp').existsSync(), isFalse);
  });
}
