import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

final class EnergyRuleConfigLoader {
  const EnergyRuleConfigLoader(this.rules);

  final RuleConfigVersionsRepository rules;

  Future<EnergyRuleConfig> load(String version) async {
    final stored = await rules.find(version);
    if (stored == null) {
      throw StateError('Rule version $version does not exist');
    }
    final rawRules = stored.values['activityRules'];
    if (rawRules is! Map<String, Object?>) {
      throw FormatException('Rule version $version has no activityRules');
    }
    return EnergyRuleConfig(
      ruleVersion: version,
      rules: [
        for (final subcategory in ActivitySubcategory.values)
          SubcategoryEnergyRule(
            subcategory: subcategory,
            deltas: {
              for (final duration in DurationSlot.values)
                duration: _readDelta(rawRules, subcategory, duration),
            },
          ),
      ],
    )..validateOrThrow();
  }

  int _readDelta(
    Map<String, Object?> rawRules,
    ActivitySubcategory subcategory,
    DurationSlot duration,
  ) {
    final rawRow = rawRules[subcategory.code];
    if (rawRow is! Map<String, Object?>) {
      throw FormatException('Missing rule row ${subcategory.code}');
    }
    final value = rawRow[duration.minutes.toString()];
    if (value is! int) {
      throw FormatException(
        'Missing ${subcategory.code}/${duration.minutes} rule value',
      );
    }
    return value;
  }
}
