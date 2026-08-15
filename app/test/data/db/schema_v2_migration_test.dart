import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:test/test.dart';

import '../../generated_migrations/schema.dart';
import '../../support/backup_fixture.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('empty real schema v1 migrates to the exact schema v2', () async {
    final connection = await verifier.startAt(1);
    final database = AppDatabase.forExecutor(
      connection,
      clock: const _FixedClock(),
    );
    addTearDown(database.close);

    await verifier.migrateAndValidate(
      database,
      2,
      options: const ValidationOptions(validateDropped: true),
    );

    expect(await _userVersion(database), 2);
    expect(await _count(database, 'activity_feedback'), 0);
  });

  test(
    'full v1 fixture preserves all seven legacy tables byte-for-byte',
    () async {
      final schema = await verifier.schemaAt(1);
      addTearDown(schema.rawDatabase.close);
      final oldDatabase = GeneratedHelper().databaseForVersion(
        schema.newConnection(),
        1,
      );
      await _insertFullV1Fixture(oldDatabase);
      final before = await _snapshotV1BusinessRows(oldDatabase);
      await oldDatabase.close();

      final database = AppDatabase.forExecutor(
        schema.newConnection(),
        clock: const _FixedClock(),
      );
      addTearDown(database.close);
      await verifier.migrateAndValidate(
        database,
        2,
        options: const ValidationOptions(validateDropped: true),
      );

      final after = await _snapshotV1BusinessRows(database);
      expect(after, before);
      expect(await _count(database, 'activity_feedback'), 0);
      final legacyColumns = await database.customSelect('''
      SELECT
        contract_version,
        reference_type,
        initial_estimate_at_observation,
        estimated_ordinal_at_observation,
        base_energy_at_observation,
        rule_version_at_observation,
        comparison_band_version,
        personalization_version_at_observation,
        effective_model_fingerprint_at_observation,
        model_regime_epoch_at_observation,
        active_activity_count_at_observation,
        coverage_state,
        model_regime_key
      FROM energy_observations
    ''').get();
      expect(
        legacyColumns.every(
          (row) => row.data.values.every((value) => value == null),
        ),
        isTrue,
      );
      await expectLater(
        database.customStatement(
          'UPDATE daily_summaries SET final_estimated_energy = 1',
        ),
        throwsA(anything),
      );
      await expectLater(
        database.customStatement(
          'UPDATE rule_config_versions SET values_json = ?',
          ['{"changed":true}'],
        ),
        throwsA(anything),
      );
    },
  );

  for (final checkpoint in const [
    'after-extras-dropped',
    'during-observation-copy',
    'before-protection-triggers',
  ]) {
    test(
      'failure at $checkpoint rolls the complete database back to v1',
      () async {
        final schema = await verifier.schemaAt(1);
        addTearDown(schema.rawDatabase.close);
        final oldDatabase = GeneratedHelper().databaseForVersion(
          schema.newConnection(),
          1,
        );
        await _insertMinimumV1Fixture(oldDatabase);
        await oldDatabase.close();

        var hookCalls = 0;
        final failing = AppDatabase.forExecutor(
          schema.newConnection(),
          clock: const _FixedClock(),
          migrationFailureHook: (current) async {
            if (current == checkpoint) {
              hookCalls++;
              throw StateError('injected at $checkpoint');
            }
          },
        );
        await expectLater(
          failing.customSelect('SELECT 1').get(),
          throwsA(isA<StateError>()),
        );
        await failing.close();

        expect(hookCalls, 1);
        expect(
          schema.rawDatabase
              .select('PRAGMA user_version')
              .single['user_version'],
          1,
        );
        expect(
          schema.rawDatabase
              .select("PRAGMA table_info('energy_observations')")
              .length,
          7,
        );
        expect(
          schema.rawDatabase.select(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'activity_feedback'",
          ),
          isEmpty,
        );
        expect(
          schema.rawDatabase.select(
            "SELECT name FROM sqlite_master WHERE type = 'trigger' "
            "AND name = 'referenced_rule_versions_reject_update'",
          ),
          hasLength(1),
        );
        expect(
          schema.rawDatabase
              .select('SELECT id FROM energy_observations')
              .single['id'],
          'legacy-minimum',
        );

        final retry = AppDatabase.forExecutor(
          schema.newConnection(),
          clock: const _FixedClock(),
        );
        addTearDown(retry.close);
        await verifier.migrateAndValidate(
          retry,
          2,
          options: const ValidationOptions(validateDropped: true),
        );
        expect(await _userVersion(retry), 2);
      },
    );
  }

  test('successful migration runs once across a restart', () async {
    final schema = await verifier.schemaAt(1);
    addTearDown(schema.rawDatabase.close);
    final oldDatabase = GeneratedHelper().databaseForVersion(
      schema.newConnection(),
      1,
    );
    await _insertMinimumV1Fixture(oldDatabase);
    await oldDatabase.close();

    final first = AppDatabase.forExecutor(
      schema.newConnection(),
      clock: const _FixedClock(),
    );
    await verifier.migrateAndValidate(first, 2);
    await first.close();

    var migrationHookCalls = 0;
    final reopened = AppDatabase.forExecutor(
      schema.newConnection(),
      clock: const _FixedClock(),
      migrationFailureHook: (_) async => migrationHookCalls++,
    );
    addTearDown(reopened.close);
    expect(await _userVersion(reopened), 2);
    expect(await _count(reopened, 'energy_observations'), 1);
    expect(migrationHookCalls, 0);
  });
}

