import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/backup_content_digest.dart';
import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/application/local_backup_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/backup/local_backup_store.dart';

enum MvpBUpgradeReadinessStatus {
  notChecked,
  ready,
  latestBackupMissing,
  latestBackupChanged,
  currentDataChanged,
  contentMismatch,
  invalidBackup,
  invalidProof,
  currentDataInvalid,
  currentExportFailed,
  backupWriteFailed,
  backupReadFailed,
  preparationFailed,
  checkFailed,
}

final class MvpBUpgradeReadinessProof {
  const MvpBUpgradeReadinessProof({
    required this.verifiedAt,
    required this.backupModifiedAt,
    required this.backupByteLength,
    required this.backupSchemaVersion,
    required this.digestVersion,
    required this.backupContentDigest,
    required this.currentContentDigest,
  });

  final DateTime verifiedAt;
  final DateTime backupModifiedAt;
  final int backupByteLength;
  final int backupSchemaVersion;
  final String digestVersion;
  final String backupContentDigest;
  final String currentContentDigest;
}

abstract interface class MvpBUpgradeReadinessStore {
  Future<MvpBUpgradeReadinessProof?> load();
  Future<void> save(MvpBUpgradeReadinessProof proof);
}

abstract interface class MvpBUpgradeReadinessChecker {
  Future<MvpBUpgradeReadinessReport> check();
}

abstract interface class MvpBUpgradeReadinessPreparer
    implements MvpBUpgradeReadinessChecker {
  Future<MvpBUpgradeReadinessReport> prepare();
}

final class MvpBUpgradeReadinessReport {
  const MvpBUpgradeReadinessReport({
    required this.status,
    required this.checkedAt,
    this.verifiedAt,
    this.localBackup,
    this.backupSchemaVersion,
  });

  final MvpBUpgradeReadinessStatus status;
  final DateTime checkedAt;
  final DateTime? verifiedAt;
  final LocalBackupMetadata? localBackup;
  final int? backupSchemaVersion;

  bool get isReady => status == MvpBUpgradeReadinessStatus.ready;
}

