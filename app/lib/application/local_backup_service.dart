import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/backup/local_backup_store.dart';

abstract interface class LocalBackupSaver {
  Future<LocalBackupMetadata> saveLatest();
}

enum LocalBackupFailureStage {
  export,
  validateExport,
  write,
  readBack,
  validateReadBack,
}

final class LocalBackupException implements Exception {
  const LocalBackupException(this.stage);

  final LocalBackupFailureStage stage;
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
    final JsonExportResult exported;
    try {
      exported = await exportService.create(exportedAt: clock.now());
    } on Object {
      throw const LocalBackupException(LocalBackupFailureStage.export);
    }

    try {
      codec.inspect(
        fileName: exported.fileName,
        bytes: Uint8List.fromList(utf8.encode(exported.contents)),
      );
    } on Object {
      throw const LocalBackupException(LocalBackupFailureStage.validateExport);
    }

    final LocalBackupMetadata metadata;
    try {
      metadata = await store.save(exported.contents);
    } on Object {
      throw const LocalBackupException(LocalBackupFailureStage.write);
    }

    final Uint8List storedBytes;
    try {
      storedBytes = await store.readBytes();
    } on Object {
      throw const LocalBackupException(LocalBackupFailureStage.readBack);
    }

    try {
      codec.inspect(
        fileName: FileLocalBackupStore.fileName,
        bytes: storedBytes,
      );
    } on Object {
      throw const LocalBackupException(
        LocalBackupFailureStage.validateReadBack,
      );
    }
    return metadata;
  }
}
