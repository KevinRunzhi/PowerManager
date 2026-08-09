import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:power_manager/application/json_backup_restore_service.dart';

typedef SupportDirectoryLoader = Future<Directory> Function();

final class LocalBackupSafetyStore implements BackupSafetyStore {
  LocalBackupSafetyStore({SupportDirectoryLoader? directoryLoader})
    : _directoryLoader = directoryLoader ?? getApplicationSupportDirectory;

  static const fileName = 'powermanager-before-last-restore.json';

  final SupportDirectoryLoader _directoryLoader;

  @override
  Future<void> save(String contents) async {
    final directory = await _directoryLoader();
    await directory.create(recursive: true);
    final target = File('${directory.path}${Platform.pathSeparator}$fileName');
    final temporary = File('${target.path}.tmp');
    try {
      await temporary.writeAsString(contents, flush: true);
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  @override
  Future<String?> existingPath() async {
    final directory = await _directoryLoader();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    return await file.exists() ? file.path : null;
  }
}
