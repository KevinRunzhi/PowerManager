import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:test/test.dart';

import '../support/production_backup_fixture.dart';

const _codec = JsonBackupCodec(
  supportedBaselineAlgorithms: {productionFixtureAlgorithm},
  supportedBaselineConfigs: {productionFixtureConfig},
);

void main() {
  test('configured schema v4 round-trips a production candidate graph', () {
    final fixture = productionBackupFixture();
    final inspected = _inspect(_codec, fixture.toJson());

    expect(inspected.backup.schemaVersion, 4);
    expect(inspected.backup.personalizationVersions, hasLength(2));
    expect(
      inspected.backup.personalizationVersions.last.status,
      PersonalizationVersionStatus.awaitingReview,
    );
    expect(inspected.backup.learningRuns, hasLength(2));
    expect(
      inspected.backup.learningRuns.last.result,
      LearningRunResult.candidate,
    );
    expect(inspected.backup.learningConsents, hasLength(1));
    expect(inspected.backup.learningNotices, hasLength(1));

    final second = _inspect(_codec, inspected.backup.toJson());
    expect(
      second.backup.learningRuns.last.evidenceHash,
      fixture.learningRuns.last.evidenceHash,
    );
    expect(
      second.backup.personalizationVersions.last.id,
      fixture.personalizationVersions.last.id,
    );
  });

  test('formal codec rejects every non-allowlisted production run', () {
    final fixture = productionBackupFixture();

    expect(
      () => _inspect(const JsonBackupCodec(), fixture.toJson()),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('preproduction watermark remains forbidden even when allowlisted', () {
    const watermarkedAlgorithm = 'baseline-preproduction-do-not-ship';
    final fixture = productionBackupFixture(
      algorithmVersion: watermarkedAlgorithm,
    );
    const watermarkedCodec = JsonBackupCodec(
      supportedBaselineAlgorithms: {watermarkedAlgorithm},
      supportedBaselineConfigs: {productionFixtureConfig},
    );

    expect(
      () => _inspect(watermarkedCodec, fixture.toJson()),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('non-off learning mode requires the current family disclosure', () {
    final json = _mutableJson(productionBackupFixture().toJson());
    json['learningConsents'] = <Object?>[];

    expect(() => _inspect(_codec, json), throwsA(isA<BackupFormatException>()));
  });

  test('zero or multiple active personalization versions are rejected', () {
    final zero = _mutableJson(productionBackupFixture().toJson());
    final zeroVersions = zero['personalizationVersions']! as List<Object?>;
    final initial = zeroVersions.first! as Map<String, Object?>;
    initial['status'] = PersonalizationVersionStatus.superseded.code;
    initial['endedAt'] = '2026-08-15T10:00:00.000000Z';

    final multiple = _mutableJson(productionBackupFixture().toJson());
    final multipleVersions =
        multiple['personalizationVersions']! as List<Object?>;
    final candidate = multipleVersions.last! as Map<String, Object?>;
    candidate['status'] = PersonalizationVersionStatus.active.code;
    candidate['scheduleSource'] =
        PersonalizationScheduleSource.reviewAccepted.code;
    candidate['effectiveLifeDay'] = '2026-08-16';
    candidate['activatedAt'] = '2026-08-16T04:00:00.000000Z';

    expect(() => _inspect(_codec, zero), throwsA(isA<BackupFormatException>()));
    expect(
      () => _inspect(_codec, multiple),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('candidate values and source run relationship are strict', () {
    final candidateMismatch = _mutableJson(productionBackupFixture().toJson());
    final runs = candidateMismatch['learningRuns']! as List<Object?>;
    final run = runs.last! as Map<String, Object?>;
    run['candidateValuesJson'] = '{"baseEnergy":97}';

    final sourceMismatch = _mutableJson(productionBackupFixture().toJson());
    final sourceRuns = sourceMismatch['learningRuns']! as List<Object?>;
    final sourceRun = sourceRuns.last! as Map<String, Object?>;
    sourceRun['sourcePersonalizationVersionId'] = 'missing-model';

    expect(
      () => _inspect(_codec, candidateMismatch),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => _inspect(_codec, sourceMismatch),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('automatic schedule requires its persistent notice and 24 hours', () {
    final valid = productionBackupFixture(automaticScheduled: true);
    expect(() => _inspect(_codec, valid.toJson()), returnsNormally);

    final missingNotice = _mutableJson(valid.toJson());
    missingNotice['learningNotices'] = <Object?>[];
    expect(
      () => _inspect(_codec, missingNotice),
      throwsA(isA<BackupFormatException>()),
    );

    final short = productionBackupFixture(
      automaticScheduled: true,
      shortAutomaticNotice: true,
    );
    expect(
      () => _inspect(_codec, short.toJson()),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test(
    'notice identity, run family and lifecycle timestamps are immutable',
    () {
      final wrongDedup = _mutableJson(productionBackupFixture().toJson());
      final notices = wrongDedup['learningNotices']! as List<Object?>;
      final notice = notices.single! as Map<String, Object?>;
      notice['dedupKey'] = 'tampered';

      final beforeVersion = _mutableJson(productionBackupFixture().toJson());
      final beforeNotices = beforeVersion['learningNotices']! as List<Object?>;
      final beforeNotice = beforeNotices.single! as Map<String, Object?>;
      beforeNotice['createdAt'] = '2026-08-01T00:00:00.000000Z';

      expect(
        () => _inspect(_codec, wrongDedup),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => _inspect(_codec, beforeVersion),
        throwsA(isA<BackupFormatException>()),
      );
    },
  );
}

BackupInspection _inspect(JsonBackupCodec codec, Map<String, Object?> json) {
  return codec.inspect(
    fileName: 'schema-v4.json',
    bytes: Uint8List.fromList(utf8.encode(jsonEncode(json))),
  );
}

Map<String, Object?> _mutableJson(Map<String, Object?> value) {
  return jsonDecode(jsonEncode(value)) as Map<String, Object?>;
}
