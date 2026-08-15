import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/learning/baseline_shadow_replay.dart';

BaselineShadowReplayConfig b1PreproductionBaselineConfig({
  int step = 2,
  int anchorCumulativeLimit = 8,
  bool activationAllowed = false,
  String watermark = preproductionOnlyWatermark,
  List<ObservationReferenceType>? referencePriority,
}) {
  return BaselineShadowReplayConfig(
    algorithmVersion: 'baseline-shadow-replay-v1',
    configVersion: 'preprod-baseline-lifecycle-v1-do-not-ship',
    watermark: watermark,
    activationAllowed: activationAllowed,
    referencePriority:
        referencePriority ??
        const [
          ObservationReferenceType.currentMoment,
          ObservationReferenceType.previousLifeDayEnd,
        ],
    reviewThresholds: const BaselineDirectionThresholds(
      minimumSameDirectionPerWindow: 5,
      minimumSameDirectionTotal: 10,
      maximumOppositePerWindow: 1,
    ),
    automaticThresholds: const BaselineDirectionThresholds(
      minimumSameDirectionPerWindow: 6,
      minimumSameDirectionTotal: 12,
      maximumOppositePerWindow: 0,
    ),
    step: step,
    anchorCumulativeLimit: anchorCumulativeLimit,
    hardMinimum: 60,
    hardMaximum: 140,
    minimumCounterfactualAlignedGain: 1,
    minimumCounterfactualOrdinalErrorReduction: 1,
  );
}
