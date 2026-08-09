import 'package:power_manager/data/export/power_manager_export_dto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';

final backupFixtureNow = DateTime.utc(2026, 8, 9, 4);

PowerManagerExportDto backupFixture({int baseEnergy = 100}) {
  final config = EnergyRuleConfig.v2MvpA();
  return PowerManagerExportDto(
    schemaVersion: 1,
    exportedAt: backupFixtureNow,
    appVersion: '0.1.0+fixture',
    appSettings: AppSettings(
      baseEstimatedEnergy: baseEnergy,
      pendingBaseEstimatedEnergy: null,
      baseEnergyEffectiveLifeDay: null,
      activeRuleVersion: config.ruleVersion,
      pendingRuleVersion: null,
      pendingRuleEffectiveLifeDay: null,
      onboardingCompleted: true,
      createdAt: backupFixtureNow,
      updatedAt: backupFixtureNow,
    ),
    ruleVersions: [
      RuleConfigVersion(
        version: config.ruleVersion,
        values: {
          'ruleVersion': config.ruleVersion,
          'activityRules': {
            for (final rule in config.rules)
              rule.subcategory.code: {
                for (final duration in DurationSlot.values)
                  '${duration.minutes}': rule.deltas[duration],
              },
          },
        },
        createdAt: backupFixtureNow,
      ),
    ],
    morningCheckIns: const [],
    activityRecords: const [],
    energyObservations: const [],
    dailySummaries: const [],
    promptReceipts: const [],
  );
}
