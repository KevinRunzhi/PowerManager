import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:power_manager/application/mvp_b_upgrade_readiness_service.dart';
import 'package:power_manager/data/backup/recoverable_atomic_text_file.dart';

typedef MvpBReadinessDirectoryLoader = Future<Directory> Function();
typedef BeforeMvpBReadinessReplace =
    Future<void> Function(File temporary, File target);

final class FileMvpBUpgradeReadinessStore implements MvpBUpgradeReadinessStore {
  FileMvpBUpgradeReadinessStore({
    MvpBReadinessDirectoryLoader? directoryLoader,
    this.beforeReplace,
  }) : _directoryLoader = directoryLoader ?? getApplicationSupportDirectory;

  static const fileName = 'powermanager-mvp-b-upgrade-readiness.json';
  static const formatVersion = 'mvp-b-upgrade-readiness-v1';
  static const _maximumBytes = 16 * 1024;

  final MvpBReadinessDirectoryLoader _directoryLoader;
  final BeforeMvpBReadinessReplace? beforeReplace;

  @override
  Future<MvpBUpgradeReadinessProof?> load() async {
    return RecoverableAtomicTextFile(await _file()).read(_load);
  }

  Future<MvpBUpgradeReadinessProof?> _load(File file) async {
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > _maximumBytes) {
      throw const FormatException('Upgrade readiness proof is too large');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
    } on Object {
      throw const FormatException('Upgrade readiness proof is invalid');
    }
    if (decoded is! Map<String, Object?> ||
        decoded['formatVersion'] != formatVersion ||
        decoded['integrityStatus'] != 'passed' ||
        !decoded.containsKey('failureReason') ||
        decoded['failureReason'] != null) {
      throw const FormatException('Upgrade readiness proof is invalid');
    }

    final verifiedAt = _utcDate(decoded, 'verifiedAt');
    final backupModifiedAt = _utcDate(decoded, 'backupModifiedAt');
    final backupByteLength = _positiveInt(decoded, 'backupByteLength');
    final backupSchemaVersion = _positiveInt(decoded, 'backupSchemaVersion');
    final digestVersion = _string(decoded, 'digestVersion');
    final backupContentDigest = _digest(decoded, 'backupContentDigest');
    final currentContentDigest = _digest(decoded, 'currentContentDigest');
    return MvpBUpgradeReadinessProof(
      verifiedAt: verifiedAt,
      backupModifiedAt: backupModifiedAt,
      backupByteLength: backupByteLength,
      backupSchemaVersion: backupSchemaVersion,
      digestVersion: digestVersion,
      backupContentDigest: backupContentDigest,
      currentContentDigest: currentContentDigest,
    );
  }

  @override
  Future<void> save(MvpBUpgradeReadinessProof proof) async {
    final target = await _file();
    final contents = jsonEncode({
      'formatVersion': formatVersion,
      'verifiedAt': proof.verifiedAt.toUtc().toIso8601String(),
      'backupModifiedAt': proof.backupModifiedAt.toUtc().toIso8601String(),
      'backupByteLength': proof.backupByteLength,
      'backupSchemaVersion': proof.backupSchemaVersion,
      'digestVersion': proof.digestVersion,
      'backupContentDigest': proof.backupContentDigest,
      'currentContentDigest': proof.currentContentDigest,
      'integrityStatus': 'passed',
      'failureReason': null,
    });
    await RecoverableAtomicTextFile(
      target,
      beforeReplace: beforeReplace,
    ).write(contents);
  }

  Future<File> _file() async {
    final directory = await _directoryLoader();
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }
}

DateTime _utcDate(Map<String, Object?> json, String key) {
  final raw = _string(json, key);
  if (!raw.endsWith('Z')) {
    throw const FormatException('Upgrade readiness timestamp must be UTC');
  }
  final parsed = DateTime.tryParse(raw);
  if (parsed == null || !parsed.isUtc) {
    throw const FormatException('Upgrade readiness timestamp is invalid');
  }
  return parsed;
}

int _positiveInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int || value <= 0) {
    throw FormatException('Upgrade readiness $key is invalid');
  }
  return value;
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Upgrade readiness $key is invalid');
  }
  return value;
}

String _digest(Map<String, Object?> json, String key) {
  final value = _string(json, key);
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw FormatException('Upgrade readiness $key is invalid');
  }
  return value;
}
