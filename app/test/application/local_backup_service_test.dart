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
      throwsA(
        isA<LocalBackupException>().having(
          (error) => error.stage,
          'stage',
          LocalBackupFailureStage.validateExport,
        ),
      ),
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
      throwsA(
        isA<LocalBackupException>().having(
          (error) => error.stage,
          'stage',
          LocalBackupFailureStage.validateReadBack,
        ),
      ),
    );
    expect(store.saveCalls, 1);
  });

  test('export, write, and read failures keep distinct safe stages', () async {
    final exportFailure = LocalBackupService(
      exportService: const _Exporter('', fail: true),
      codec: const JsonBackupCodec(),
      store: _Store(),
      clock: _Clock(backupFixtureNow),
    );
    await expectLater(
      exportFailure.saveLatest(),
      _throwsStage(LocalBackupFailureStage.export),
    );

    final writeFailure = LocalBackupService(
      exportService: _Exporter(_validJson()),
      codec: const JsonBackupCodec(),
      store: _Store(failSave: true),
      clock: _Clock(backupFixtureNow),
    );
    await expectLater(
      writeFailure.saveLatest(),
      _throwsStage(LocalBackupFailureStage.write),
    );

    final readFailure = LocalBackupService(
      exportService: _Exporter(_validJson()),
      codec: const JsonBackupCodec(),
      store: _Store(failRead: true),
      clock: _Clock(backupFixtureNow),
    );
    await expectLater(
      readFailure.saveLatest(),
      _throwsStage(LocalBackupFailureStage.readBack),
    );
  });
}

Matcher _throwsStage(LocalBackupFailureStage stage) => throwsA(
  isA<LocalBackupException>().having((error) => error.stage, 'stage', stage),
);

String _validJson() => jsonEncode(backupFixture().toJson());

final class _Exporter implements JsonExporter {
  const _Exporter(this.contents, {this.fail = false});

  final String contents;
  final bool fail;

  @override
  Future<JsonExportResult> create({required DateTime exportedAt}) async {
    if (fail) throw StateError('injected export failure');
    return JsonExportResult(fileName: 'backup.json', contents: contents);
  }
}

final class _Store implements LocalBackupStore {
  _Store({
    this.corruptAfterSave = false,
    this.failSave = false,
    this.failRead = false,
  });

  final bool corruptAfterSave;
  final bool failSave;
  final bool failRead;
  var saveCalls = 0;
  var contents = '';

  @override
  Future<LocalBackupMetadata> save(String contents) async {
    saveCalls++;
    if (failSave) throw StateError('injected write failure');
    this.contents = contents;
    return LocalBackupMetadata(
      path: 'backup.json',
      modifiedAt: backupFixtureNow,
      byteLength: utf8.encode(contents).length,
    );
  }

  @override
  Future<Uint8List> readBytes() async {
    if (failRead) throw StateError('injected read failure');
    return Uint8List.fromList(
      utf8.encode(corruptAfterSave ? '{broken' : contents),
    );
  }

  @override
  Future<LocalBackupMetadata?> metadata() async => null;
}

final class _Clock implements Clock {
  const _Clock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
