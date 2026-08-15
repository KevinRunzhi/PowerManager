import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/data/export/power_manager_export_dto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:test/test.dart';

import '../support/backup_fixture.dart';

void main() {
  const codec = JsonBackupCodec();

  test('valid schema v1 backup produces a read-only preview', () {
    final backup = backupFixture(baseEnergy: 120);
    final inspection = codec.inspect(
      fileName: 'powermanager.json',
      bytes: Uint8List.fromList(utf8.encode(jsonEncode(backup.toJson()))),
    );

    expect(inspection.backup.appSettings.baseEstimatedEnergy, 120);
    expect(inspection.counts.ruleVersions, 1);
    expect(inspection.counts.total, 2);
    expect(inspection.earliestLifeDay, isNull);
    expect(
      () => inspection.backup.ruleVersions.add(
        inspection.backup.ruleVersions.single,
      ),
      throwsUnsupportedError,
    );
  });

  test('schema v1 imports as legacy and can be re-exported as valid v2', () {
    final legacyInspection = _inspect(codec, backupFixture().toJson());

    expect(legacyInspection.backup.schemaVersion, 1);
    expect(legacyInspection.backup.activityFeedback, isEmpty);
    expect(
      legacyInspection.backup.energyObservations.every(
        (item) => item.contractVersion == null,
      ),
      isTrue,
    );

    final legacy = legacyInspection.backup;
    final upgradedJson = PowerManagerExportDto(
      schemaVersion: 2,
      exportedAt: legacy.exportedAt,
      appVersion: legacy.appVersion,
      appSettings: legacy.appSettings,
      ruleVersions: legacy.ruleVersions,
      morningCheckIns: legacy.morningCheckIns,
      activityRecords: legacy.activityRecords,
      energyObservations: legacy.energyObservations,
      activityFeedback: legacy.activityFeedback,
      dailySummaries: legacy.dailySummaries,
      promptReceipts: legacy.promptReceipts,
    ).toJson();
    final upgraded = _inspect(codec, upgradedJson);

    expect(upgraded.backup.schemaVersion, 2);
    expect(upgraded.backup.activityFeedback, isEmpty);
  });

  test('schema v2 round-trips full observation and feedback snapshots', () {
    final source = backupFixtureV2();
    final inspection = _inspect(codec, source.toJson());

    expect(inspection.backup.schemaVersion, 2);
    expect(inspection.counts.activityFeedback, 2);
    expect(inspection.backup.energyObservations, hasLength(2));
    expect(
      inspection.backup.energyObservations.first.contractVersion,
      mvpBObservationContractV1,
    );
    expect(
      inspection.backup.activityFeedback.last.status,
      ActivityFeedbackStatus.invalidated,
    );
    expect(
      inspection.backup.activityFeedback.last.invalidationReason,
      ActivityFeedbackInvalidationReason.activityDeleted,
    );

    final reparsed = _inspect(codec, inspection.backup.toJson());
    expect(reparsed.counts.total, inspection.counts.total);
    expect(reparsed.backup.toJson(), inspection.backup.toJson());
  });

  test('unsupported schema, extension and malformed UTF-8 are rejected', () {
    final json = backupFixture().toJson()..['schemaVersion'] = 3;

    expect(
      () => codec.inspect(
        fileName: 'backup.json',
        bytes: Uint8List.fromList(utf8.encode(jsonEncode(json))),
      ),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => codec.inspect(
        fileName: 'backup.txt',
        bytes: Uint8List.fromList(utf8.encode('{}')),
      ),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => codec.inspect(
        fileName: 'backup.json',
        bytes: Uint8List.fromList([0xC3, 0x28]),
      ),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test(
    'schema v2 rejects missing fields, broken FK, duplicates, and enums',
    () {
      final cases = <Map<String, Object?>>[];

      final missingSnapshot = backupFixtureV2().toJson();
      final observation =
          (missingSnapshot['energyObservations']! as List<Object?>).first!
              as Map<String, Object?>;
      observation.remove('modelRegimeKey');
      cases.add(missingSnapshot);

      final mismatchedOrdinal = backupFixtureV2().toJson();
      final ordinalObservation =
          (mismatchedOrdinal['energyObservations']! as List<Object?>).first!
              as Map<String, Object?>;
      ordinalObservation['estimatedOrdinalAtObservation'] = 0;
      cases.add(mismatchedOrdinal);

      final mismatchedRegimeKey = backupFixtureV2().toJson();
      final regimeObservation =
          (mismatchedRegimeKey['energyObservations']! as List<Object?>).first!
              as Map<String, Object?>;
      regimeObservation['modelRegimeKey'] =
          'model-regime-sha256-v1:${List.filled(64, '0').join()}';
      cases.add(mismatchedRegimeKey);

      final missingActivity = backupFixtureV2().toJson();
      final missingActivityFeedback =
          (missingActivity['activityFeedback']! as List<Object?>).first!
              as Map<String, Object?>;
      missingActivityFeedback['activityRecordId'] = 'missing-activity';
      cases.add(missingActivity);

      final duplicateActive = backupFixtureV2().toJson();
      final feedback = duplicateActive['activityFeedback']! as List<Object?>;
      final duplicate = Map<String, Object?>.from(
        feedback.first! as Map<String, Object?>,
      )..['id'] = 'feedback-active-duplicate';
      feedback.add(duplicate);
      cases.add(duplicateActive);

      final unknownDirection = backupFixtureV2().toJson();
      final unknownFeedback =
          (unknownDirection['activityFeedback']! as List<Object?>).first!
              as Map<String, Object?>;
      unknownFeedback['direction'] = 'surprising';
      cases.add(unknownDirection);

      final missingFeedbackField = backupFixtureV2().toJson();
      final incompleteFeedback =
          (missingFeedbackField['activityFeedback']! as List<Object?>).first!
              as Map<String, Object?>;
      incompleteFeedback.remove('invalidationReason');
      cases.add(missingFeedbackField);

      for (final json in cases) {
        expect(
          () => _inspect(codec, json),
          throwsA(isA<BackupFormatException>()),
        );
      }
    },
  );

  test(
    'missing references and broken rule values are rejected before write',
    () {
      final missingReference = backupFixture().toJson();
      final settings = missingReference['appSettings']! as Map<String, Object?>;
      settings['activeRuleVersion'] = 'missing';
      final brokenRule = backupFixture().toJson();
      final versions = brokenRule['ruleConfigVersions']! as List<Object?>;
      final version = versions.single! as Map<String, Object?>;
      final values = version['values']! as Map<String, Object?>;
      final rules = values['activityRules']! as Map<String, Object?>;
      final firstRule = rules.values.first! as Map<String, Object?>;
      firstRule.remove('15');

      for (final json in [missingReference, brokenRule]) {
        expect(
          () => codec.inspect(
            fileName: 'backup.json',
            bytes: Uint8List.fromList(utf8.encode(jsonEncode(json))),
          ),
          throwsA(isA<BackupFormatException>()),
        );
      }
    },
  );

  test('file size limit is enforced before JSON parsing', () {
    expect(
      () => codec.inspect(
        fileName: 'backup.json',
        bytes: Uint8List(JsonBackupCodec.maxBytes + 1),
      ),
      throwsA(
        isA<BackupFormatException>().having(
          (error) => error.message,
          'message',
          contains('10 MiB'),
        ),
      ),
    );
  });
}

BackupInspection _inspect(JsonBackupCodec codec, Map<String, Object?> json) {
  return codec.inspect(
    fileName: 'backup.json',
    bytes: Uint8List.fromList(utf8.encode(jsonEncode(json))),
  );
}
