import 'package:power_manager/application/backup_content_digest.dart';
import 'package:power_manager/data/export/power_manager_export_dto.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:test/test.dart';

import '../support/backup_fixture.dart';

void main() {
  const digester = BackupContentDigester();

  test('transport metadata does not change the business digest', () {
    final source = backupFixture();
    final changedTransport = _copy(
      source,
      exportedAt: source.exportedAt.add(const Duration(days: 1)),
      appVersion: '99.0.0+different',
    );

    expect(digester.digest(changedTransport), digester.digest(source));
  });

  test('top-level entity order is canonical', () {
    final source = backupFixture();
    final first = RuleConfigVersion(
      version: 'first',
      values: {
        'z': [3, 2, 1],
        'a': {'y': 2, 'x': 1},
      },
      createdAt: backupFixtureNow,
    );
    final second = RuleConfigVersion(
      version: 'second',
      values: {
        'a': {'x': 1, 'y': 2},
        'z': [3, 2, 1],
      },
      createdAt: backupFixtureNow,
    );
    final forward = _copy(source, ruleVersions: [first, second]);
    final reverse = _copy(source, ruleVersions: [second, first]);

    expect(digester.digest(reverse), digester.digest(forward));
  });

  test('schema v2 activity feedback order is canonical', () {
    final source = backupFixtureV2();
    final reversed = _copy(
      source,
      activityFeedback: source.activityFeedback.reversed.toList(),
    );

    expect(digester.digest(reversed), digester.digest(source));
  });

  test('nested object insertion order does not change the digest', () {
    final source = backupFixture();
    final forwardRule = RuleConfigVersion(
      version: 'canonical',
      values: {
        'a': {'x': 1, 'y': 2},
        'z': [3, 2, 1],
      },
      createdAt: backupFixtureNow,
    );
    final reverseRule = RuleConfigVersion(
      version: 'canonical',
      values: {
        'z': [3, 2, 1],
        'a': {'y': 2, 'x': 1},
      },
      createdAt: backupFixtureNow,
    );

    expect(
      digester.digest(_copy(source, ruleVersions: [reverseRule])),
      digester.digest(_copy(source, ruleVersions: [forwardRule])),
    );
  });

  test('a business value change changes the digest', () {
    expect(
      digester.digest(backupFixture(baseEnergy: 101)),
      isNot(digester.digest(backupFixture(baseEnergy: 100))),
    );
  });

  test('digest is a stable SHA-256 lowercase hex value', () {
    final digest = digester.digest(backupFixture());

    expect(digest, hasLength(64));
    expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(digest), isTrue);
    expect(BackupContentDigester.version, 'sha256-canonical-business-v1');
  });
}

PowerManagerExportDto _copy(
  PowerManagerExportDto source, {
  DateTime? exportedAt,
  String? appVersion,
  List<RuleConfigVersion>? ruleVersions,
  List<ActivityFeedback>? activityFeedback,
}) {
  return PowerManagerExportDto(
    schemaVersion: source.schemaVersion,
    exportedAt: exportedAt ?? source.exportedAt,
    appVersion: appVersion ?? source.appVersion,
    appSettings: source.appSettings,
    ruleVersions: ruleVersions ?? source.ruleVersions,
    morningCheckIns: source.morningCheckIns,
    activityRecords: source.activityRecords,
    energyObservations: source.energyObservations,
    activityFeedback: activityFeedback ?? source.activityFeedback,
    dailySummaries: source.dailySummaries,
    promptReceipts: source.promptReceipts,
  );
}
