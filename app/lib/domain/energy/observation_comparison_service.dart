import 'package:power_manager/domain/energy/energy_enums.dart';

enum ObservationAlignmentDirection {
  lower('lower'),
  aligned('aligned'),
  higher('higher');

  const ObservationAlignmentDirection(this.code);
  final String code;
}

enum ObservationComparisonFailure {
  invalidInitialEstimate('invalidInitialEstimate');

  const ObservationComparisonFailure(this.code);
  final String code;
}

final class ObservationComparisonResult {
  const ObservationComparisonResult._({
    required this.actualOrdinal,
    required this.estimatedOrdinal,
    required this.alignmentDelta,
    required this.direction,
    required this.failure,
  });

  const ObservationComparisonResult.success({
    required int actualOrdinal,
    required int estimatedOrdinal,
    required int alignmentDelta,
    required ObservationAlignmentDirection direction,
  }) : this._(
         actualOrdinal: actualOrdinal,
         estimatedOrdinal: estimatedOrdinal,
         alignmentDelta: alignmentDelta,
         direction: direction,
         failure: null,
       );

  const ObservationComparisonResult.invalidInitialEstimate({
    required int actualOrdinal,
  }) : this._(
         actualOrdinal: actualOrdinal,
         estimatedOrdinal: null,
         alignmentDelta: null,
         direction: null,
         failure: ObservationComparisonFailure.invalidInitialEstimate,
       );

  final int actualOrdinal;
  final int? estimatedOrdinal;
  final int? alignmentDelta;
  final ObservationAlignmentDirection? direction;
  final ObservationComparisonFailure? failure;

  bool get isValid => failure == null;
}

final class ObservationComparisonService {
  const ObservationComparisonService();

  ObservationComparisonResult compare({
    required AbsoluteEnergyState actualState,
    required int estimate,
    required int initialEstimate,
  }) {
    final actualOrdinal = switch (actualState) {
      AbsoluteEnergyState.exhausted => 0,
      AbsoluteEnergyState.low => 1,
      AbsoluteEnergyState.okay => 2,
      AbsoluteEnergyState.good => 3,
      AbsoluteEnergyState.full => 4,
    };
    if (initialEstimate <= 0) {
      return ObservationComparisonResult.invalidInitialEstimate(
        actualOrdinal: actualOrdinal,
      );
    }
    final estimatedOrdinal = switch (estimate) {
      < 0 => 0,
      _ when estimate * 4 < initialEstimate => 1,
      _ when estimate * 2 < initialEstimate => 2,
      _ when estimate * 5 < initialEstimate * 4 => 3,
      _ => 4,
    };
    final alignmentDelta = actualOrdinal - estimatedOrdinal;
    final direction = switch (alignmentDelta) {
      < 0 => ObservationAlignmentDirection.lower,
      0 => ObservationAlignmentDirection.aligned,
      _ => ObservationAlignmentDirection.higher,
    };
    return ObservationComparisonResult.success(
      actualOrdinal: actualOrdinal,
      estimatedOrdinal: estimatedOrdinal,
      alignmentDelta: alignmentDelta,
      direction: direction,
    );
  }
}
