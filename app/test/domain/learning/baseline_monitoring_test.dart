import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/learning/baseline_monitoring.dart';
import 'package:power_manager/domain/learning/baseline_shadow_replay.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

import '../../support/production_backup_fixture.dart';

void main() {
  test(
    'improvement requires both aligned gain and ordinal error reduction',
    () {
      final evidence = _monitoringPackage(estimate: 25);
      final result = const BaselineMonitoringEvaluator().evaluate(
        evidence: evidence,
        expectedDirection: BaselineReplayDirection.decrease,
        baselineAligned: 10,
        baselineOrdinalError: 4,
      );

      expect(result.result, LearningRunResult.improved);
      expect(result.reasonCodes, ['minimumUsefulImprovementMet']);
      expect(result.after!.aligned, 14);
      expect(result.after!.totalAbsoluteOrdinalError, 0);
    },
  );

  test('opposite evidence crosses the safety boundary and is worsened', () {
    final evidence = _monitoringPackage(estimate: 10);
    final result = const BaselineMonitoringEvaluator().evaluate(
      evidence: evidence,
      expectedDirection: BaselineReplayDirection.decrease,
      baselineAligned: 14,
      baselineOrdinalError: 0,
    );
    expect(result.result, LearningRunResult.worsened);
    expect(result.reasonCodes, contains('oppositeTotalBoundary'));
    expect(result.after!.opposite, 14);
  });

  test('a non-ready epoch never produces a change decision', () {
    final evidence = _monitoringPackage(estimate: 25, selected: 13);
    final result = const BaselineMonitoringEvaluator().evaluate(
      evidence: evidence,
      expectedDirection: BaselineReplayDirection.decrease,
      baselineAligned: 14,
      baselineOrdinalError: 0,
    );
    expect(result.result, LearningRunResult.insufficientEvidence);
  });
}

ShadowEvidencePackage _monitoringPackage({
  required int estimate,
  int selected = 14,
}) {
  final run = productionBackupFixture().learningRuns.last;
  final decoded = jsonDecode(run.evidenceSnapshotJson) as Map<String, Object?>;
  final hashInput = Map<String, Object?>.of(
    decoded['hashInput']! as Map<String, Object?>,
  );
  hashInput['algorithmVersion'] = baselineMonitoringAlgorithmV1;
  hashInput['configVersion'] = baselineMonitoringConfigV1;
  final selectedEvidence = [
    for (final raw
        in (hashInput['selectedEligibleEvidence']! as List<Object?>).take(
          selected,
        ))
      Map<String, Object?>.of(raw! as Map<String, Object?>)
        ..['estimateAtObservation'] = estimate,
  ];
  hashInput['selectedEligibleEvidence'] = selectedEvidence;
  final descriptive =
      Map<String, Object?>.of(decoded['descriptive']! as Map<String, Object?>)
        ..['selectedEligible'] = selected
        ..['windowSizes'] = selected == 14 ? [7, 7] : [7, 6]
        ..['readiness'] = {
          'hasCompleteWindows': selected == 14,
          'hasMinimumCount': selected == 14,
          'hasMinimumSpan': selected == 14,
          'spanCalendarDays': selected == 14 ? 26 : 24,
        };
  const encoder = CanonicalJsonEncoder();
  final snapshot = encoder.encode({
    'descriptive': descriptive,
    'hashInput': hashInput,
  });
  final hash = sha256
      .convert(utf8.encode(encoder.encode(hashInput)))
      .toString();
  DirectionCounts counts(Map<String, Object?> value) => DirectionCounts(
    lower: value['lower']! as int,
    aligned: value['aligned']! as int,
    higher: value['higher']! as int,
  );
  final reference = ObservationReferenceType.values.firstWhere(
    (value) => value.code == hashInput['referenceType'],
  );
  return ShadowEvidencePackage(
    sourceModelIdentity: run.sourceModelIdentity,
    referenceType: reference,
    baseEnergy: 100,
    evidenceSnapshotJson: snapshot,
    evidenceHash: hash,
    currentValuesJson: '{"baseEnergy":100}',
    eligibleTotal: selected,
    selectedEligible: selected,
    excludedTotal: 0,
    missingToMinimum: 14 - selected,
    earliestLifeDay: LifeDay(2026, 7, 19),
    latestLifeDay: LifeDay(2026, 8, 14),
    directionCounts: counts(
      descriptive['directionCounts']! as Map<String, Object?>,
    ),
    windowDirectionCounts: const [],
    windowSizes: selected == 14 ? const [7, 7] : const [7, 6],
    exclusionCounts: const {},
    readiness: ShadowReadiness(
      hasMinimumCount: selected == 14,
      hasMinimumSpan: selected == 14,
      hasCompleteWindows: selected == 14,
      spanCalendarDays: selected == 14 ? 26 : 24,
    ),
  );
}
