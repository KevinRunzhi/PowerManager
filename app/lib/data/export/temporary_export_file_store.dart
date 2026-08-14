import 'dart:io';

import 'package:power_manager/application/json_export_service.dart';

typedef TemporaryDirectoryLoader = Future<Directory> Function();

final class TemporaryExportFileStore {
  const TemporaryExportFileStore({required this.directoryLoader});

  final TemporaryDirectoryLoader directoryLoader;

  Future<File> write(JsonExportResult result) async {
    final directory = await directoryLoader();
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}${Platform.pathSeparator}${result.fileName}',
    );
    await file.writeAsString(result.contents, flush: true);
    return file;
  }

  Future<void> delete(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