final class MvpBUpgradeReadinessService
    implements MvpBUpgradeReadinessPreparer {
  MvpBUpgradeReadinessService({
    required this.preparer,
    required this.localBackupSaver,
    required this.localBackupStore,
    required this.readinessStore,
    required this.exportService,
    required this.codec,
    required this.digester,
    required this.clock,
  });

  final OperationPreparer preparer;
  final LocalBackupSaver localBackupSaver;
  final LocalBackupStore localBackupStore;
  final MvpBUpgradeReadinessStore readinessStore;
  final JsonExporter exportService;
  final JsonBackupCodec codec;
  final BackupContentDigester digester;
  final Clock clock;

  Future<MvpBUpgradeReadinessReport>? _preparationInFlight;

  @override
  Future<MvpBUpgradeReadinessReport> prepare() {
    final active = _preparationInFlight;
    if (active != null) return active;

    late final Future<MvpBUpgradeReadinessReport> task;
    task = _prepare().whenComplete(() {
      if (identical(_preparationInFlight, task)) {
        _preparationInFlight = null;
      }
    });
    _preparationInFlight = task;
    return task;
  }

  Future<MvpBUpgradeReadinessReport> _prepare() async {
    LocalBackupMetadata? metadata;
    try {
      await preparer.prepare(PreparationTrigger.beforeWrite);
      try {
        metadata = await localBackupSaver.saveLatest();
      } on LocalBackupException catch (error) {
        return _report(_statusForLocalBackupFailure(error.stage));
      }

      final Uint8List backupBytes;
      try {
        backupBytes = await localBackupStore.readBytes();
      } on Object {
        return _report(
          MvpBUpgradeReadinessStatus.backupReadFailed,
          metadata: metadata,
        );
      }
      final backupInspection = codec.inspect(
        fileName: FileLocalBackupStore.fileName,
        bytes: backupBytes,
      );
      final backupDigest = digester.digest(backupInspection.backup);

      final BackupInspection currentInspection;
      try {
        final currentExport = await exportService.create(
          exportedAt: clock.now(),
        );
        currentInspection = codec.inspect(
          fileName: currentExport.fileName,
          bytes: _bytes(currentExport.contents),
        );
      } on BackupFormatException {
        return _report(
          MvpBUpgradeReadinessStatus.currentDataInvalid,
          metadata: metadata,
          schemaVersion: backupInspection.backup.schemaVersion,
        );
      } on Object {
        return _report(
          MvpBUpgradeReadinessStatus.currentExportFailed,
          metadata: metadata,
          schemaVersion: backupInspection.backup.schemaVersion,
        );
      }
      final currentDigest = digester.digest(currentInspection.backup);
      if (backupDigest != currentDigest) {
        return _report(
          MvpBUpgradeReadinessStatus.contentMismatch,
          metadata: metadata,
          schemaVersion: backupInspection.backup.schemaVersion,
        );
      }

      final verifiedAt = clock.now().toUtc();
      final proof = MvpBUpgradeReadinessProof(
        verifiedAt: verifiedAt,
        backupModifiedAt: metadata.modifiedAt.toUtc(),
        backupByteLength: metadata.byteLength,
        backupSchemaVersion: backupInspection.backup.schemaVersion,
        digestVersion: BackupContentDigester.version,
        backupContentDigest: backupDigest,
        currentContentDigest: currentDigest,
      );
      await readinessStore.save(proof);
      final persistedProof = await readinessStore.load();
      if (persistedProof == null || !_sameProof(persistedProof, proof)) {
        return _report(
          MvpBUpgradeReadinessStatus.preparationFailed,
          metadata: metadata,
          schemaVersion: proof.backupSchemaVersion,
        );
      }
      return MvpBUpgradeReadinessReport(
        status: MvpBUpgradeReadinessStatus.ready,
        checkedAt: verifiedAt,
        verifiedAt: verifiedAt,
        localBackup: metadata,
        backupSchemaVersion: proof.backupSchemaVersion,
      );
    } on BackupFormatException {
      return _report(
        MvpBUpgradeReadinessStatus.invalidBackup,
        metadata: metadata,
      );
    } on Object {
      return _report(
        MvpBUpgradeReadinessStatus.preparationFailed,
        metadata: metadata,
      );
    }
  }

  @override
  Future<MvpBUpgradeReadinessReport> check() async {
    final active = _preparationInFlight;
    if (active != null) return active;

    final MvpBUpgradeReadinessProof? proof;
    try {
      proof = await readinessStore.load();
    } on FormatException {
      return _report(MvpBUpgradeReadinessStatus.invalidProof);
    } on Object {
      return _report(MvpBUpgradeReadinessStatus.checkFailed);
    }

    final LocalBackupMetadata? metadata;
    try {
      metadata = await localBackupStore.metadata();
    } on Object {
      return _report(MvpBUpgradeReadinessStatus.checkFailed);
    }
    if (metadata == null) {
      return _report(MvpBUpgradeReadinessStatus.latestBackupMissing);
    }
    if (proof == null) {
      return _report(MvpBUpgradeReadinessStatus.notChecked, metadata: metadata);
    }
    if (proof.digestVersion != BackupContentDigester.version ||
        proof.backupSchemaVersion != JsonExportService.schemaVersion) {
      return _report(
        MvpBUpgradeReadinessStatus.invalidProof,
        metadata: metadata,
      );
    }
    if (proof.backupByteLength != metadata.byteLength ||
        !proof.backupModifiedAt.isAtSameMomentAs(metadata.modifiedAt)) {
      return _report(
        MvpBUpgradeReadinessStatus.latestBackupChanged,
        metadata: metadata,
      );
    }

    final BackupInspection backupInspection;
    try {
      backupInspection = codec.inspect(
        fileName: FileLocalBackupStore.fileName,
        bytes: await localBackupStore.readBytes(),
      );
    } on BackupFormatException {
      return _report(
        MvpBUpgradeReadinessStatus.invalidBackup,
        metadata: metadata,
      );
    } on Object {
      return _report(
        MvpBUpgradeReadinessStatus.checkFailed,
        metadata: metadata,
      );
    }

    final backupDigest = digester.digest(backupInspection.backup);
    if (backupDigest != proof.backupContentDigest) {
      return _report(
        MvpBUpgradeReadinessStatus.latestBackupChanged,
        metadata: metadata,
        schemaVersion: backupInspection.backup.schemaVersion,
      );
    }

    final BackupInspection currentInspection;
    try {
      final currentExport = await exportService.create(exportedAt: clock.now());
      currentInspection = codec.inspect(
        fileName: currentExport.fileName,
        bytes: _bytes(currentExport.contents),
      );
    } on BackupFormatException {
      return _report(
        MvpBUpgradeReadinessStatus.currentDataInvalid,
        metadata: metadata,
      );
    } on Object {
      return _report(
        MvpBUpgradeReadinessStatus.checkFailed,
        metadata: metadata,
      );
    }

    final currentDigest = digester.digest(currentInspection.backup);
    if (currentDigest != proof.currentContentDigest) {
      return _report(
        MvpBUpgradeReadinessStatus.currentDataChanged,
        metadata: metadata,
        schemaVersion: backupInspection.backup.schemaVersion,
      );
    }
    if (currentDigest != backupDigest) {
      return _report(
        MvpBUpgradeReadinessStatus.contentMismatch,
        metadata: metadata,
        schemaVersion: backupInspection.backup.schemaVersion,
      );
    }

    return MvpBUpgradeReadinessReport(
      status: MvpBUpgradeReadinessStatus.ready,
      checkedAt: clock.now().toUtc(),
      verifiedAt: proof.verifiedAt,
      localBackup: metadata,
      backupSchemaVersion: backupInspection.backup.schemaVersion,
    );
  }

  MvpBUpgradeReadinessReport _report(
    MvpBUpgradeReadinessStatus status, {
    LocalBackupMetadata? metadata,
    int? schemaVersion,
  }) {
    return MvpBUpgradeReadinessReport(
      status: status,
      checkedAt: clock.now().toUtc(),
      localBackup: metadata,
      backupSchemaVersion: schemaVersion,
    );
  }
}

