import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/backup/local_backup_store.dart';

abstract interface class LocalBackupSaver {
  Future<LocalBackupMetadata> saveLatest();
}

final class LocalBackupService implements LocalBackupSaver {
  const LocalBackupService({
    required this.exportService,
    required this.codec,
    required this.store,
    required this.clock,
  });

  final JsonExporter exportService;
  final JsonBackupCodec codec;
  final LocalBackupStore store;
  final Clock clock;

  @override
  Future<LocalBackupMetadata> saveLatest() async {
    final exported = await exportService.create(exportedAt: clock.now());
    codec.inspect(
      fileName: exported.fileName,
      bytes: Uint8List.fromList(utf8.encode(exported.contents)),
    );
    final metadata = await store.save(exported.contents);
    codec.inspect(
      fileName: FileLocalBackupStore.fileName,
      bytes: await store.readBytes(),
    );
    return metadata;
  }
}
