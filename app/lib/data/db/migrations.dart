part of 'app_database.dart';

typedef SchemaMigrationFailureHook = Future<void> Function(String checkpoint);

extension _SchemaMigrations on AppDatabase {
  Future<void> _upgradeSchema(Migrator migrator, int from, int to) async {
    if (from < 1 || to > 5 || from >= to) {
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
        if (current == 4 && to >= 5) {
          await _migrateV4ToV5(migrator);
          current = 5;
        }
        if (current != to) {
          throw StateError('Unsupported schema migration: $from -> $to');
        }
      });
    } finally {
      await customStatement('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _migrateV4ToV5(Migrator migrator) async {
    final activityCount = await _tableRowCount('activity_records');
    final feedbackCount = await _tableRowCount('activity_feedback');
    await _verifyForeignKeysAndIntegrity('schema v4 preflight');
    await migrationFailureHook?.call('v5-before-preflight');

    await _dropProtectionTriggers();
    await customStatement(
      'DROP INDEX IF EXISTS activity_feedback_one_active_per_activity',
    );
    await migrationFailureHook?.call('v5-after-extras-dropped');

    await customStatement(
      'ALTER TABLE activity_feedback RENAME TO activity_feedback_v4_backup',
    );
    await migrationFailureHook?.call('v5-after-feedback-renamed');

    await customStatement(
      'ALTER TABLE activity_records RENAME TO activity_records_v4_backup',
    );
    await migrator.createTable(activityRecordsTable);
    await customStatement('''
      INSERT INTO activity_records (
        id, life_day, completed_at, created_at, updated_at, category,
        subcategory, duration_minutes, theoretical_delta, applied_delta,
        default_theoretical_delta, activity_factor, personalized_theoretical_delta,
        personalization_version_id, factor_regime_started_life_day,
        rule_version, status, deleted_at
      )
      SELECT
        id, life_day, completed_at, created_at, updated_at, category,
        subcategory, duration_minutes, theoretical_delta, applied_delta,
        theoretical_delta, 1.0, theoretical_delta, NULL, NULL,
        rule_version, status, deleted_at
      FROM activity_records_v4_backup
    ''');
    await customStatement('DROP TABLE activity_records_v4_backup');
    await migrationFailureHook?.call('v5-after-activity-columns');

    await migrator.createTable(activityFeedbackTable);
    await migrator.createTable(personalizationActivityFactorsTable);
    await migrator.createTable(activityFeedbackSamplesTable);
    await migrationFailureHook?.call('v5-after-tables-created');

    await customStatement('''
      INSERT INTO activity_feedback (
        id,
        activity_record_id,
        life_day,
        subcategory_snapshot,
        duration_minutes_snapshot,
        theoretical_delta_snapshot,
        applied_delta_snapshot,
        default_theoretical_delta_snapshot,
        factor_snapshot,
        personalized_theoretical_delta_snapshot,
        personalization_version_id,
        factor_regime_started_life_day,
        impact_sign_snapshot,
        rule_version_snapshot,
        activity_updated_at_snapshot,
        direction,
        collection_source,
        sampling_policy_version,
        sampled_at,
        sample_id,
        status,
        invalidation_reason,
        observed_at
      )
      SELECT
        id,
        activity_record_id,
        life_day,
        subcategory_snapshot,
        duration_minutes_snapshot,
        theoretical_delta_snapshot,
        applied_delta_snapshot,
        theoretical_delta_snapshot,
        1.0,
        theoretical_delta_snapshot,
        NULL,
        NULL,
        impact_sign_snapshot,
        rule_version_snapshot,
        activity_updated_at_snapshot,
        direction,
        'userInitiated',
        NULL,
        NULL,
        NULL,
        status,
        invalidation_reason,
        observed_at
      FROM activity_feedback_v4_backup
    ''');
    await migrationFailureHook?.call('v5-after-feedback-copied');
    if (await _tableRowCount('activity_records') != activityCount ||
        await _tableRowCount('activity_feedback') != feedbackCount) {
      throw StateError('Schema v4 -> v5 row count changed');
    }
    await customStatement('DROP TABLE activity_feedback_v4_backup');
    await migrationFailureHook?.call('v5-after-backup-dropped');

    await _ensureLearningRunsV5Constraints();

    await _createV5ActivityIndexes();
    await _createProtectionTriggers();
    await migrationFailureHook?.call('v5-before-verify');
    await _verifySchemaV5(
      expectedActivities: activityCount,
      expectedFeedback: feedbackCount,
    );
  }

  Future<void> _ensureLearningRunsV5Constraints() async {
    final table = await customSelect(
      "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'learning_runs'",
    ).getSingleOrNull();
    final sql = table?.readNullable<String>('sql') ?? '';
    if (sql.contains("json_type(current_values_json, '\$.factors')")) {
      return;
    }
    await _dropProtectionTriggers();
    for (final name in const [
      'learning_runs_idempotency',
      'learning_runs_source_time',
      'learning_runs_status_time',
    ]) {
      await customStatement('DROP INDEX IF EXISTS $name');
    }
    await customStatement('PRAGMA foreign_keys = OFF');
    await customStatement('PRAGMA legacy_alter_table = ON');
    await customStatement(
      'ALTER TABLE learning_runs RENAME TO learning_runs_v5_old',
    );
    await customStatement('''
      CREATE TABLE learning_runs (
        id TEXT NOT NULL,
        parameter_family TEXT NOT NULL,
        source_model_identity TEXT NOT NULL,
        source_personalization_version_id TEXT NULL,
        status TEXT NOT NULL,
        result TEXT NULL,
        evidence_snapshot_json TEXT NOT NULL,
        evidence_hash TEXT NOT NULL,
        evidence_hash_version TEXT NOT NULL,
        algorithm_version TEXT NOT NULL,
        config_version TEXT NOT NULL,
        current_values_json TEXT NOT NULL,
        candidate_values_json TEXT NULL,
        reason_codes_json TEXT NOT NULL,
        triggered_at INTEGER NOT NULL,
        completed_at INTEGER NULL,
        PRIMARY KEY (id),
        CHECK (length(trim(id)) > 0),
        CHECK (parameter_family IN ('baseline', 'activityImpact')),
        CHECK (length(trim(source_model_identity)) > 0),
        CHECK (status IN ('pending', 'running', 'completed', 'retryableFailure', 'terminalFailure')),
        CHECK (result IS NULL OR result IN ('insufficientEvidence', 'readyForAudit', 'unstable', 'noChange', 'candidate', 'configurationBlocked', 'improved', 'worsened')),
        CHECK (json_valid(evidence_snapshot_json) AND json_type(evidence_snapshot_json) = 'object'),
        CHECK (length(evidence_hash) = 64 AND evidence_hash = lower(evidence_hash) AND evidence_hash NOT GLOB '*[^0-9a-f]*'),
        CHECK (length(trim(evidence_hash_version)) > 0),
        CHECK (length(trim(algorithm_version)) > 0),
        CHECK (length(trim(config_version)) > 0),
        CHECK (json_valid(current_values_json) AND json_type(current_values_json) = 'object'),
        CHECK ((parameter_family = 'baseline' AND json_type(current_values_json, '\$.baseEnergy') = 'integer' AND json_extract(current_values_json, '\$.baseEnergy') BETWEEN 60 AND 140) OR (parameter_family = 'activityImpact' AND json_type(current_values_json, '\$.factors') = 'object')),
        CHECK ((parameter_family = 'baseline' AND current_values_json = json_object('baseEnergy', json_extract(current_values_json, '\$.baseEnergy'))) OR (parameter_family = 'activityImpact' AND current_values_json = json_object('factors', json_extract(current_values_json, '\$.factors')))),
        CHECK ((result = 'candidate' AND status = 'completed' AND candidate_values_json IS NOT NULL AND json_valid(candidate_values_json) AND ((parameter_family = 'baseline' AND json_type(candidate_values_json, '\$.baseEnergy') = 'integer' AND json_extract(candidate_values_json, '\$.baseEnergy') BETWEEN 60 AND 140 AND candidate_values_json = json_object('baseEnergy', json_extract(candidate_values_json, '\$.baseEnergy'))) OR (parameter_family = 'activityImpact' AND json_type(candidate_values_json, '\$.factors') = 'object' AND candidate_values_json = json_object('factors', json_extract(candidate_values_json, '\$.factors'))))) OR ((result IS NULL OR result != 'candidate') AND candidate_values_json IS NULL)),
        CHECK (json_valid(reason_codes_json) AND json_type(reason_codes_json) = 'array'),
        CHECK (((status IN ('pending', 'running')) AND result IS NULL AND completed_at IS NULL) OR (status = 'completed' AND result IS NOT NULL AND completed_at IS NOT NULL) OR (status IN ('retryableFailure', 'terminalFailure') AND result IS NULL AND completed_at IS NOT NULL)),
        CHECK ((algorithm_version = 'evidence-shadow-v1' AND source_personalization_version_id IS NULL AND candidate_values_json IS NULL) OR (algorithm_version != 'evidence-shadow-v1' AND source_personalization_version_id IS NOT NULL)),
        FOREIGN KEY (source_personalization_version_id) REFERENCES personalization_versions(id) ON UPDATE RESTRICT ON DELETE RESTRICT
      )
    ''');
    await customStatement('''
      INSERT INTO learning_runs SELECT * FROM learning_runs_v5_old
    ''');
    await customStatement('DROP TABLE learning_runs_v5_old');
    await customStatement('PRAGMA legacy_alter_table = OFF');
    await customStatement('PRAGMA foreign_keys = ON');
    await _createV3IndexesAfterMigration();
    await _createLearningRunProtectionTrigger();
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
    await _createLegacyActivityFeedbackTableV2();
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

  Future<void> _createLegacyActivityFeedbackTableV2() async {
    await customStatement('''
      CREATE TABLE activity_feedback (
        id TEXT NOT NULL,
        activity_record_id TEXT NOT NULL,
        life_day TEXT NOT NULL,
        subcategory_snapshot TEXT NOT NULL,
        duration_minutes_snapshot INTEGER NOT NULL,
        theoretical_delta_snapshot INTEGER NOT NULL,
        applied_delta_snapshot INTEGER NOT NULL,
        impact_sign_snapshot TEXT NOT NULL,
        rule_version_snapshot TEXT NOT NULL,
        activity_updated_at_snapshot INTEGER NOT NULL,
        direction TEXT NOT NULL,
        status TEXT NOT NULL,
        invalidation_reason TEXT NULL,
        observed_at INTEGER NOT NULL,
        PRIMARY KEY (id),
        CHECK (length(trim(id)) > 0),
        CHECK (length(trim(activity_record_id)) > 0),
        CHECK (subcategory_snapshot IN ('classAttendance', 'selfStudyOrThesis', 'homework', 'reviewOrExamPrep', 'organizeOrSummarize', 'otherStudy', 'implementationOrDevelopment', 'experiment', 'projectProgress', 'debuggingOrRevision', 'organizationOrAdministration', 'otherPractice', 'nap', 'lightActivity', 'mentalReset', 'exerciseRecovery', 'lifeMaintenance', 'otherRecovery', 'gaming', 'shortVideo', 'seriesOrMovie', 'chatOrSocial', 'hobbyEntertainment', 'otherLeisure')),
        CHECK (duration_minutes_snapshot IN (15, 30, 45, 60, 90, 120)),
        CHECK (impact_sign_snapshot IN ('consumption', 'recovery', 'zero')),
        CHECK ((impact_sign_snapshot = 'consumption' AND theoretical_delta_snapshot < 0) OR (impact_sign_snapshot = 'recovery' AND theoretical_delta_snapshot > 0) OR (impact_sign_snapshot = 'zero' AND theoretical_delta_snapshot = 0)),
        CHECK (length(trim(rule_version_snapshot)) > 0),
        CHECK (direction IN ('strongerImpact', 'aboutRight', 'weakerImpact', 'directionMismatch')),
        CHECK (status IN ('active', 'invalidated')),
        CHECK (invalidation_reason IS NULL OR invalidation_reason IN ('activityDeleted', 'activityEdited', 'integrityFailure')),
        CHECK ((status = 'active' AND invalidation_reason IS NULL) OR (status = 'invalidated' AND invalidation_reason IS NOT NULL)),
        FOREIGN KEY (activity_record_id) REFERENCES activity_records(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
        FOREIGN KEY (rule_version_snapshot) REFERENCES rule_config_versions(version) ON UPDATE RESTRICT ON DELETE RESTRICT
      )
    ''');
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

  Future<void> _verifySchemaV5({
    required int expectedActivities,
    required int expectedFeedback,
  }) async {
    await _verifyForeignKeysAndIntegrity('Schema v5 migration');
    for (final table in const [
      'personalization_activity_factors',
      'activity_feedback_samples',
    ]) {
      if (await _tableRowCount(table) != 0) {
        throw StateError('Schema v5 fabricated $table rows');
      }
    }
    if (await _tableRowCount('activity_records') != expectedActivities ||
        await _tableRowCount('activity_feedback') != expectedFeedback) {
      throw StateError('Schema v5 changed activity row counts');
    }
    final activityColumns = await customSelect(
      'PRAGMA table_info(activity_records)',
    ).get();
    final activityNames = activityColumns
        .map((row) => row.read<String>('name'))
        .toSet();
    if (!activityNames.containsAll(const {
      'default_theoretical_delta',
      'activity_factor',
      'personalized_theoretical_delta',
      'personalization_version_id',
      'factor_regime_started_life_day',
    })) {
      throw StateError('Schema v5 activity snapshots are missing');
    }
    final feedbackColumns = await customSelect(
      'PRAGMA table_info(activity_feedback)',
    ).get();
    final feedbackNames = feedbackColumns
        .map((row) => row.read<String>('name'))
        .toSet();
    if (!feedbackNames.containsAll(const {
      'default_theoretical_delta_snapshot',
      'factor_snapshot',
      'personalized_theoretical_delta_snapshot',
      'personalization_version_id',
      'factor_regime_started_life_day',
      'collection_source',
      'sampling_policy_version',
      'sampled_at',
      'sample_id',
    })) {
      throw StateError('Schema v5 feedback snapshots are missing');
    }
    final legacyFeedback = await customSelect('''
      SELECT COUNT(*) AS row_count
      FROM activity_feedback
      WHERE collection_source = 'userInitiated'
        AND sample_id IS NULL
        AND factor_snapshot = 1.0
        AND default_theoretical_delta_snapshot = theoretical_delta_snapshot
        AND personalized_theoretical_delta_snapshot = theoretical_delta_snapshot
    ''').getSingle();
    if (legacyFeedback.read<int>('row_count') != expectedFeedback) {
      throw StateError('Schema v5 legacy feedback bridge is invalid');
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
