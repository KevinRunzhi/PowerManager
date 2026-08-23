import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:test/test.dart';

void main() {
  group('stable domain enums', () {
    test('contains 4 categories, 24 subcategories, and 6 duration slots', () {
      expect(ActivityCategory.values, hasLength(4));
      expect(ActivitySubcategory.values, hasLength(24));
      expect(DurationSlot.values.map((slot) => slot.minutes), [
        15,
        30,
        45,
        60,
        90,
        120,
      ]);
    });

    test('each category owns exactly 6 uniquely coded subcategories', () {
      expect(
        ActivitySubcategory.values
            .map((subcategory) => subcategory.code)
            .toSet(),
        hasLength(24),
      );
      for (final category in ActivityCategory.values) {
        expect(
          ActivitySubcategory.values.where(
            (subcategory) => subcategory.category == category,
          ),
          hasLength(6),
          reason: category.code,
        );
      }
    });

    test(
      'observation and estimate enums preserve the specified vocabulary',
      () {
        expect(AbsoluteEnergyState.values.map((state) => state.code), [
          'exhausted',
          'low',
          'okay',
          'good',
          'full',
        ]);
        expect(RelativeCorrection.values.map((state) => state.code), [
          'lower',
          'aboutRight',
          'higher',
        ]);
        expect(EstimatedEnergyBand.values.map((band) => band.code), [
          'estimatedOverdraft',
          'estimatedLow',
          'estimatedMediumLow',
          'estimatedNormal',
        ]);
        expect(SleepRecovery.values.map((state) => state.code), [
          'bad',
          'normal',
          'good',
        ]);
      },
    );
  });

  group('EnergyRuleConfig v2 MVP-A', () {
    final config = EnergyRuleConfig.v2MvpA();

    test('has a non-empty immutable version and exactly 144 cells', () {
      expect(config.ruleVersion, energyRulesV2MvpAVersion);
      expect(config.rules, hasLength(24));
      expect(config.cellCount, 144);
      expect(config.validate(), isEmpty);
      expect(
        config.rules.every(
          (rule) => rule.deltas.length == DurationSlot.values.length,
        ),
        isTrue,
      );
    });

    test('matches all 144 source-of-truth values', () {
      final expectedRows = <ActivitySubcategory, List<int>>{
        ActivitySubcategory.classAttendance: [-5, -5, -8, -12, -16, -20],
        ActivitySubcategory.selfStudyOrThesis: [-5, -12, -16, -20, -25, -25],
        ActivitySubcategory.homework: [-5, -8, -12, -16, -20, -25],
        ActivitySubcategory.reviewOrExamPrep: [-5, -12, -16, -20, -25, -30],
        ActivitySubcategory.organizeOrSummarize: [0, -5, -5, -8, -12, -16],
        ActivitySubcategory.otherStudy: [-5, -8, -12, -16, -20, -25],
        ActivitySubcategory.implementationOrDevelopment: [
          -5,
          -5,
          -8,
          -12,
          -16,
          -20,
        ],
        ActivitySubcategory.experiment: [-5, -12, -16, -20, -25, -25],
        ActivitySubcategory.projectProgress: [-5, -5, -8, -12, -16, -20],
        ActivitySubcategory.debuggingOrRevision: [-5, -12, -16, -20, -25, -30],
        ActivitySubcategory.organizationOrAdministration: [
          -5,
          -8,
          -12,
          -16,
          -20,
          -25,
        ],
        ActivitySubcategory.otherPractice: [-5, -8, -12, -16, -20, -25],
        ActivitySubcategory.nap: [5, 10, 10, 15, 15, 10],
        ActivitySubcategory.lightActivity: [5, 5, 5, 5, 10, -5],
        ActivitySubcategory.mentalReset: [5, 5, 0, 0, -5, -8],
        ActivitySubcategory.exerciseRecovery: [5, 5, 5, 5, 5, -5],
        ActivitySubcategory.lifeMaintenance: [5, 5, 5, 0, -5, -5],
        ActivitySubcategory.otherRecovery: [5, 5, 5, 0, -5, -5],
        ActivitySubcategory.gaming: [-5, -5, -12, -12, -20, -25],
        ActivitySubcategory.shortVideo: [0, -5, -5, -12, -20, -25],
        ActivitySubcategory.seriesOrMovie: [0, 0, 0, 0, -5, -12],
        ActivitySubcategory.chatOrSocial: [5, 0, 0, -5, -5, -12],
        ActivitySubcategory.hobbyEntertainment: [5, 5, 0, 0, -5, -5],
        ActivitySubcategory.otherLeisure: [0, 0, -5, -5, -12, -16],
      };

      for (final MapEntry(key: subcategory, value: expected)
          in expectedRows.entries) {
        expect(
          DurationSlot.values
              .map((duration) => config.theoreticalDelta(subcategory, duration))
              .toList(),
          expected,
          reason: subcategory.code,
        );
      }
    });

    test('validation reports duplicate and missing subcategories', () {
      final onlyRule = config.rules.first;
      final invalid = EnergyRuleConfig(
        ruleVersion: energyRulesV2MvpAVersion,
        rules: [onlyRule, onlyRule],
      );

      expect(invalid.validate(), contains(contains('duplicate subcategory')));
      expect(invalid.validate(), contains(contains('missing subcategories')));
      expect(
        invalid.validateOrThrow,
        throwsA(isA<EnergyRuleValidationException>()),
      );
    });

    test('validation reports an empty version and incomplete duration row', () {
      final invalid = EnergyRuleConfig(
        ruleVersion: ' ',
        rules: [
          SubcategoryEnergyRule(
            subcategory: ActivitySubcategory.classAttendance,
            deltas: {DurationSlot.minutes15: -5},
          ),
        ],
      );

      expect(invalid.validate(), contains('ruleVersion must not be empty'));
      expect(invalid.validate(), contains(contains('missing duration slots')));
      expect(
        invalid.validate(),
        contains('config must contain exactly 144 cells'),
      );
    });
  });
}
