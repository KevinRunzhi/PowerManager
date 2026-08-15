import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:test/test.dart';

import '../../generated_migrations/schema.dart';
import '../../support/backup_fixture.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('v3 without pending bridges one fixed active model', () async {
    final schema = await verifier.schemaAt(3);
    addTearDown(schema.rawDatabase.close);
    final old = GeneratedHelper().databaseForVersion(schema.newConnection(), 3);
    await _insertV3Fixture(old);
    await old.close();

    final database = AppDatabase.forExecutor(
      schema.newConnection(),
      clock: const _MigrationClock(),
    );
    addTearDown(database.close);
    await verifier.migrateAndValidate(
      database,
      4,
      options: const ValidationOptions(validateDropped: true),
    );

    final models = await database.customSelect('''
      SELECT * FROM personalization_versions ORDER BY created_at, id
    ''').get();
    expect(models, hasLength(1));
    final active = models.single;
    expect(active.read<String>('status'), 'active');
    expect(active.read<int>('base_energy'), 100);
    expect(active.read<int>('baseline_anchor_energy'), 100);
    expect(
      active.read<String>('effective_model_fingerprint'),
      fixedMvpAEffectiveModelFingerprint,
    );
    expect(
      active.read<String>('model_regime_epoch'),
      fixedMvpAInitialModelRegimeEpoch,
    );
    expect(active.read<String>('creation_source'), 'initial');

    final settings = await database
        .customSelect('SELECT * FROM app_settings')
        .getSingle();
    expect(settings.read<String>('baseline_learning_mode'), 'off');
    expect(settings.read<String>('activity_impact_learning_mode'), 'off');
    expect(settings.read<bool>('baseline_learning_suspended'), isFalse);
    expect(settings.read<bool>('activity_impact_learning_suspended'), isFalse);
    expect(
      settings.readNullable<DateTime>('baseline_learning_cooldown_until'),
      isNull,
    );
    expect(
      settings.readNullable<DateTime>(
        'activity_impact_learning_cooldown_until',
      ),
      isNull,
    );
    final columns = await database
        .customSelect('PRAGMA table_info(app_settings)')
        .get();
    final names = columns.map((row) => row.read<String>('name')).toSet();
    expect(names, isNot(contains('base_energy')));
    expect(names, isNot(contains('pending_base_energy')));
    expect(names, isNot(contains('base_energy_effective_life_day')));
  });

  for (final fixture in const [
    ('future', '2026-08-20'),
    ('due', '2026-08-10'),
  ]) {
    test('v3 ${fixture.$1} pending remains a legacy schedule', () async {
      final schema = await verifier.schemaAt(3);
      addTearDown(schema.rawDatabase.close);
      final old = GeneratedHelper().databaseForVersion(
        schema.newConnection(),
        3,
      );
      await _insertV3Fixture(old, pendingBase: 112, pendingBaseDay: fixture.$2);
      await old.close();

      final database = AppDatabase.forExecutor(
        schema.newConnection(),
        clock: const _MigrationClock(),
      );
      addTearDown(database.close);
      final rows = await database.customSelect('''
        SELECT * FROM personalization_versions ORDER BY created_at, id
      ''').get();
      expect(rows, hasLength(2));
      final scheduled = rows.singleWhere(
        (row) => row.read<String>('status') == 'scheduled',
      );
      expect(scheduled.read<int>('base_energy'), 112);
      expect(scheduled.read<int>('baseline_anchor_energy'), 112);
      expect(scheduled.read<String>('creation_source'), 'legacyManualPending');
      expect(scheduled.read<String>('schedule_source'), 'legacyManualPending');
      expect(scheduled.read<String>('effective_life_day'), fixture.$2);
      expect(scheduled.readNullable<String>('source_learning_run_id'), isNull);
    });
  }

  for (final malformed in const [(112, null), (null, '2026-08-20')]) {
    test('v3 malformed pending pair rolls the migration back', () async {
      final schema = await verifier.schemaAt(3);
      addTearDown(schema.rawDatabase.close);
      final old = GeneratedHelper().databaseForVersion(
        schema.newConnection(),
        3,
      );
      await old.customStatement('PRAGMA ignore_check_constraints = ON');
      await _insertV3Fixture(
        old,
        pendingBase: malformed.$1,
        pendingBaseDay: malformed.$2,
      );
      await old.customStatement('PRAGMA ignore_check_constraints = OFF');
      await old.close();

      await _expectV3MigrationRejected(schema.newConnection());
      expect(
        schema.rawDatabase.select('PRAGMA user_version').single['user_version'],
        3,
      );
      expect(
        schema.rawDatabase
            .select('SELECT pending_base_energy FROM app_settings')
            .single['pending_base_energy'],
        malformed.$1,
      );
    });
  }

  for (final pendingRule in const [
    (energyRulesV2MvpAVersion, null),
    (null, '2026-08-20'),
    (energyRulesV2MvpAVersion, '2026-08-20'),
  ]) {
    test('v3 unresolved pending rule is rejected before replacement', () async {
      final schema = await verifier.schemaAt(3);
      addTearDown(schema.rawDatabase.close);
      final old = GeneratedHelper().databaseForVersion(
        schema.newConnection(),
        3,
      );
      await old.customStatement('PRAGMA ignore_check_constraints = ON');
      await _insertV3Fixture(
        old,
        pendingRule: pendingRule.$1,
        pendingRuleDay: pendingRule.$2,
      );
      await old.customStatement('PRAGMA ignore_check_constraints = OFF');
      await old.close();

      await _expectV3MigrationRejected(schema.newConnection());
      expect(
        schema.rawDatabase.select('PRAGMA user_version').single['user_version'],
        3,
      );
      expect(
        schema.rawDatabase.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'personalization_versions'",
        ),
        isEmpty,
      );
    });
  }

  test(
    'v3 learning runs and summary legacy columns survive byte-for-byte',
    () async {
      final schema = await verifier.schemaAt(3);
      addTearDown(schema.rawDatabase.close);
      final old = GeneratedHelper().databaseForVersion(
        schema.newConnection(),
        3,
      );
      await _insertV3Fixture(old, includeLearningRunAndSummary: true);
      final beforeRuns = await _snapshotRows(old, 'learning_runs', 'id');
      final beforeSummaries = await _snapshotRows(
        old,
        'daily_summaries',
        'life_day',
        columns: _legacySummaryColumns,
      );
      await old.close();

      final database = AppDatabase.forExecutor(
        schema.newConnection(),
        clock: const _MigrationClock(),
      );
      addTearDown(database.close);
      expect(await _snapshotRows(database, 'learning_runs', 'id'), beforeRuns);
      expect(
        await _snapshotRows(
          database,
          'daily_summaries',
          'life_day',
          columns: _legacySummaryColumns,
        ),
        beforeSummaries,
      );
      final summary = await database
          .customSelect(
            'SELECT model_snapshot_source, personalization_version_id '
            'FROM daily_summaries',
          )
          .getSingle();
      expect(summary.read<String>('model_snapshot_source'), 'legacyInline');
      expect(
        summary.readNullable<String>('personalization_version_id'),
        isNull,
      );
    },
  );

  for (final checkpoint in const [
    'v4-before-preflight',
    'v4-after-preflight',
    'v4-after-extras-dropped',
    'v4-after-tables-renamed',
    'v4-after-tables-created',
    'v4-after-learning-runs-copied',
    'v4-after-models-bridged',
    'v4-after-settings-copied',
    'v4-after-summaries-copied',
    'v4-after-backups-dropped',
    'v4-before-verify',
  ]) {
    test('failure at $checkpoint rolls all v4 migration work back', () async {
      final schema = await verifier.schemaAt(3);
      addTearDown(schema.rawDatabase.close);
      final old = GeneratedHelper().databaseForVersion(
        schema.newConnection(),
        3,
      );
      await _insertV3Fixture(old, includeLearningRunAndSummary: true);
      final before = await _snapshotV3BridgeTables(old);
      await old.close();

      var failures = 0;
      final database = AppDatabase.forExecutor(
        schema.newConnection(),
        clock: const _MigrationClock(),
        migrationFailureHook: (current) async {
          if (current == checkpoint) {
            failures++;
            throw StateError('injected at $checkpoint');
          }
        },
      );
      await expectLater(
        database.customSelect('SELECT 1').get(),
        throwsA(isA<StateError>()),
      );
      await database.close();

      expect(failures, 1);
      expect(
        schema.rawDatabase.select('PRAGMA user_version').single['user_version'],
        3,
      );
      final retry = GeneratedHelper().databaseForVersion(
        schema.newConnection(),
        3,
      );
      expect(await _snapshotV3BridgeTables(retry), before);
      await retry.close();
      expect(
        schema.rawDatabase.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name LIKE '%_v3_backup'",
        ),
        isEmpty,
      );

      final successfulRetry = AppDatabase.forExecutor(
        schema.newConnection(),
        clock: const _MigrationClock(),
      );
      addTearDown(successfulRetry.close);
      expect(await _userVersion(successfulRetry), 4);
    });
  }

  test('successful v3 bridge is not repeated after restart', () async {
    final schema = await verifier.schemaAt(3);
    addTearDown(schema.rawDatabase.close);
    final old = GeneratedHelper().databaseForVersion(schema.newConnection(), 3);
    await _insertV3Fixture(old, pendingBase: 108, pendingBaseDay: '2026-08-20');
    await old.close();

    final first = AppDatabase.forExecutor(
      schema.newConnection(),
      clock: const _MigrationClock(),
    );
    expect(await _count(first, 'personalization_versions'), 2);
    await first.close();

    var migrationCalls = 0;
    final reopened = AppDatabase.forExecutor(
      schema.newConnection(),
      clock: const _MigrationClock(),
      migrationFailureHook: (_) async => migrationCalls++,
    );
    addTearDown(reopened.close);
    expect(await _count(reopened, 'personalization_versions'), 2);
    expect(migrationCalls, 0);
  });
}

