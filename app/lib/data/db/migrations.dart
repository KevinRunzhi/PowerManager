part of 'app_database.dart';

typedef SchemaMigrationFailureHook = Future<void> Function(String checkpoint);

extension _SchemaMigrations on AppDatabase {
  Future<void> _upgradeSchema(Migrator migrator, int from, int to) async {
    if (from < 1 || to > 4 || from >= to) {
      throw StateError('Unsupported schema migration: $from -> $to');
    }

    await customStatement('PRAGMA foreign_keys = OFF');
    try {
      await transaction(() async {
        var current = from;
        if (current == 1 && to >= 2) {
          await _migrateV1ToV2(migrator);
          current = 2;
        }
        if (current == 2 && to >= 3) {
          await _migrateV2ToV3(migrator);
          current = 3;
        }
        if (current == 3 && to >= 4) {
          await _migrateV3ToV4(migrator);
          current = 4;
        }
        if (current != to) {
          throw StateError('Unsupported schema migration: $from -> $to');
        }
      });
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
    await _createProtectionTriggers(
      includeLearningRuns: false,
      includePersonalization: false,
    );
    await _verifySchemaV2();
  }

  Future<void> _migrateV2ToV3(Migrator migrator) async {
    await migrationFailureHook?.call('before-learning-runs-create');
    await migrator.createTable(learningRunsTable);
    await migrationFailureHook?.call('after-learning-runs-table');
    await _createV3IndexesAfterMigration();
    await migrationFailureHook?.call('after-learning-runs-indexes');
    await _createLearningRunProtectionTrigger();
    await migrationFailureHook?.call('before-v3-verify');
    await _verifySchemaV3();
  }

  Future<void> _migrateV3ToV4(Migrator migrator) async {
    await migrationFailureHook?.call('v4-before-preflight');
    final bridge = await _readAndValidateV3SettingsBridge();
    final learningRunCount = await _tableRowCount('learning_runs');
    final summaryCount = await _tableRowCount('daily_summaries');
    await _verifyForeignKeysAndIntegrity('schema v3 preflight');
    await migrationFailureHook?.call('v4-after-preflight');

    await _dropProtectionTriggers();
    for (final name in const [
      'learning_runs_idempotency',
      'learning_runs_source_time',
      'learning_runs_status_time',
    ]) {
      await customStatement('DROP INDEX IF EXISTS $name');
    }
    await migrationFailureHook?.call('v4-after-extras-dropped');

    await customStatement(
      'ALTER TABLE app_settings RENAME TO app_settings_v3_backup',
    );
    await customStatement(
      'ALTER TABLE learning_runs RENAME TO learning_runs_v3_backup',
    );
    await customStatement(
      'ALTER TABLE daily_summaries RENAME TO daily_summaries_v3_backup',
    );
    await migrationFailureHook?.call('v4-after-tables-renamed');

    await migrator.createTable(learningRunsTable);
    await migrator.createTable(personalizationVersionsTable);
    await migrator.createTable(appSettingsTable);
    await migrator.createTable(dailySummariesTable);
    await migrator.createTable(learningConsentsTable);
    await migrator.createTable(learningNoticesTable);
    await migrationFailureHook?.call('v4-after-tables-created');

    await customStatement('''
      INSERT INTO learning_runs (
        id,
        parameter_family,
        source_model_identity,
        source_personalization_version_id,
        status,
        result,
        evidence_snapshot_json,
        evidence_hash,
        evidence_hash_version,
        algorithm_version,
        config_version,
        current_values_json,
        candidate_values_json,
        reason_codes_json,
        triggered_at,
        completed_at
      )
      SELECT
        id,
        parameter_family,
        source_model_identity,
        source_personalization_version_id,
        status,
        result,
        evidence_snapshot_json,
        evidence_hash,
        evidence_hash_version,
        algorithm_version,
        config_version,
        current_values_json,
        candidate_values_json,
        reason_codes_json,
        triggered_at,
        completed_at
      FROM learning_runs_v3_backup
    ''');
    await migrationFailureHook?.call('v4-after-learning-runs-copied');
    await _verifyV3LearningRunCopy(learningRunCount);

    final initial = initialPersonalizationVersion(
      baseEnergy: bridge.baseEnergy,
      createdAt: bridge.createdAt,
    );
    await _insertMigratedPersonalizationVersion(initial);
    if (bridge.pendingBaseEnergy case final pending?) {
      final scheduled = scheduledManualPersonalizationVersion(
        parent: initial,
        baseEnergy: pending,
        effectiveLifeDay: bridge.pendingBaseEffectiveLifeDay!,
        createdAt: bridge.updatedAt,
        ruleVersion: bridge.activeRuleVersion,
        legacy: true,
      );
      await _insertMigratedPersonalizationVersion(scheduled);
    }
    await migrationFailureHook?.call('v4-after-models-bridged');

    await into(appSettingsTable).insert(
      AppSettingsTableCompanion.insert(
        id: const Value(1),
        activeRuleVersion: bridge.activeRuleVersion,
        pendingRuleVersion: const Value(null),
        pendingRuleEffectiveLifeDay: const Value(null),
        onboardingCompleted: Value(bridge.onboardingCompleted),
        baselineLearningMode: const Value(LearningMode.off),
        activityImpactLearningMode: const Value(LearningMode.off),
        baselineLearningSuspended: const Value(false),
        baselineLearningSuspendedAt: const Value(null),
        baselineLearningSuspensionReason: const Value(null),
        activityImpactLearningSuspended: const Value(false),
        activityImpactLearningSuspendedAt: const Value(null),
        activityImpactLearningSuspensionReason: const Value(null),
        baselineLearningCooldownUntil: const Value(null),
        activityImpactLearningCooldownUntil: const Value(null),
        createdAt: bridge.createdAt,
        updatedAt: bridge.updatedAt,
      ),
    );
    await migrationFailureHook?.call('v4-after-settings-copied');

    await customStatement('''
      INSERT INTO daily_summaries (
        life_day,
        base_energy,
        rule_version,
        morning_adjustment,
        short_term_adjustment,
        initial_estimated_energy,
        final_estimated_energy,
        total_consumption,
        total_recovery,
        category_summary_json,
        is_standard_effective_day,
        is_weak_effective_day,
        model_snapshot_source,
        personalization_version_id,
        settled_at
      )
      SELECT
        life_day,
        base_energy,
        rule_version,
        morning_adjustment,
        short_term_adjustment,
        initial_estimated_energy,
        final_estimated_energy,
        total_consumption,
        total_recovery,
        category_summary_json,
        is_standard_effective_day,
        is_weak_effective_day,
        'legacyInline',
        NULL,
        settled_at
      FROM daily_summaries_v3_backup
    ''');
    await migrationFailureHook?.call('v4-after-summaries-copied');
    await _verifyV3DailySummaryCopy(summaryCount);

    await customStatement('DROP TABLE app_settings_v3_backup');
    await customStatement('DROP TABLE learning_runs_v3_backup');
    await customStatement('DROP TABLE daily_summaries_v3_backup');
    await migrationFailureHook?.call('v4-after-backups-dropped');

    await _createV4IndexesAfterMigration();
    await _createProtectionTriggers();
    await migrationFailureHook?.call('v4-before-verify');
    await _verifySchemaV4(
      expectedLearningRuns: learningRunCount,
      expectedSummaries: summaryCount,
      expectedPendingVersions: bridge.pendingBaseEnergy == null ? 0 : 1,
    );
  }

  Future<_V3SettingsBridge> _readAndValidateV3SettingsBridge() async {
    if (await _tableRowCount('app_settings') != 1) {
      throw StateError('Schema v3 must contain exactly one settings row');
    }
    final row = await customSelect('''
      SELECT
        id,
        base_energy,
        pending_base_energy,
        base_energy_effective_life_day,
        active_rule_version,
        pending_rule_version,
        pending_rule_effective_life_day,
        onboarding_completed,
        created_at,
        updated_at
      FROM app_settings
    ''').getSingle();
    if (row.read<int>('id') != 1) {
      throw StateError('Schema v3 settings identifier is invalid');
    }
    final baseEnergy = row.read<int>('base_energy');
    final pendingBase = row.readNullable<int>('pending_base_energy');
    final effectiveRaw = row.readNullable<String>(
      'base_energy_effective_life_day',
    );
    if (baseEnergy < 60 ||
        baseEnergy > 140 ||
        (pendingBase != null && (pendingBase < 60 || pendingBase > 140)) ||
        ((pendingBase == null) != (effectiveRaw == null))) {
      throw StateError('Schema v3 baseline bridge is invalid');
    }
    final pendingRule = row.readNullable<String>('pending_rule_version');
    final pendingRuleDay = row.readNullable<String>(
      'pending_rule_effective_life_day',
    );
    if (pendingRule != null || pendingRuleDay != null) {
      throw StateError('Schema v3 has an unresolved pending rule');
    }
    final createdAt = row.read<DateTime>('created_at').toUtc();
    final updatedAt = row.read<DateTime>('updated_at').toUtc();
    if (createdAt.isAfter(updatedAt)) {
      throw StateError('Schema v3 settings timestamps are invalid');
    }
    return _V3SettingsBridge(
      baseEnergy: baseEnergy,
      pendingBaseEnergy: pendingBase,
      pendingBaseEffectiveLifeDay: effectiveRaw == null
          ? null
          : LifeDay.parse(effectiveRaw),
      activeRuleVersion: row.read<String>('active_rule_version'),
      onboardingCompleted: row.read<bool>('onboarding_completed'),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Future<void> _insertMigratedPersonalizationVersion(
    PersonalizationVersion version,
  ) async {
    await into(personalizationVersionsTable).insert(
      PersonalizationVersionsTableCompanion.insert(
        id: version.id,
        parentVersionId: Value(version.parentVersionId),
        effectiveModelFingerprint: version.effectiveModelFingerprint,
        modelRegimeEpoch: version.modelRegimeEpoch,
        creationSource: version.creationSource,
        scheduleSource: Value(version.scheduleSource),
        sourceLearningRunId: Value(version.sourceLearningRunId),
        algorithmVersion: version.algorithmVersion,
        configVersion: version.configVersion,
        changedParameterFamily: version.changedParameterFamily,
        baseEnergy: version.baseEnergy,
        baselineAnchorEnergy: version.baselineAnchorEnergy,
        status: version.status,
        effectiveLifeDay: Value(version.effectiveLifeDay),
        createdAt: version.createdAt,
        activatedAt: Value(version.activatedAt),
        endedAt: Value(version.endedAt),
        transitionReason: version.transitionReason,
      ),
    );
  }

  Future<void> _verifyV3LearningRunCopy(int expectedCount) async {
    if (await _tableRowCount('learning_runs') != expectedCount) {
      throw StateError('Learning run row count changed during v3 -> v4');
    }
    final differences = await customSelect('''
      SELECT * FROM learning_runs_v3_backup
      EXCEPT SELECT * FROM learning_runs
      UNION ALL
      SELECT * FROM learning_runs
      EXCEPT SELECT * FROM learning_runs_v3_backup
    ''').get();
    if (differences.isNotEmpty) {
      throw StateError('Learning runs changed during v3 -> v4');
    }
  }

  Future<void> _verifyV3DailySummaryCopy(int expectedCount) async {
    if (await _tableRowCount('daily_summaries') != expectedCount) {
      throw StateError('Daily summary row count changed during v3 -> v4');
    }
    const legacyColumns = '''
      life_day,
      base_energy,
      rule_version,
      morning_adjustment,
      short_term_adjustment,
      initial_estimated_energy,
      final_estimated_energy,
      total_consumption,
      total_recovery,
      category_summary_json,
      is_standard_effective_day,
      is_weak_effective_day,
      settled_at
    ''';
    final differences = await customSelect('''
      SELECT $legacyColumns FROM daily_summaries_v3_backup
      EXCEPT SELECT $legacyColumns FROM daily_summaries
      UNION ALL
      SELECT $legacyColumns FROM daily_summaries
      EXCEPT SELECT $legacyColumns FROM daily_summaries_v3_backup
    ''').get();
    if (differences.isNotEmpty) {
      throw StateError('Daily summaries changed during v3 -> v4');
    }
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

  Future<void> _createV3IndexesAfterMigration() async {
    await customStatement('''
      CREATE UNIQUE INDEX learning_runs_idempotency
      ON learning_runs (
        parameter_family,
        source_model_identity,
        algorithm_version,
        config_version,
        evidence_hash
      )
    ''');
    await customStatement('''
      CREATE INDEX learning_runs_source_time
      ON learning_runs (
        parameter_family,
        source_model_identity,
        triggered_at,
        id
      )
    ''');
    await customStatement('''
      CREATE INDEX learning_runs_status_time
      ON learning_runs (status, triggered_at, id)
    ''');
  }

  Future<void> _createV4IndexesAfterMigration() async {
    await _createV3IndexesAfterMigration();
    await customStatement('''
      CREATE INDEX personalization_versions_parent
      ON personalization_versions (parent_version_id)
    ''');
    await customStatement('''
      CREATE INDEX personalization_versions_status_time
      ON personalization_versions (status, created_at, id)
    ''');
    await customStatement('''
      CREATE INDEX learning_notices_status_time
      ON learning_notices (status, created_at, id)
    ''');
    await _createV4PersonalizationIndexes();
  }

  Future<void> _verifyForeignKeysAndIntegrity(String description) async {
    final foreignKeyIssues = await customSelect(
      'PRAGMA foreign_key_check',
    ).get();
    if (foreignKeyIssues.isNotEmpty) {
      throw StateError('$description violates foreign keys');
    }
    final integrity = await customSelect('PRAGMA integrity_check').get();
    if (integrity.length != 1 ||
        integrity.single.data.values.singleOrNull != 'ok') {
      throw StateError('$description failed integrity_check');
    }
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

  Future<void> _verifySchemaV3() async {
    final foreignKeyIssues = await customSelect(
      'PRAGMA foreign_key_check',
    ).get();
    if (foreignKeyIssues.isNotEmpty) {
      throw StateError('Schema v3 migration violates foreign keys');
    }

    final integrity = await customSelect('PRAGMA integrity_check').get();
    if (integrity.length != 1 ||
        integrity.single.data.values.singleOrNull != 'ok') {
      throw StateError('Schema v3 migration failed integrity_check');
    }

    final schemaObjects = await customSelect('''
      SELECT name FROM sqlite_master
      WHERE type IN ('table', 'index', 'trigger')
    ''').get();
    final names = schemaObjects.map((row) => row.read<String>('name')).toSet();
    const required = <String>{
      'learning_runs',
      'learning_runs_idempotency',
      'learning_runs_source_time',
      'learning_runs_status_time',
      'learning_runs_reject_final_update',
    };
    if (!names.containsAll(required)) {
      throw StateError('Schema v3 learning run objects are missing');
    }

    if (await _tableRowCount('learning_runs') != 0) {
      throw StateError('Schema v3 migration fabricated learning runs');
    }
    final forbiddenTables = await customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name = 'personalization_versions'
    ''').get();
    if (forbiddenTables.isNotEmpty) {
      throw StateError('Schema v3 contains premature model tables');
    }
  }

  Future<void> _verifySchemaV4({
    required int expectedLearningRuns,
    required int expectedSummaries,
    required int expectedPendingVersions,
  }) async {
    await _verifyForeignKeysAndIntegrity('Schema v4 migration');
    final schemaObjects = await customSelect('''
      SELECT name FROM sqlite_master
      WHERE type IN ('table', 'index', 'trigger')
    ''').get();
    final names = schemaObjects.map((row) => row.read<String>('name')).toSet();
    const required = <String>{
      'personalization_versions',
      'learning_consents',
      'learning_notices',
      'personalization_versions_one_active',
      'personalization_versions_one_pending',
      'personalization_versions_parent',
      'personalization_versions_status_time',
      'learning_notices_status_time',
      'personalization_versions_reject_delete',
      'personalization_versions_reject_identity_update',
      'personalization_versions_reject_terminal_update',
      'learning_consents_reject_update',
      'learning_consents_reject_delete',
      'learning_notices_reject_identity_update',
      'learning_runs_reject_final_update',
      'daily_summaries_reject_update',
      'daily_summaries_reject_delete',
      'app_settings_reject_delete',
    };
    if (!names.containsAll(required)) {
      throw StateError('Schema v4 indexes or protection triggers are missing');
    }
    if (await _tableRowCount('learning_runs') != expectedLearningRuns ||
        await _tableRowCount('daily_summaries') != expectedSummaries) {
      throw StateError('Schema v4 preserved row counts do not match');
    }
    final activeCount = await customSelect('''
      SELECT COUNT(*) AS row_count
      FROM personalization_versions
      WHERE status = 'active'
    ''').getSingle();
    if (activeCount.read<int>('row_count') != 1) {
      throw StateError('Schema v4 must contain exactly one active model');
    }
    final pendingCount = await customSelect('''
      SELECT COUNT(*) AS row_count
      FROM personalization_versions
      WHERE status IN ('candidate', 'awaitingReview', 'deferred', 'scheduled')
    ''').getSingle();
    if (pendingCount.read<int>('row_count') != expectedPendingVersions) {
      throw StateError('Schema v4 pending model count is invalid');
    }
    final legacySummaryCount = await customSelect('''
      SELECT COUNT(*) AS row_count
      FROM daily_summaries
      WHERE model_snapshot_source = 'legacyInline'
        AND personalization_version_id IS NULL
    ''').getSingle();
    if (legacySummaryCount.read<int>('row_count') != expectedSummaries) {
      throw StateError('Schema v4 legacy summary bridge is invalid');
    }
    final settingsColumns = await customSelect(
      'PRAGMA table_info(app_settings)',
    ).get();
    final columnNames = settingsColumns
        .map((row) => row.read<String>('name'))
        .toSet();
    if (columnNames.contains('base_energy') ||
        columnNames.contains('pending_base_energy') ||
        columnNames.contains('base_energy_effective_life_day')) {
      throw StateError('Schema v4 settings still contain a base truth');
    }
    final forbiddenBackups = await customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table'
        AND name IN (
          'app_settings_v3_backup',
          'learning_runs_v3_backup',
          'daily_summaries_v3_backup'
        )
    ''').get();
    if (forbiddenBackups.isNotEmpty) {
      throw StateError('Schema v4 temporary migration tables remain');
    }
  }
}

final class _V3SettingsBridge {
  const _V3SettingsBridge({
    required this.baseEnergy,
    required this.pendingBaseEnergy,
    required this.pendingBaseEffectiveLifeDay,
    required this.activeRuleVersion,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final int baseEnergy;
  final int? pendingBaseEnergy;
  final LifeDay? pendingBaseEffectiveLifeDay;
  final String activeRuleVersion;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
}