Future<void> _insertMinimumV1Fixture(GeneratedDatabase database) async {
  final rule = backupFixture().ruleVersions.single;
  final timestamp = backupFixtureNow.millisecondsSinceEpoch ~/ 1000;
  await database.customStatement(
    'INSERT INTO rule_config_versions (version, values_json, created_at) '
    'VALUES (?, ?, ?)',
    [rule.version, jsonEncode(rule.values), timestamp],
  );
  await database.customStatement(
    '''
    INSERT INTO app_settings (
      id, base_energy, pending_base_energy, base_energy_effective_life_day,
      active_rule_version, pending_rule_version,
      pending_rule_effective_life_day, onboarding_completed,
      created_at, updated_at
    ) VALUES (1, 100, NULL, NULL, ?, NULL, NULL, 1, ?, ?)
  ''',
    [rule.version, timestamp, timestamp],
  );
  await database.customStatement(
    '''
    INSERT INTO energy_observations (
      id, life_day, type, absolute_state, relative_state,
      estimate_at_observation, observed_at
    ) VALUES ('legacy-minimum', '2026-08-08', 'dailyAbsolute', 'okay', NULL, 88, ?)
  ''',
    [timestamp],
  );
}

Future<void> _insertFullV1Fixture(GeneratedDatabase database) async {
  await _insertMinimumV1Fixture(database);
  final timestamp = backupFixtureNow.millisecondsSinceEpoch ~/ 1000;
  final later = timestamp + 60;
  await database.customStatement(
    '''
    UPDATE app_settings SET
      base_energy = 112,
      pending_base_energy = 108,
      base_energy_effective_life_day = '2026-08-10',
      pending_rule_version = ?,
      pending_rule_effective_life_day = '2026-08-11'
    WHERE id = 1
  ''',
    [energyRulesV2MvpAVersion],
  );
  await database.customStatement(
    '''
    INSERT INTO morning_check_ins (
      id, life_day, overall_state, free_time_level, pressure_source,
      sleep_recovery, morning_adjustment, completed_at
    ) VALUES ('morning-v1', '2026-08-08', 'good', 'medium', 'study', 'normal', 6, ?)
  ''',
    [timestamp],
  );
  await database.customStatement(
    '''
    INSERT INTO activity_records (
      id, life_day, completed_at, created_at, updated_at, category,
      subcategory, duration_minutes, theoretical_delta, applied_delta,
      rule_version, status, deleted_at
    ) VALUES
      ('active-v1', '2026-08-08', ?, ?, ?, 'study', 'homework', 30, -8, -8, ?, 'active', NULL),
      ('deleted-v1', '2026-08-08', ?, ?, ?, 'recovery', 'nap', 30, 12, 10, ?, 'deleted', ?)
  ''',
    [
      timestamp,
      timestamp,
      timestamp,
      energyRulesV2MvpAVersion,
      timestamp,
      timestamp,
      later,
      energyRulesV2MvpAVersion,
      later,
    ],
  );
  await database.customStatement(
    '''
    INSERT INTO energy_observations (
      id, life_day, type, absolute_state, relative_state,
      estimate_at_observation, observed_at
    ) VALUES ('legacy-correction', '2026-08-08', 'relativeCorrection', NULL, 'lower', 77, ?)
  ''',
    [later],
  );
  await database.customStatement(
    '''
    INSERT INTO daily_summaries (
      life_day, base_energy, rule_version, morning_adjustment,
      short_term_adjustment, initial_estimated_energy,
      final_estimated_energy, total_consumption, total_recovery,
      category_summary_json, is_standard_effective_day,
      is_weak_effective_day, settled_at
    ) VALUES ('2026-08-08', 112, ?, 6, 0, 118, 120, 8, 10, ?, 1, 0, ?)
  ''',
    [
      energyRulesV2MvpAVersion,
      jsonEncode({
        'study': {'durationMinutes': 30, 'netDelta': -8, 'grossDelta': 8},
        'practice': {'durationMinutes': 0, 'netDelta': 0, 'grossDelta': 0},
        'recovery': {'durationMinutes': 30, 'netDelta': 10, 'grossDelta': 10},
        'leisure': {'durationMinutes': 0, 'netDelta': 0, 'grossDelta': 0},
      }),
      later,
    ],
  );
  await database.customStatement(
    '''
    INSERT INTO prompt_receipts (id, type, scope_key, "action", occurred_at)
    VALUES ('receipt-v1', 'energyBand', '2026-08-08:estimatedLow', 'shown', ?)
  ''',
    [later],
  );
}

const _v1TableOrder = <String, String>{
  'rule_config_versions': 'version',
  'app_settings': 'id',
  'morning_check_ins': 'id',
  'activity_records': 'id',
  'energy_observations': 'id',
  'daily_summaries': 'life_day',
  'prompt_receipts': 'id',
};

const _v1ObservationColumns = '''
  id, life_day, type, absolute_state, relative_state,
  estimate_at_observation, observed_at
''';

Future<Map<String, List<Map<String, Object?>>>> _snapshotV1BusinessRows(
  GeneratedDatabase database,
) async {
  final snapshot = <String, List<Map<String, Object?>>>{};
  for (final entry in _v1TableOrder.entries) {
    final columns = entry.key == 'energy_observations'
        ? _v1ObservationColumns
        : '*';
    final rows = await database
        .customSelect(
          'SELECT $columns FROM ${entry.key} ORDER BY ${entry.value}',
        )
        .get();
    snapshot[entry.key] = [
      for (final row in rows) Map<String, Object?>.from(row.data),
    ];
  }
  return snapshot;
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

final class _FixedClock implements Clock {
  const _FixedClock();

  @override
  DateTime now() => backupFixtureNow;
}
