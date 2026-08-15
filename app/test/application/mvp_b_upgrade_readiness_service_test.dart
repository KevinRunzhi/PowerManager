import 'dart:convert';
import 'dart:typed_data';

import 'package:power_manager/application/backup_content_digest.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/json_backup_codec.dart';
import 'package:power_manager/application/json_export_service.dart';
import 'package:power_manager/application/local_backup_service.dart';
import 'package:power_manager/application/mvp_b_upgrade_readiness_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/backup/local_backup_store.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

import '../support/backup_fixture.dart';

void main() {
  test(
    'prepare validates backup, matches current data, and saves proof',
    () async {
      final harness = _Harness();

      final first = harness.service.prepare();
      final second = harness.service.prepare();
      final reports = await Future.wait([first, second]);

      expect(reports.every((report) => report.isReady), isTrue);
      expect(harness.preparer.calls, [PreparationTrigger.beforeWrite]);
      expect(harness.saver.calls, 1);
      expect(harness.proofStore.proof, isNotNull);
      expect(
        harness.proofStore.proof!.backupContentDigest,
        harness.proofStore.proof!.currentContentDigest,
      );
      expect(harness.proofStore.proof!.backupSchemaVersion, 2);
      expect((await harness.service.check()).isReady, isTrue);
    },
  );

  test('current business data change invalidates a previous proof', () async {
    final harness = _Harness();
    expect((await harness.service.prepare()).isReady, isTrue);

    harness.exporter.contents = _json(baseEnergy: 110);
    final report = await harness.service.check();

    expect(report.status, MvpBUpgradeReadinessStatus.currentDataChanged);
  });

  test('latest backup replacement invalidates a previous proof', () async {
    final harness = _Harness();
    expect((await harness.service.prepare()).isReady, isTrue);

    await harness.backupStore.save(_json(baseEnergy: 110));
    final report = await harness.service.check();

    expect(report.status, MvpBUpgradeReadinessStatus.latestBackupChanged);
  });

  test('corrupted bytes with unchanged metadata are reported safely', () async {
    final harness = _Harness();
    expect((await harness.service.prepare()).isReady, isTrue);

    harness.backupStore.replaceBytesWithoutMetadata('{broken');
    final report = await harness.service.check();

    expect(report.status, MvpBUpgradeReadinessStatus.invalidBackup);
  });

  test('missing proof and missing backup have distinct states', () async {
    final withBackup = _Harness();
    await withBackup.backupStore.save(_json());
    expect(
      (await withBackup.service.check()).status,
      MvpBUpgradeReadinessStatus.notChecked,
    );

    final withoutBackup = _Harness();
    expect(
      (await withoutBackup.service.check()).status,
      MvpBUpgradeReadinessStatus.latestBackupMissing,
    );
  });

  test('invalid proof never reports ready', () async {
    final harness = _Harness();
    await harness.backupStore.save(_json());
    harness.proofStore.failLoad = true;

    final report = await harness.service.check();

    expect(report.status, MvpBUpgradeReadinessStatus.invalidProof);
  });

  test('prepare rejects a backup that differs from current data', () async {
    final harness = _Harness(
      savedBackupContents: _json(baseEnergy: 100),
      currentContents: _json(baseEnergy: 110),
    );

    final report = await harness.service.prepare();

    expect(report.status, MvpBUpgradeReadinessStatus.contentMismatch);
    expect(harness.proofStore.proof, isNull);
  });

  test(
    'prepare distinguishes invalid current data from an invalid backup',
    () async {
      final harness = _Harness(
        savedBackupContents: _json(),
        currentContents: '{"schemaVersion":1}',
      );

      final report = await harness.service.prepare();

      expect(report.status, MvpBUpgradeReadinessStatus.currentDataInvalid);
    },
  );

  test('save or proof persistence failure never reports ready', () async {
    final saveFailure = _Harness()..saver.fail = true;
    expect(
      (await saveFailure.service.prepare()).status,
      MvpBUpgradeReadinessStatus.preparationFailed,
    );

    final proofFailure = _Harness()..proofStore.failSave = true;
    expect(
      (await proofFailure.service.prepare()).status,
      MvpBUpgradeReadinessStatus.preparationFailed,
    );

    final missingReadBack = _Harness()..proofStore.dropSave = true;
    expect(
      (await missingReadBack.service.prepare()).status,
      MvpBUpgradeReadinessStatus.preparationFailed,
    );
  });

  test(
    'prepare exposes stable export, write, and read failure states',
    () async {
      final localExportFailure = _Harness()
        ..saver.failureStage = LocalBackupFailureStage.export;
      expect(
        (await localExportFailure.service.prepare()).status,
        MvpBUpgradeReadinessStatus.currentExportFailed,
      );

      final writeFailure = _Harness()
        ..saver.failureStage = LocalBackupFailureStage.write;
      expect(
        (await writeFailure.service.prepare()).status,
        MvpBUpgradeReadinessStatus.backupWriteFailed,
      );

      final saverReadFailure = _Harness()
        ..saver.failureStage = LocalBackupFailureStage.readBack;
      expect(
        (await saverReadFailure.service.prepare()).status,
        MvpBUpgradeReadinessStatus.backupReadFailed,
      );

      final verificationReadFailure = _Harness();
      verificationReadFailure.backupStore.failRead = true;
      expect(
        (await verificationReadFailure.service.prepare()).status,
        MvpBUpgradeReadinessStatus.backupReadFailed,
      );

      final currentExportFailure = _Harness()..exporter.fail = true;
      expect(
        (await currentExportFailure.service.prepare()).status,
        MvpBUpgradeReadinessStatus.currentExportFailed,
      );
    },
  );
}

