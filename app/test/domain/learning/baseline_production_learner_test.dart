import 'dart:convert';

import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/baseline_production_learner.dart';
import 'package:power_manager/domain/learning/baseline_shadow_replay.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

import '../../support/production_backup_fixture.dart';

void main() {
  test('re-identifies frozen evidence and returns a clean candidate', () {
    final run = productionBackupFixture().learningRuns.last;
    final result = const BaselineProductionLearner().evaluate(
      shadowEvidence: _packageFromRun(run),
      baselineAnchorEnergy: 100,
      mode: BaselineReplayMode.review,
      config: BaselineProductionConfig(),
    );

    expect(result.result, LearningRunResult.candidate);
    expect(result.candidateBaseEnergy, 98);
    expect(result.candidateValuesJson, '{"baseEnergy":98}');
    expect(result.evidence.evidenceHash, run.evidenceHash);
    expect(
      result.evidence.evidenceSnapshotJson,
      contains('baseline-production-v1'),
    );
    expect(
      result.evidence.evidenceSnapshotJson,
      isNot(contains('do-not-ship')),
    );
  });

  test(
    'invalid production config is configuration blocked and never candidates',
    () {
      final run = productionBackupFixture().learningRuns.last;
      final result = const BaselineProductionLearner().evaluate(
        shadowEvidence: _packageFromRun(run),
        baselineAnchorEnergy: 100,
        mode: BaselineReplayMode.automatic,
        config: BaselineProductionConfig(step: 0),
      );

      expect(result.result, LearningRunResult.configurationBlocked);
      expect(result.reasonCodes, ['invalidProductionConfiguration']);
      expect(result.candidateValuesJson, isNull);
    },
  );
}

ShadowEvidencePackage _packageFromRun(LearningRun run) {
  final snapshot = jsonDecode(run.evidenceSnapshotJson) as Map<String, Object?>;
  final descriptive = snapshot['descriptive']! as Map<String, Object?>;
  DirectionCounts counts(Map<String, Object?> value) => DirectionCounts(
    lower: value['lower']! as int,
    aligned: value['aligned']! as int,
    higher: value['higher']! as int,
  );
  final hashInput = snapshot['hashInput']! as Map<String, Object?>;
  final reference = ObservationReferenceType.values.firstWhere(
    (value) => value.code == hashInput['referenceType'],
  );
  final readiness = descriptive['readiness']! as Map<String, Object?>;
  final earliest = LifeDay.parse(
    descriptive['earliestSelectedLifeDay']! as String,
  );
  final latest = LifeDay.parse(descriptive['latestSelectedLifeDay']! as String);
  return ShadowEvidencePackage(
    sourceModelIdentity: run.sourceModelIdentity,
    referenceType: reference,
    baseEnergy: 100,
    evidenceSnapshotJson: run.evidenceSnapshotJson,
    evidenceHash: run.evidenceHash,
    currentValuesJson: run.currentValuesJson,
    eligibleTotal: descriptive['eligibleTotal']! as int,
    selectedEligible: descriptive['selectedEligible']! as int,
    excludedTotal: descriptive['excludedTotal']! as int,
    missingToMinimum: descriptive['missingToMinimum']! as int,
    earliestLifeDay: earliest,
    latestLifeDay: latest,
    directionCounts: counts(
      descriptive['directionCounts']! as Map<String, Object?>,
    ),
    windowDirectionCounts: [
      for (final item in descriptive['windowDirectionCounts']! as List<Object?>)
        counts(item as Map<String, Object?>),
    ],
    windowSizes: [
      for (final item in descriptive['windowSizes']! as List<Object?>)
        item as int,
    ],
    exclusionCounts: const {},
    readiness: ShadowReadiness(
      hasMinimumCount: readiness['hasMinimumCount']! as bool,
      hasMinimumSpan: readiness['hasMinimumSpan']! as bool,
      hasCompleteWindows: readiness['hasCompleteWindows']! as bool,
      spanCalendarDays: readiness['spanCalendarDays']! as int,
    ),
  );
}
