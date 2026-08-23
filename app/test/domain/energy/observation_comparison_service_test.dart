import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/observation_comparison_service.dart';
import 'package:test/test.dart';

void main() {
  const service = ObservationComparisonService();

  test('maps all five actual states to explicit stable ordinals', () {
    final ordinals = [
      for (final state in AbsoluteEnergyState.values)
        service
            .compare(actualState: state, estimate: 100, initialEstimate: 100)
            .actualOrdinal,
    ];

    expect(ordinals, [0, 1, 2, 3, 4]);
  });

  test('uses strict integer boundaries for estimated ordinals', () {
    final cases = <int, int>{
      -1: 0,
      0: 1,
      24: 1,
      25: 2,
      49: 2,
      50: 3,
      79: 3,
      80: 4,
    };

    for (final entry in cases.entries) {
      final result = service.compare(
        actualState: AbsoluteEnergyState.okay,
        estimate: entry.key,
        initialEstimate: 100,
      );
      expect(
        result.estimatedOrdinal,
        entry.value,
        reason: 'estimate ${entry.key}',
      );
    }
    expect(
      service
          .compare(
            actualState: AbsoluteEnergyState.okay,
            estimate: 25,
            initialEstimate: 101,
          )
          .estimatedOrdinal,
      1,
    );
  });

  test('returns only ordinal delta and lower aligned higher direction', () {
    final lower = service.compare(
      actualState: AbsoluteEnergyState.low,
      estimate: 80,
      initialEstimate: 100,
    );
    final aligned = service.compare(
      actualState: AbsoluteEnergyState.full,
      estimate: 80,
      initialEstimate: 100,
    );
    final higher = service.compare(
      actualState: AbsoluteEnergyState.full,
      estimate: 25,
      initialEstimate: 100,
    );

    expect(lower.alignmentDelta, -3);
    expect(lower.direction, ObservationAlignmentDirection.lower);
    expect(aligned.alignmentDelta, 0);
    expect(aligned.direction, ObservationAlignmentDirection.aligned);
    expect(higher.alignmentDelta, 2);
    expect(higher.direction, ObservationAlignmentDirection.higher);
  });

  test('invalid initial estimate returns a stable integrity failure', () {
    for (final initial in [0, -1]) {
      final result = service.compare(
        actualState: AbsoluteEnergyState.good,
        estimate: 10,
        initialEstimate: initial,
      );
      expect(result.isValid, isFalse);
      expect(
        result.failure,
        ObservationComparisonFailure.invalidInitialEstimate,
      );
      expect(result.estimatedOrdinal, isNull);
      expect(result.alignmentDelta, isNull);
      expect(result.direction, isNull);
    }
  });
}