String _json({int baseEnergy = 100}) =>
    jsonEncode(backupFixtureV2(baseEnergy: baseEnergy).toJson());

final class _Harness {
  _Harness({String? savedBackupContents, String? currentContents})
    : exporter = _MutableExporter(currentContents ?? _json()),
      backupStore = _MemoryLocalBackupStore(),
      proofStore = _MemoryProofStore(),
      preparer = _FakePreparer(),
      clock = const _FixedClock() {
    saver = _FakeLocalBackupSaver(
      store: backupStore,
      contents: savedBackupContents ?? currentContents ?? _json(),
    );
    service = MvpBUpgradeReadinessService(
      preparer: preparer,
      localBackupSaver: saver,
      localBackupStore: backupStore,
      readinessStore: proofStore,
      exportService: exporter,
      codec: const JsonBackupCodec(),
      digester: const BackupContentDigester(),
      clock: clock,
    );
  }

  final _MutableExporter exporter;
  final _MemoryLocalBackupStore backupStore;
  final _MemoryProofStore proofStore;
  final _FakePreparer preparer;
  final _FixedClock clock;
  late final _FakeLocalBackupSaver saver;
  late final MvpBUpgradeReadinessService service;
}

final class _MutableExporter implements JsonExporter {
  _MutableExporter(this.contents);

  String contents;
  var fail = false;

  @override
  Future<JsonExportResult> create({required DateTime exportedAt}) async {
    if (fail) throw StateError('injected current export failure');
    return JsonExportResult(fileName: 'current.json', contents: contents);
  }
}

final class _FakeLocalBackupSaver implements LocalBackupSaver {
  _FakeLocalBackupSaver({required this.store, required this.contents});

  final _MemoryLocalBackupStore store;
  final String contents;
  var calls = 0;
  var fail = false;
  LocalBackupFailureStage? failureStage;

  @override
  Future<LocalBackupMetadata> saveLatest() async {
    calls++;
    if (failureStage case final stage?) {
      throw LocalBackupException(stage);
    }
    if (fail) throw StateError('injected save failure');
    return store.save(contents);
  }
}

final class _MemoryLocalBackupStore implements LocalBackupStore {
  Uint8List? _bytes;
  LocalBackupMetadata? _metadata;
  var _revision = 0;
  var failRead = false;

  @override
  Future<LocalBackupMetadata> save(String contents) async {
    _revision++;
    _bytes = Uint8List.fromList(utf8.encode(contents));
    _metadata = LocalBackupMetadata(
      path: 'backup.json',
      modifiedAt: backupFixtureNow.add(Duration(seconds: _revision)),
      byteLength: _bytes!.length,
    );
    return _metadata!;
  }

  void replaceBytesWithoutMetadata(String contents) {
    _bytes = Uint8List.fromList(utf8.encode(contents));
  }

  @override
  Future<LocalBackupMetadata?> metadata() async => _metadata;

  @override
  Future<Uint8List> readBytes() async {
    if (failRead) throw StateError('injected read failure');
    final bytes = _bytes;
    if (bytes == null) throw StateError('missing backup');
    return bytes;
  }
}

final class _MemoryProofStore implements MvpBUpgradeReadinessStore {
  MvpBUpgradeReadinessProof? proof;
  var failLoad = false;
  var failSave = false;
  var dropSave = false;

  @override
  Future<MvpBUpgradeReadinessProof?> load() async {
    if (failLoad) throw const FormatException('injected invalid proof');
    return proof;
  }

  @override
  Future<void> save(MvpBUpgradeReadinessProof proof) async {
    if (failSave) throw StateError('injected proof save failure');
    if (dropSave) return;
    this.proof = proof;
  }
}

final class _FixedClock implements Clock {
  const _FixedClock();

  @override
  DateTime now() => backupFixtureNow;
}

final class _FakePreparer implements OperationPreparer {
  final calls = <PreparationTrigger>[];

  @override
  Future<OperationPreparationResult> prepare(PreparationTrigger trigger) async {
    calls.add(trigger);
    return OperationPreparationResult(
      trigger: trigger,
      nowLocal: DateTime(2026, 8, 9, 12),
      nowUtc: backupFixtureNow,
      current: CurrentDayProjection(
        lifeDay: LifeDay(2026, 8, 9),
        baseEstimatedEnergy: 100,
        ruleVersion: 'energy-rules-v2-mvp-a',
        morningAdjustment: 0,
        shortTermAdjustment: 0,
        previousFinalEstimate: null,
        morningCheckInCompleted: false,
        projection: EstimatedDayProjection(
          initialEstimate: 100,
          currentEstimate: 100,
          band: EstimatedEnergyBand.estimatedNormal,
          activities: const [],
          totalConsumption: 0,
          totalRecovery: 0,
          categorySummaries: const {},
          effectiveDayKind: EffectiveDayKind.none,
        ),
      ),
      settledSummaries: const [],
      appliedPendingBaseEnergy: false,
      appliedPendingRuleVersion: false,
    );
  }
}
