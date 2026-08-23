import 'dart:collection';

import 'package:power_manager/domain/energy/energy_enums.dart';

const energyRulesV2MvpAVersion = 'energy-rules-v2-mvp-a';

final class SubcategoryEnergyRule {
  SubcategoryEnergyRule({
    required this.subcategory,
    required Map<DurationSlot, int> deltas,
  }) : deltas = UnmodifiableMapView(Map.of(deltas));

  final ActivitySubcategory subcategory;
  final Map<DurationSlot, int> deltas;
}

final class EnergyRuleValidationException implements Exception {
  const EnergyRuleValidationException(this.issues);

  final List<String> issues;

  @override
  String toString() => 'Invalid energy rule config: ${issues.join('; ')}';
}

final class EnergyRuleConfig {
  EnergyRuleConfig({
    required this.ruleVersion,
    required Iterable<SubcategoryEnergyRule> rules,
  }) : rules = List.unmodifiable(rules);

  factory EnergyRuleConfig.v2MvpA() {
    final config = EnergyRuleConfig(
      ruleVersion: energyRulesV2MvpAVersion,
      rules: _v2MvpARules,
    );
    config.validateOrThrow();
    return config;
  }

  final String ruleVersion;
  final List<SubcategoryEnergyRule> rules;

  int get cellCount =>
      rules.fold(0, (total, rule) => total + rule.deltas.length);

  List<String> validate() {
    final issues = <String>[];
    if (ruleVersion.trim().isEmpty) {
      issues.add('ruleVersion must not be empty');
    }

    final seen = <ActivitySubcategory>{};
    for (final rule in rules) {
      if (!seen.add(rule.subcategory)) {
        issues.add('duplicate subcategory: ${rule.subcategory.code}');
      }

      final missingSlots = DurationSlot.values
          .where((slot) => !rule.deltas.containsKey(slot))
          .map((slot) => slot.minutes)
          .toList();
      if (missingSlots.isNotEmpty) {
        issues.add(
          '${rule.subcategory.code} is missing duration slots: $missingSlots',
        );
      }
      if (rule.deltas.length != DurationSlot.values.length) {
        issues.add(
          '${rule.subcategory.code} must contain exactly '
          '${DurationSlot.values.length} duration slots',
        );
      }
    }

    final missingSubcategories = ActivitySubcategory.values
        .where((subcategory) => !seen.contains(subcategory))
        .map((subcategory) => subcategory.code)
        .toList();
    if (missingSubcategories.isNotEmpty) {
      issues.add('missing subcategories: $missingSubcategories');
    }
    if (rules.length != ActivitySubcategory.values.length) {
      issues.add(
        'config must contain exactly ${ActivitySubcategory.values.length} '
        'subcategory rules',
      );
    }
    if (cellCount !=
        ActivitySubcategory.values.length * DurationSlot.values.length) {
      issues.add('config must contain exactly 144 cells');
    }

    return List.unmodifiable(issues);
  }

  void validateOrThrow() {
    final issues = validate();
    if (issues.isNotEmpty) {
      throw EnergyRuleValidationException(issues);
    }
  }

  int theoreticalDelta(ActivitySubcategory subcategory, DurationSlot duration) {
    if (ruleVersion.trim().isEmpty) {
      throw StateError('Cannot read an invalid rule config');
    }

    final matches = rules.where((rule) => rule.subcategory == subcategory);
    if (matches.length != 1) {
      throw StateError(
        'Expected one rule for ${subcategory.code}, found ${matches.length}',
      );
    }
    final delta = matches.single.deltas[duration];
    if (delta == null) {
      throw StateError(
        'Missing ${duration.minutes}-minute rule for ${subcategory.code}',
      );
    }
    return delta;
  }
}

SubcategoryEnergyRule _rule(ActivitySubcategory subcategory, List<int> deltas) {
  if (deltas.length != DurationSlot.values.length) {
    throw ArgumentError.value(deltas, 'deltas', 'Expected exactly 6 values');
  }
  return SubcategoryEnergyRule(
    subcategory: subcategory,
    deltas: {
      for (var index = 0; index < DurationSlot.values.length; index++)
        DurationSlot.values[index]: deltas[index],
    },
  );
}

final List<SubcategoryEnergyRule> _v2MvpARules = [
  _rule(ActivitySubcategory.classAttendance, [-5, -5, -8, -12, -16, -20]),
  _rule(ActivitySubcategory.selfStudyOrThesis, [-5, -12, -16, -20, -25, -25]),
  _rule(ActivitySubcategory.homework, [-5, -8, -12, -16, -20, -25]),
  _rule(ActivitySubcategory.reviewOrExamPrep, [-5, -12, -16, -20, -25, -30]),
  _rule(ActivitySubcategory.organizeOrSummarize, [0, -5, -5, -8, -12, -16]),
  _rule(ActivitySubcategory.otherStudy, [-5, -8, -12, -16, -20, -25]),
  _rule(ActivitySubcategory.implementationOrDevelopment, [
    -5,
    -5,
    -8,
    -12,
    -16,
    -20,
  ]),
  _rule(ActivitySubcategory.experiment, [-5, -12, -16, -20, -25, -25]),
  _rule(ActivitySubcategory.projectProgress, [-5, -5, -8, -12, -16, -20]),
  _rule(ActivitySubcategory.debuggingOrRevision, [-5, -12, -16, -20, -25, -30]),
  _rule(ActivitySubcategory.organizationOrAdministration, [
    -5,
    -8,
    -12,
    -16,
    -20,
    -25,
  ]),
  _rule(ActivitySubcategory.otherPractice, [-5, -8, -12, -16, -20, -25]),
  _rule(ActivitySubcategory.nap, [5, 10, 10, 15, 15, 10]),
  _rule(ActivitySubcategory.lightActivity, [5, 5, 5, 5, 10, -5]),
  _rule(ActivitySubcategory.mentalReset, [5, 5, 0, 0, -5, -8]),
  _rule(ActivitySubcategory.exerciseRecovery, [5, 5, 5, 5, 5, -5]),
  _rule(ActivitySubcategory.lifeMaintenance, [5, 5, 5, 0, -5, -5]),
  _rule(ActivitySubcategory.otherRecovery, [5, 5, 5, 0, -5, -5]),
  _rule(ActivitySubcategory.gaming, [-5, -5, -12, -12, -20, -25]),
  _rule(ActivitySubcategory.shortVideo, [0, -5, -5, -12, -20, -25]),
  _rule(ActivitySubcategory.seriesOrMovie, [0, 0, 0, 0, -5, -12]),
  _rule(ActivitySubcategory.chatOrSocial, [5, 0, 0, -5, -5, -12]),
  _rule(ActivitySubcategory.hobbyEntertainment, [5, 5, 0, 0, -5, -5]),
  _rule(ActivitySubcategory.otherLeisure, [0, 0, -5, -5, -12, -16]),
];
