import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:power_manager/data/export/power_manager_export_dto.dart';

/// Produces a stable digest of schema-v1 business data.
///
/// Export timestamps and app versions are transport metadata, so they are not
/// part of the digest. Top-level entity arrays are sets in the backup contract
/// and are sorted before encoding.
final class BackupContentDigester {
  const BackupContentDigester();

  static const version = 'sha256-canonical-business-v1';

  static const _entityListKeys = <String>{
    'ruleConfigVersions',
    'morningCheckIns',
    'activityRecords',
    'energyObservations',
    'dailySummaries',
    'promptReceipts',
  };

  String digest(PowerManagerExportDto backup) {
    final payload = Map<String, Object?>.from(backup.toJson())
      ..remove('exportedAt')
      ..remove('appVersion');

    for (final key in _entityListKeys) {
      final rawItems = payload[key];
      if (rawItems is! List<Object?>) {
        throw StateError('Backup entity list is missing: $key');
      }
      final canonicalItems = rawItems.map(_canonicalize).toList();
      canonicalItems.sort(
        (left, right) => jsonEncode(left).compareTo(jsonEncode(right)),
      );
      payload[key] = canonicalItems;
    }

    final canonicalJson = jsonEncode(_canonicalize(payload));
    return sha256.convert(utf8.encode(canonicalJson)).toString();
  }
}

Object? _canonicalize(Object? value) {
  if (value is Map<Object?, Object?>) {
    final sorted = SplayTreeMap<String, Object?>();
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw StateError('Backup JSON object keys must be strings');
      }
      sorted[key] = _canonicalize(entry.value);
    }
    return sorted;
  }
  if (value is List<Object?>) {
    return value.map(_canonicalize).toList(growable: false);
  }
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  throw StateError('Unsupported backup JSON value: ${value.runtimeType}');
}
