import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:power_manager/application/json_backup_restore_service.dart';
import 'package:power_manager/data/backup/recoverable_atomic_text_file.dart';

typedef SupportDirectoryLoader = Future<Directory> Function();

final class LocalBackupSafetyStore implements BackupSafetyStore {
  LocalBackupSafetyStore({SupportDirectoryLoader? directoryLoader})
    : _directoryLoader = directoryLoader ?? getApplicationSupportDirectory;

  static const fileName = 'powermanager-before-last-restore.json';

  final SupportDirectoryLoader _directoryLoader;

  @override
  Future<void> save(String contents) async {
    final directory = await _directoryLoader();
    final target = File('${directory.path}${Platform.pathSeparator}$fileName');
    await RecoverableAtomicTextFile(target).write(contents);
  }

  @override
  Future<String?> existingPath() async {
    final directory = await _directoryLoader();
    return RecoverableAtomicTextFile(
      File('${directory.path}${Platform.pathSeparator}$fileName'),
    ).read((file) async => await file.exists() ? file.path : null);
  }
}
