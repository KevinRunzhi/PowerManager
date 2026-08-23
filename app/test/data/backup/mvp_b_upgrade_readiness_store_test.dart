import 'dart:io';

import 'package:power_manager/application/backup_content_digest.dart';
import 'package:power_manager/application/mvp_b_upgrade_readiness_service.dart';
import 'package:power_manager/data/backup/mvp_b_upgrade_readiness_store.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'powermanager-mvp-b-readiness-',
    );
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('proof is atomically saved and strictly loaded', () async {
    final store = FileMvpBUpgradeReadinessStore(
      directoryLoader: () async => directory,
    );
    final proof = _proof('a');

    await store.save(proof);
    final loaded = await store.load();

    expect(loaded, isNotNull);
    expect(loaded!.verifiedAt, proof.verifiedAt);
    expect(loaded.backupModifiedAt, proof.backupModifiedAt);
    expect(loaded.backupByteLength, proof.backupByteLength);
    expect(loaded.backupSchemaVersion, 1);
    expect(loaded.backupContentDigest, proof.backupContentDigest);
    expect(loaded.currentContentDigest, proof.currentContentDigest);
    expect(
      File(
        '${directory.path}${Platform.pathSeparator}'
        '${FileMvpBUpgradeReadinessStore.fileName}.tmp',
      ).existsSync(),
      isFalse,
    );
  });

  test('failure before replace preserves the previous proof', () async {
    final normal = FileMvpBUpgradeReadinessStore(
      directoryLoader: () async => directory,
    );
    await normal.save(_proof('a'));
    final failing = FileMvpBUpgradeReadinessStore(
      directoryLoader: () async => directory,
      beforeReplace: (_, _) async => throw StateError('injected failure'),
    );

    await expectLater(failing.save(_proof('b')), throwsStateError);

    expect((await normal.load())!.backupContentDigest, _digest('a'));
  });

  test('missing proof returns null and malformed proof is rejected', () async {
    final store = FileMvpBUpgradeReadinessStore(
      directoryLoader: () async => directory,
    );
    expect(await store.load(), isNull);

    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      '${FileMvpBUpgradeReadinessStore.fileName}',
    );
    await file.writeAsString('{"formatVersion":"wrong"}');

    await expectLater(store.load(), throwsFormatException);
  });
}

MvpBUpgradeReadinessProof _proof(String character) {
  return MvpBUpgradeReadinessProof(
    verifiedAt: DateTime.utc(2026, 8, 15, 8),
    backupModifiedAt: DateTime.utc(2026, 8, 15, 7),
    backupByteLength: 4096,
    backupSchemaVersion: 1,
    digestVersion: BackupContentDigester.version,
    backupContentDigest: _digest(character),
    currentContentDigest: _digest(character),
  );
}

String _digest(String character) => List.filled(64, character).join();
