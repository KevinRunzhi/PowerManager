import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/json_backup_codec.dart';
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

  test('unsupported schema, extension and malformed UTF-8 are rejected', () {
    final json = backupFixture().toJson()..['schemaVersion'] = 2;

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