Uint8List _bytes(String contents) => Uint8List.fromList(utf8.encode(contents));

bool _sameProof(
  MvpBUpgradeReadinessProof left,
  MvpBUpgradeReadinessProof right,
) {
  return left.verifiedAt.isAtSameMomentAs(right.verifiedAt) &&
      left.backupModifiedAt.isAtSameMomentAs(right.backupModifiedAt) &&
      left.backupByteLength == right.backupByteLength &&
      left.backupSchemaVersion == right.backupSchemaVersion &&
      left.digestVersion == right.digestVersion &&
      left.backupContentDigest == right.backupContentDigest &&
      left.currentContentDigest == right.currentContentDigest;
}

MvpBUpgradeReadinessStatus _statusForLocalBackupFailure(
  LocalBackupFailureStage stage,
) {
  return switch (stage) {
    LocalBackupFailureStage.export =>
      MvpBUpgradeReadinessStatus.currentExportFailed,
    LocalBackupFailureStage.validateExport =>
      MvpBUpgradeReadinessStatus.currentDataInvalid,
    LocalBackupFailureStage.write =>
      MvpBUpgradeReadinessStatus.backupWriteFailed,
    LocalBackupFailureStage.readBack =>
      MvpBUpgradeReadinessStatus.backupReadFailed,
    LocalBackupFailureStage.validateReadBack =>
      MvpBUpgradeReadinessStatus.invalidBackup,
  };
}
