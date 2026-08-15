import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/export/power_manager_export_dto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/personalization_identity.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

part 'app_database.g.dart';
part 'backup_restore.dart';
part 'converters.dart';
part 'daos.dart';
part 'migrations.dart';
part 'tables.dart';

@DriftDatabase(
  tables: [
    AppSettingsTable,
    RuleConfigVersionsTable,
    MorningCheckInsTable,
    ActivityRecordsTable,
    EnergyObservationsTable,
    ActivityFeedbackTable,
    PersonalizationActivityFactorsTable,
    ActivityFeedbackSamplesTable,
    LearningRunsTable,
    PersonalizationVersionsTable,
    LearningConsentsTable,
    LearningNoticesTable,
    DailySummariesTable,
    PromptReceiptsTable,
  ],
  daos: [
    AppSettingsDao,
    RuleConfigVersionsDao,
    MorningCheckInsDao,
    ActivityRecordsDao,
    EnergyObservationsDao,
    ActivityFeedbackDao,
    PersonalizationActivityFactorsDao,
    ActivityFeedbackSamplesDao,
    LearningRunsDao,
    PersonalizationVersionsDao,
    LearningConsentsDao,
    LearningNoticesDao,
    DailySummariesDao,
    PromptReceiptsDao,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase.forExecutor(
    QueryExecutor executor, {
    Clock clock = const SystemClock(),
    SchemaMigrationFailureHook? migrationFailureHook,
    int schemaVersionOverride = 5,
  }) : this._(
         executor,
         clock: clock,
         migrationFailureHook: migrationFailureHook,
         schemaVersionOverride: schemaVersionOverride,
       );

  AppDatabase._(
    super.executor, {
    required this.clock,
    this.migrationFailureHook,
    required this.schemaVersionOverride,
  });

  final Clock clock;
  final SchemaMigrationFailureHook? migrationFailureHook;
  final int schemaVersionOverride;

  @override
  int get schemaVersion => schemaVersionOverride;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createSchemaExtras();
    },
    onUpgrade: _upgradeSchema,
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await transaction(_seedDefaults);
    },
  );

  Future<void> _createSchemaExtras() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS energy_observations_one_daily_absolute
      ON energy_observations (life_day)
      WHERE type = 'dailyAbsolute'
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS activity_feedback_one_active_per_activity
      ON activity_feedback (activity_record_id)
      WHERE status = 'active'
    ''');
    await _createV5ActivityIndexes();
    await _createV4PersonalizationIndexes();
    await _createProtectionTriggers();
  }

  Future<void> _createV5ActivityIndexes() async {
    await customStatement('''
      CREATE INDEX IF NOT EXISTS activity_records_life_day_order
      ON activity_records (life_day, completed_at, created_at, id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS activity_feedback_activity_order
      ON activity_feedback (activity_record_id, observed_at, id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS activity_feedback_life_day_status
      ON activity_feedback (life_day, status, observed_at, id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS personalization_activity_factors_source
      ON personalization_activity_factors (source_learning_run_id)
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS activity_feedback_samples_activity_day
      ON activity_feedback_samples (activity_record_id, life_day, selected_at)
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS activity_feedback_one_active_per_activity
      ON activity_feedback (activity_record_id)
      WHERE status = 'active'
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS activity_feedback_samples_one_active_policy
      ON activity_feedback_samples (activity_record_id, sampling_policy_version)
      WHERE status != 'invalidated'
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS activity_feedback_samples_one_feedback
      ON activity_feedback_samples (feedback_id)
      WHERE feedback_id IS NOT NULL
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS activity_feedback_one_sample
      ON activity_feedback (sample_id)
      WHERE sample_id IS NOT NULL
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS referenced_rule_versions_reject_update_v5
      BEFORE UPDATE ON rule_config_versions
      WHEN EXISTS (
        SELECT 1 FROM personalization_activity_factors
        WHERE base_activity_rule_version = OLD.version
      )
      BEGIN
        SELECT RAISE (ABORT, 'referenced activity factor rule versions are immutable');
      END
    ''');
  }

  Future<void> _createV4PersonalizationIndexes() async {
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS personalization_versions_one_active
      ON personalization_versions ((1))
      WHERE status = 'active'
    ''');
    await customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS personalization_versions_one_pending
      ON personalization_versions ((1))
      WHERE status IN ('candidate', 'awaitingReview', 'deferred', 'scheduled')
    ''');
  }

  Future<void> _createProtectionTriggers({
    bool includeLearningRuns = true,
    bool includePersonalization = true,
  }) async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS daily_summaries_reject_update
      BEFORE UPDATE ON daily_summaries
      BEGIN
        SELECT RAISE(ABORT, 'daily summaries are immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS app_settings_reject_delete
      BEFORE DELETE ON app_settings
      BEGIN
        SELECT RAISE(ABORT, 'app settings row must exist');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS daily_summaries_reject_delete
      BEFORE DELETE ON daily_summaries
      BEGIN
        SELECT RAISE(ABORT, 'daily summaries are immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS referenced_rule_versions_reject_update
      BEFORE UPDATE ON rule_config_versions
      WHEN
        EXISTS (
          SELECT 1 FROM app_settings
          WHERE active_rule_version = OLD.version
             OR pending_rule_version = OLD.version
        )
        OR EXISTS (
          SELECT 1 FROM activity_records
          WHERE rule_version = OLD.version
        )
        OR EXISTS (
          SELECT 1 FROM daily_summaries
          WHERE rule_version = OLD.version
        )
        OR EXISTS (
          SELECT 1 FROM energy_observations
          WHERE rule_version_at_observation = OLD.version
        )
        OR EXISTS (
          SELECT 1 FROM activity_feedback
          WHERE rule_version_snapshot = OLD.version
        )
      BEGIN
        SELECT RAISE(ABORT, 'referenced rule versions are immutable');
      END
    ''');
    if (includeLearningRuns) {
      await _createLearningRunProtectionTrigger();
    }
    if (includePersonalization) {
      await _createPersonalizationProtectionTriggers();
    }
  }

  Future<void> _createLearningRunProtectionTrigger() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS learning_runs_reject_final_update
      BEFORE UPDATE ON learning_runs
      WHEN OLD.status IN ('completed', 'terminalFailure')
      BEGIN
        SELECT RAISE(ABORT, 'final learning runs are immutable');
      END
    ''');
  }

  Future<void> _createPersonalizationProtectionTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS personalization_versions_reject_delete
      BEFORE DELETE ON personalization_versions
      BEGIN
        SELECT RAISE(ABORT, 'personalization versions are immutable history');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS personalization_versions_reject_identity_update
      BEFORE UPDATE ON personalization_versions
      WHEN
        NEW.id IS NOT OLD.id
        OR NEW.parent_version_id IS NOT OLD.parent_version_id
        OR NEW.effective_model_fingerprint IS NOT OLD.effective_model_fingerprint
        OR NEW.model_regime_epoch IS NOT OLD.model_regime_epoch
        OR NEW.creation_source IS NOT OLD.creation_source
        OR NEW.source_learning_run_id IS NOT OLD.source_learning_run_id
        OR NEW.algorithm_version IS NOT OLD.algorithm_version
        OR NEW.config_version IS NOT OLD.config_version
        OR NEW.changed_parameter_family IS NOT OLD.changed_parameter_family
        OR NEW.base_energy IS NOT OLD.base_energy
        OR NEW.baseline_anchor_energy IS NOT OLD.baseline_anchor_energy
        OR NEW.created_at IS NOT OLD.created_at
      BEGIN
        SELECT RAISE(ABORT, 'personalization version identity is immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS personalization_versions_reject_terminal_update
      BEFORE UPDATE ON personalization_versions
      WHEN OLD.status IN ('superseded', 'rejected', 'reverted', 'canceled', 'invalidated')
      BEGIN
        SELECT RAISE(ABORT, 'terminal personalization versions are immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS learning_consents_reject_update
      BEFORE UPDATE ON learning_consents
      BEGIN
        SELECT RAISE(ABORT, 'learning consents are immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS learning_consents_reject_delete
      BEFORE DELETE ON learning_consents
      BEGIN
        SELECT RAISE(ABORT, 'learning consents are immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS learning_notices_reject_identity_update
      BEFORE UPDATE ON learning_notices
      WHEN
        NEW.id IS NOT OLD.id
        OR NEW.parameter_family IS NOT OLD.parameter_family
        OR NEW.type IS NOT OLD.type
        OR NEW.personalization_version_id IS NOT OLD.personalization_version_id
        OR NEW.learning_run_id IS NOT OLD.learning_run_id
        OR NEW.dedup_key IS NOT OLD.dedup_key
        OR NEW.reason_code IS NOT OLD.reason_code
        OR NEW.created_at IS NOT OLD.created_at
      BEGIN
        SELECT RAISE(ABORT, 'learning notice identity is immutable');
      END
    ''');
  }

  Future<void> _seedDefaults() async {
    final createdAt = clock.now().toUtc();
    await into(ruleConfigVersionsTable).insert(
      RuleConfigVersionsTableCompanion.insert(
        version: energyRulesV2MvpAVersion,
        valuesJson: _encodeDefaultRuleConfig(),
        createdAt: createdAt,
      ),
      mode: InsertMode.insertOrIgnore,
    );
    final initial = initialPersonalizationVersion(
      baseEnergy: 100,
      createdAt: createdAt,
      transitionReason: 'freshSchemaV4Initial',
    );
    await into(personalizationVersionsTable).insert(
      PersonalizationVersionsTableCompanion.insert(
        id: initial.id,
        parentVersionId: const Value(null),
        effectiveModelFingerprint: initial.effectiveModelFingerprint,
        modelRegimeEpoch: initial.modelRegimeEpoch,
        creationSource: initial.creationSource,
        scheduleSource: const Value(null),
        sourceLearningRunId: const Value(null),
        algorithmVersion: initial.algorithmVersion,
        configVersion: initial.configVersion,
        changedParameterFamily: initial.changedParameterFamily,
        baseEnergy: initial.baseEnergy,
        baselineAnchorEnergy: initial.baselineAnchorEnergy,
        status: initial.status,
        effectiveLifeDay: const Value(null),
        createdAt: initial.createdAt,
        activatedAt: Value(initial.activatedAt),
        endedAt: const Value(null),
        transitionReason: initial.transitionReason,
      ),
      mode: InsertMode.insertOrIgnore,
    );
    await into(appSettingsTable).insert(
      AppSettingsTableCompanion.insert(
        id: const Value(1),
        activeRuleVersion: energyRulesV2MvpAVersion,
        onboardingCompleted: const Value(false),
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }
}

String _encodeDefaultRuleConfig() {
  final config = EnergyRuleConfig.v2MvpA();
  return jsonEncode({
    'ruleVersion': config.ruleVersion,
    'durationSlots': DurationSlot.values.map((slot) => slot.minutes).toList(),
    'activityRules': {
      for (final rule in config.rules)
        rule.subcategory.code: {
          for (final slot in DurationSlot.values)
            slot.minutes.toString(): rule.deltas[slot],
        },
    },
    'morningAdjustments': {
      for (final state in MorningOverallState.values)
        state.code: state.adjustment,
    },
    'shortTermAdjustments': {
      'nonNegative': 0,
      'minus1ToMinus5': -1,
      'minus6ToMinus10': -2,
      'minus11ToMinus20': -3,
      'belowMinus20': -4,
    },
    'estimatedBands': [
      for (final band in EstimatedEnergyBand.values) band.code,
    ],
    'effectiveDayRules': {
      'standard': 'morningCheckIn && activeActivities >= 1',
      'weak': '!morningCheckIn && activeActivities >= 2',
    },
  });
}