Future<void> _expectV3MigrationRejected(QueryExecutor executor) async {
  final database = AppDatabase.forExecutor(
    executor,
    clock: const _MigrationClock(),
  );
  await expectLater(
    database.customSelect('SELECT 1').get(),
    throwsA(isA<StateError>()),
  );
  await database.close();
}

Future<void> _insertV3Fixture(
  GeneratedDatabase database, {
  int? pendingBase,
  String? pendingBaseDay,
  String? pendingRule,
  String? pendingRuleDay,
  bool includeLearningRunAndSummary = false,
}) async {
  final backup = backupFixtureV3();
  final rule = backup.ruleVersions.single;
  int seconds(DateTime value) =>
      value.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
  await database.customStatement(
    'INSERT INTO rule_config_versions (version, values_json, created_at) '
    'VALUES (?, ?, ?)',
    [rule.version, jsonEncode(rule.values), seconds(rule.createdAt)],
  );
  await database.customStatement(
    '''
    INSERT INTO app_settings (
      id, base_energy, pending_base_energy, base_energy_effective_life_day,
      active_rule_version, pending_rule_version,
      pending_rule_effective_life_day, onboarding_completed,
      created_at, updated_at
    ) VALUES (1, 100, ?, ?, ?, ?, ?, 1, ?, ?)
    ''',
    [
      pendingBase,
      pendingBaseDay,
      rule.version,
      pendingRule,
      pendingRuleDay,
      seconds(DateTime.utc(2026, 8, 1, 4)),
      seconds(DateTime.utc(2026, 8, 2, 4)),
    ],
  );
  if (!includeLearningRunAndSummary) return;

  final run = backup.learningRuns.single;
  await database.customStatement(
    '''
    INSERT INTO learning_runs (
      id, parameter_family, source_model_identity,
      source_personalization_version_id, status, result,
      evidence_snapshot_json, evidence_hash, evidence_hash_version,
      algorithm_version, config_version, current_values_json,
      candidate_values_json, reason_codes_json, triggered_at, completed_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      run.id,
      run.parameterFamily.code,
      run.sourceModelIdentity,
      run.sourcePersonalizationVersionId,
      run.status.code,
      run.result?.code,
      run.evidenceSnapshotJson,
      run.evidenceHash,
      run.evidenceHashVersion,
      run.algorithmVersion,
      run.configVersion,
      run.currentValuesJson,
      run.candidateValuesJson,
      run.reasonCodesJson,
      seconds(run.triggeredAt),
      run.completedAt == null ? null : seconds(run.completedAt!),
    ],
  );
  await database.customStatement(
    '''
    INSERT INTO daily_summaries (
      life_day, base_energy, rule_version, morning_adjustment,
      short_term_adjustment, initial_estimated_energy,
      final_estimated_energy, total_consumption, total_recovery,
      category_summary_json, is_standard_effective_day,
      is_weak_effective_day, settled_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      '2026-08-08',
      100,
      rule.version,
      6,
      -1,
      105,
      93,
      18,
      6,
      jsonEncode({
        'study': {'durationMinutes': 30, 'netDelta': -8, 'grossDelta': 8},
        'practice': {'durationMinutes': 15, 'netDelta': -10, 'grossDelta': 10},
        'recovery': {'durationMinutes': 15, 'netDelta': 6, 'grossDelta': 6},
        'leisure': {'durationMinutes': 0, 'netDelta': 0, 'grossDelta': 0},
      }),
      1,
      0,
      seconds(DateTime.utc(2026, 8, 9, 4)),
    ],
  );
}

