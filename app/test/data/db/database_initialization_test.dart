import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:test/test.dart';

import 'test_database.dart';

void main() {
  test('schema v1 creates exactly seven business tables', () async {
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
      'activity_records',
      'app_settings',
      'daily_summaries',
      'energy_observations',
      'morning_check_ins',
      'prompt_receipts',
      'rule_config_versions',
    ]);
    expect(version.read<int>('user_version'), 1);
    expect(foreignKeys.read<int>('foreign_keys'), 1);
    expect(integrity.read<String>('integrity_check'), 'ok');
    expect(
      schemaExtras.map((row) => row.read<String>('name')),
      containsAll([
        'activity_records_life_day_order',
        'app_settings_reject_delete',
        'daily_summaries_reject_delete',
        'daily_summaries_reject_update',
        'energy_observations_life_day_time',
        'energy_observations_one_daily_absolute',
        'referenced_rule_versions_reject_update',
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

    final settings = await settingsRepository.get();
    final rule = await ruleRepository.find(energyRulesV2MvpAVersion);
    final rules = rule!.values['activityRules']! as Map<String, Object?>;

    expect(settings.baseEstimatedEnergy, 100);
    expect(settings.activeRuleVersion, energyRulesV2MvpAVersion);
    expect(settings.pendingBaseEstimatedEnergy, isNull);
    expect(settings.baseEnergyEffectiveLifeDay, isNull);
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
        'power_manager_stage3_',
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
      final original = await firstSettings.get();
      await firstSettings.save(
        AppSettings(
          baseEstimatedEnergy: 112,
          pendingBaseEstimatedEnergy: null,
          baseEnergyEffectiveLifeDay: null,
          activeRuleVersion: original.activeRuleVersion,
          pendingRuleVersion: null,
          pendingRuleEffectiveLifeDay: null,
          onboardingCompleted: true,
          createdAt: original.createdAt,
          updatedAt: DateTime.utc(2026, 7, 26, 13),
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
      final persisted = await reopenedSettings.get();

      expect(persisted.baseEstimatedEnergy, 112);
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
