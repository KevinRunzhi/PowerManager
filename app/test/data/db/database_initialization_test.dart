import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/personalization_identity.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

import 'test_database.dart';

void main() {
  test('schema v4 creates exactly twelve business tables', () async {
    final database = createTestDatabase();
    addTearDown(database.close);

    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'table' AND name NOT LIKE 'sqlite_%' "
          'ORDER BY name',
        )
        .get();
    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    final foreignKeys = await database
        .customSelect('PRAGMA foreign_keys')
        .getSingle();
    final integrity = await database
        .customSelect('PRAGMA integrity_check')
        .getSingle();
    final schemaExtras = await database
        .customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type IN ('index', 'trigger') "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .get();

    expect(tables.map((row) => row.read<String>('name')), [
      'activity_feedback',
      'activity_feedback_samples',
      'activity_records',
      'app_settings',
      'daily_summaries',
      'energy_observations',
      'learning_consents',
      'learning_notices',
      'learning_runs',
      'morning_check_ins',
      'personalization_activity_factors',
      'personalization_versions',
      'prompt_receipts',
      'rule_config_versions',
    ]);
    expect(version.read<int>('user_version'), 5);
    expect(foreignKeys.read<int>('foreign_keys'), 1);
    expect(integrity.read<String>('integrity_check'), 'ok');
    expect(
      schemaExtras.map((row) => row.read<String>('name')),
      containsAll([
        'activity_records_life_day_order',
        'activity_feedback_activity_order',
        'activity_feedback_life_day_status',
        'activity_feedback_one_active_per_activity',
        'activity_feedback_samples_activity_day',
        'activity_feedback_samples_one_active_policy',
        'activity_feedback_samples_one_feedback',
        'activity_feedback_one_sample',
        'app_settings_reject_delete',
        'daily_summaries_reject_delete',
        'daily_summaries_reject_update',
        'energy_observations_life_day_time',
        'energy_observations_contract_lookup',
        'energy_observations_one_daily_absolute',
        'learning_runs_idempotency',
        'learning_runs_source_time',
        'learning_runs_status_time',
        'personalization_activity_factors_source',
        'learning_runs_reject_final_update',
        'learning_consents_reject_delete',
        'learning_consents_reject_update',
        'learning_notices_reject_identity_update',
        'personalization_versions_one_active',
        'personalization_versions_one_pending',
        'personalization_versions_reject_delete',
        'personalization_versions_reject_identity_update',
        'personalization_versions_reject_terminal_update',
        'referenced_rule_versions_reject_update',
        'referenced_rule_versions_reject_update_v5',
      ]),
    );
  });

  test('default settings and the complete rule config seed once', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final settingsRepository = DriftAppSettingsRepository(
      AppSettingsDao(database),
    );
    final ruleRepository = DriftRuleConfigVersionsRepository(
      RuleConfigVersionsDao(database),
    );
    final versionsRepository = DriftPersonalizationVersionsRepository(
      PersonalizationVersionsDao(database),
    );

    final settings = await settingsRepository.get();
    final activeModel = await versionsRepository.getActive();
    final rule = await ruleRepository.find(energyRulesV2MvpAVersion);
    final rules = rule!.values['activityRules']! as Map<String, Object?>;

    expect(activeModel.baseEnergy, 100);
    expect(settings.activeRuleVersion, energyRulesV2MvpAVersion);
    expect(await versionsRepository.findPending(), isNull);
    expect(settings.pendingRuleVersion, isNull);
    expect(settings.pendingRuleEffectiveLifeDay, isNull);
    expect(settings.createdAt, testNow);
    expect(settings.createdAt.isUtc, isTrue);
    expect(rule.version, energyRulesV2MvpAVersion);
    expect(rules, hasLength(24));
    expect(
      rules.values.every((row) => (row! as Map<String, Object?>).length == 6),
      isTrue,
    );
    expect(await ruleRepository.list(), hasLength(1));

    final encoded = jsonEncode(rule.values);
    expect(jsonDecode(encoded), isA<Map<String, Object?>>());
  });

  test(
    'closing and reopening a file database preserves data and seeds idempotently',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'power_manager_schema_v4_',
      );
      final databaseFile = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}power_manager.sqlite',
      );
      addTearDown(() async {
        if (temporaryDirectory.existsSync()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });

      final first = AppDatabase.forExecutor(
        NativeDatabase(databaseFile),
        clock: const _FileTestClock(),
      );
      final firstSettings = DriftAppSettingsRepository(AppSettingsDao(first));
      final firstVersions = DriftPersonalizationVersionsRepository(
        PersonalizationVersionsDao(first),
      );
      final original = await firstSettings.get();
      await firstSettings.save(
        AppSettings(
          activeRuleVersion: original.activeRuleVersion,
          pendingRuleVersion: null,
          pendingRuleEffectiveLifeDay: null,
          onboardingCompleted: true,
          createdAt: original.createdAt,
          updatedAt: DateTime.utc(2026, 7, 26, 13),
        ),
      );
      await firstVersions.insert(
        scheduledManualPersonalizationVersion(
          parent: await firstVersions.getActive(),
          baseEnergy: 112,
          effectiveLifeDay: LifeDay(2026, 7, 27),
          createdAt: DateTime.utc(2026, 7, 26, 13),
          ruleVersion: original.activeRuleVersion,
          legacy: false,
        ),
      );
      await first.close();

      final reopened = AppDatabase.forExecutor(
        NativeDatabase(databaseFile),
        clock: const _FileTestClock(),
      );
      final reopenedSettings = DriftAppSettingsRepository(
        AppSettingsDao(reopened),
      );
      final reopenedRules = DriftRuleConfigVersionsRepository(
        RuleConfigVersionsDao(reopened),
      );
      final reopenedVersions = DriftPersonalizationVersionsRepository(
        PersonalizationVersionsDao(reopened),
      );
      final persisted = await reopenedSettings.get();

      expect((await reopenedVersions.getActive()).baseEnergy, 100);
      expect((await reopenedVersions.findPending())!.baseEnergy, 112);
      expect(persisted.onboardingCompleted, isTrue);
      expect(await reopenedRules.list(), hasLength(1));
      await reopened.close();
    },
  );
}

final class _FileTestClock implements Clock {
  const _FileTestClock();

  @override
  DateTime now() => testNow;
}
