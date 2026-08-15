import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/export/power_manager_export_dto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
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
    LearningRunsTable,
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
    LearningRunsDao,
    DailySummariesDao,
    PromptReceiptsDao,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase.forExecutor(
    QueryExecutor executor, {
    Clock clock = const SystemClock(),
    SchemaMigrationFailureHook? migrationFailureHook,
  }) : this._(
         executor,
         clock: clock,
         migrationFailureHook: migrationFailureHook,
       );

  AppDatabase._(
    super.executor, {
    required this.clock,
    this.migrationFailureHook,
  });

  final Clock clock;
  final SchemaMigrationFailureHook? migrationFailureHook;

  @override
  int get schemaVersion => 3;

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
    await _createProtectionTriggers();
  }

  Future<void> _createProtectionTriggers({
    bool includeLearningRuns = true,
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
    await into(appSettingsTable).insert(
      AppSettingsTableCompanion.insert(
        id: const Value(1),
        baseEstimatedEnergy: const Value(100),
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
