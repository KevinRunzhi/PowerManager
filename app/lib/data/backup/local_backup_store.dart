import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

typedef LocalBackupDirectoryLoader = Future<Directory> Function();
typedef BeforeLocalBackupReplace =
    Future<void> Function(File temporary, File target);

final class LocalBackupMetadata {
  const LocalBackupMetadata({
    required this.path,
    required this.modifiedAt,
    required this.byteLength,
  });

  final String path;
  final DateTime modifiedAt;
  final int byteLength;
}

abstract interface class LocalBackupStore {
  Future<LocalBackupMetadata> save(String contents);
  Future<LocalBackupMetadata?> metadata();
  Future<Uint8List> readBytes();
}

final class FileLocalBackupStore implements LocalBackupStore {
  FileLocalBackupStore({
    LocalBackupDirectoryLoader? directoryLoader,
    this.beforeReplace,
  }) : _directoryLoader = directoryLoader ?? getApplicationSupportDirectory;

  static const fileName = 'powermanager-latest-backup.json';

  final LocalBackupDirectoryLoader _directoryLoader;
  final BeforeLocalBackupReplace? beforeReplace;

  @override
  Future<LocalBackupMetadata> save(String contents) async {
    final directory = await _directoryLoader();
    await directory.create(recursive: true);
    final target = File('${directory.path}${Platform.pathSeparator}$fileName');
    final temporary = File('${target.path}.tmp');
    try {
      await temporary.writeAsString(contents, flush: true);
      await beforeReplace?.call(temporary, target);
      await temporary.rename(target.path);
      return (await metadata())!;
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  @override
  Future<LocalBackupMetadata?> metadata() async {
    final directory = await _directoryLoader();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    if (!await file.exists()) return null;
    final stat = await file.stat();
    return LocalBackupMetadata(
      path: file.path,
      modifiedAt: stat.modified,
      byteLength: stat.size,
    );
  }

  @override
  Future<Uint8List> readBytes() async {
    final directory = await _directoryLoader();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    return file.readAsBytes();
  }
}