Future<Map<String, List<Map<String, Object?>>>> _snapshotV3BridgeTables(
  GeneratedDatabase database,
) async {
  return {
    'app_settings': await _snapshotRows(database, 'app_settings', 'id'),
    'learning_runs': await _snapshotRows(database, 'learning_runs', 'id'),
    'daily_summaries': await _snapshotRows(
      database,
      'daily_summaries',
      'life_day',
    ),
  };
}

Future<List<Map<String, Object?>>> _snapshotRows(
  GeneratedDatabase database,
  String table,
  String orderBy, {
  String columns = '*',
}) async {
  final rows = await database
      .customSelect('SELECT $columns FROM $table ORDER BY $orderBy')
      .get();
  return [for (final row in rows) Map<String, Object?>.from(row.data)];
}

Future<int> _count(GeneratedDatabase database, String table) async {
  final row = await database
      .customSelect('SELECT COUNT(*) AS row_count FROM $table')
      .getSingle();
  return row.read<int>('row_count');
}

Future<int> _userVersion(GeneratedDatabase database) async {
  final row = await database.customSelect('PRAGMA user_version').getSingle();
  return row.read<int>('user_version');
}

const _legacySummaryColumns = '''
  life_day, base_energy, rule_version, morning_adjustment,
  short_term_adjustment, initial_estimated_energy,
  final_estimated_energy, total_consumption, total_recovery,
  category_summary_json, is_standard_effective_day,
  is_weak_effective_day, settled_at
''';

final class _MigrationClock implements Clock {
  const _MigrationClock();

  @override
  DateTime now() => DateTime.utc(2026, 8, 15, 12);
}
