import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/application/local_backup_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/backup/local_backup_store.dart';
import 'package:test/test.dart';

import '../support/backup_fixture.dart';

void main() {
  test('valid export is checked before and after latest backup save', () async {
    final store = _Store();
    final service = LocalBackupService(
      exportService: _Exporter(_validJson()),
      codec: const JsonBackupCodec(),
      store: store,
      clock: _Clock(backupFixtureNow),
    );

    final metadata = await service.saveLatest();

    expect(store.saveCalls, 1);
    expect(metadata.byteLength, utf8.encode(_validJson()).length);
  });

  test('invalid export is rejected before file write', () async {
    final store = _Store();
    final service = LocalBackupService(
      exportService: _Exporter('{"schemaVersion":1}'),
      codec: const JsonBackupCodec(),
      store: store,
      clock: _Clock(backupFixtureNow),
    );

    await expectLater(
      service.saveLatest(),
      throwsA(isA<BackupFormatException>()),
    );
    expect(store.saveCalls, 0);
  });

  test('corrupted stored bytes never report save success', () async {
    final store = _Store(corruptAfterSave: true);
    final service = LocalBackupService(
      exportService: _Exporter(_validJson()),
      codec: const JsonBackupCodec(),
      store: store,
      clock: _Clock(backupFixtureNow),
    );

    await expectLater(
      service.saveLatest(),
      throwsA(isA<BackupFormatException>()),
    );
    expect(store.saveCalls, 1);
  });
}

String _validJson() => jsonEncode(backupFixture().toJson());

final class _Exporter implements JsonExporter {
  const _Exporter(this.contents);

  final String contents;

  @override
  Future<JsonExportResult> create({required DateTime exportedAt}) async =>
      JsonExportResult(fileName: 'backup.json', contents: contents);
}

final class _Store implements LocalBackupStore {
  _Store({this.corruptAfterSave = false});

  final bool corruptAfterSave;
  var saveCalls = 0;
  var contents = '';

  @override
  Future<LocalBackupMetadata> save(String contents) async {
    saveCalls++;
    this.contents = contents;
    return LocalBackupMetadata(
      path: 'backup.json',
      modifiedAt: backupFixtureNow,
      byteLength: utf8.encode(contents).length,
    );
  }

  @override
  Future<Uint8List> readBytes() async =>
      Uint8List.fromList(utf8.encode(corruptAfterSave ? '{broken' : contents));

  @override
  Future<LocalBackupMetadata?> metadata() async => null;
}

final class _Clock implements Clock {
  const _Clock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
