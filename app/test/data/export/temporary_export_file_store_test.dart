import 'dart:io';

import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/data/export/temporary_export_file_store.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late TemporaryExportFileStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('powermanager-export-');
    store = TemporaryExportFileStore(directoryLoader: () async => directory);
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('writes the generated export and deletes it after sharing', () async {
    const result = JsonExportResult(
      fileName: 'powermanager-test.json',
      contents: '{"schemaVersion":1}',
    );

    final file = await store.write(result);

    expect(
      file.path,
      '${directory.path}${Platform.pathSeparator}${result.fileName}',
    );
    expect(await file.readAsString(), result.contents);

    await store.delete(file);
    expect(await file.exists(), isFalse);
  });

  test('deleting an already absent temporary export is safe', () async {
    final missing = File(
      '${directory.path}${Platform.pathSeparator}missing.json',
    );

    await store.delete(missing);

    expect(await missing.exists(), isFalse);
  });
}
