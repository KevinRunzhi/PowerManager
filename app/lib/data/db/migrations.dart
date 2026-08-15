part of 'app_database.dart';

typedef SchemaMigrationFailureHook = Future<void> Function(String checkpoint);

extension _SchemaMigrations on AppDatabase {
  Future<void> _upgradeSchema(Migrator migrator, int from, int to) async {
    if (from != 1 || to != 2) {
      throw StateError('Unsupported schema migration: $from -> $to');
    }

    await customStatement('PRAGMA foreign_keys = OFF');
    try {
      await transaction(() => _migrateV1ToV2(migrator));
    } finally {
      await customStatement('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _migrateV1ToV2(Migrator migrator) async {
    final sourceCount = await _tableRowCount('energy_observations');

    await _dropProtectionTriggers();
    await customStatement(
      'DROP INDEX IF EXISTS energy_observations_one_daily_absolute',
    );
    await customStatement(
      'DROP INDEX IF EXISTS energy_observations_life_day_time',
    );
    await migrationFailureHook?.call('after-extras-dropped');

    await customStatement('''
      ALTER TABLE energy_observations
      RENAME TO energy_observations_v1_backup
    ''');
    await migrationFailureHook?.call('after-observation-renamed');

    await migrator.createTable(energyObservationsTable);
    await customStatement('''
      INSERT INTO energy_observations (
        id,
        life_day,
        type,
        absolute_state,
        relative_state,
        estimate_at_observation,
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
        model_regime_key,
        observed_at
      )
      SELECT
        id,
        life_day,
        type,
        absolute_state,
        relative_state,
        estimate_at_observation,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        observed_at
      FROM energy_observations_v1_backup
    ''');
    await migrationFailureHook?.call('during-observation-copy');
    await _verifyObservationCopy(sourceCount);

    await customStatement('DROP TABLE energy_observations_v1_backup');
    await migrator.createTable(activityFeedbackTable);
    await _createV2IndexesAfterMigration();

    await migrationFailureHook?.call('before-protection-triggers');
    await _createProtectionTriggers();
    await _verifySchemaV2();
  }

  Future<void> _verifyObservationCopy(int sourceCount) async {
    if (await _tableRowCount('energy_observations') != sourceCount) {
      throw StateError('Observation row count changed during v1 -> v2');
    }
    final idDifferences = await customSelect('''
      SELECT id FROM energy_observations_v1_backup
      EXCEPT SELECT id FROM energy_observations
      UNION ALL
      SELECT id FROM energy_observations
      EXCEPT SELECT id FROM energy_observations_v1_backup
    ''').get();
    if (idDifferences.isNotEmpty) {
      throw StateError('Observation identifiers changed during v1 -> v2');
    }
  }

  Future<int> _tableRowCount(String tableName) async {
    final row = await customSelect(
      'SELECT COUNT(*) AS row_count FROM $tableName',
    ).getSingle();
    return row.read<int>('row_count');
  }

  Future<void> _createV2IndexesAfterMigration() async {
    await customStatement('''
      CREATE INDEX energy_observations_life_day_time
      ON energy_observations (life_day, observed_at, id)
    ''');
    await customStatement('''
      CREATE INDEX energy_observations_contract_lookup
      ON energy_observations (life_day, type, contract_version)
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX energy_observations_one_daily_absolute
      ON energy_observations (life_day)
      WHERE type = 'dailyAbsolute'
    ''');
    await customStatement('''
      CREATE INDEX activity_feedback_activity_order
      ON activity_feedback (activity_record_id, observed_at, id)
    ''');
    await customStatement('''
      CREATE INDEX activity_feedback_life_day_status
      ON activity_feedback (life_day, status, observed_at, id)
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX activity_feedback_one_active_per_activity
      ON activity_feedback (activity_record_id)
      WHERE status = 'active'
    ''');
  }

  Future<void> _verifySchemaV2() async {
    final foreignKeyIssues = await customSelect(
      'PRAGMA foreign_key_check',
    ).get();
    if (foreignKeyIssues.isNotEmpty) {
      throw StateError('Schema v2 migration violates foreign keys');
    }

    final integrity = await customSelect('PRAGMA integrity_check').get();
    if (integrity.length != 1 ||
        integrity.single.data.values.singleOrNull != 'ok') {
      throw StateError('Schema v2 migration failed integrity_check');
    }

    final schemaObjects = await customSelect('''
      SELECT name FROM sqlite_master
      WHERE type IN ('index', 'trigger')
    ''').get();
    final names = schemaObjects.map((row) => row.read<String>('name')).toSet();
    const required = <String>{
      'energy_observations_life_day_time',
      'energy_observations_contract_lookup',
      'energy_observations_one_daily_absolute',
      'activity_feedback_activity_order',
      'activity_feedback_life_day_status',
      'activity_feedback_one_active_per_activity',
      'daily_summaries_reject_update',
      'daily_summaries_reject_delete',
      'app_settings_reject_delete',
      'referenced_rule_versions_reject_update',
    };
    if (!names.containsAll(required)) {
      throw StateError('Schema v2 indexes or protection triggers are missing');
    }

    final forbiddenTables = await customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table'
        AND name IN ('learning_runs', 'personalization_versions')
    ''').get();
    if (forbiddenTables.isNotEmpty) {
      throw StateError('Schema v2 contains premature learning tables');
    }
  }
}
