import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:test/test.dart';

void main() {
  const builder = ModelRegimeKeyBuilder();

  test('matches the canonical model-regime-sha256-v1 fixture', () {
    final key = _build(builder, ObservationReferenceType.currentMoment);

    expect(
      key,
      'model-regime-sha256-v1:'
      '89ec781a43d8b3da4046f78da3a542884a49866c3e75c8db910eef09205c72c8',
    );
    expect(_build(builder, ObservationReferenceType.currentMoment), key);
  });

  test('reference type and every effective parameter isolate regimes', () {
    final current = _build(builder, ObservationReferenceType.currentMoment);
    expect(
      _build(builder, ObservationReferenceType.previousLifeDayEnd),
      isNot(current),
    );
    expect(
      builder.build(
        referenceType: ObservationReferenceType.currentMoment,
        baseEnergy: 101,
        ruleVersion: energyRulesV2MvpAVersion,
        comparisonBandVersion: mvpBComparisonBandV1,
        effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
        modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
      ),
      isNot(current),
    );
  });

  test('rejects empty identity components instead of creating collisions', () {
    expect(
      () => builder.build(
        referenceType: ObservationReferenceType.currentMoment,
        baseEnergy: 100,
        ruleVersion: '',
        comparisonBandVersion: mvpBComparisonBandV1,
        effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
        modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
      ),
      throwsArgumentError,
    );
  });
}

String _build(
  ModelRegimeKeyBuilder builder,
  ObservationReferenceType referenceType,
) {
  return builder.build(
    referenceType: referenceType,
    baseEnergy: 100,
    ruleVersion: energyRulesV2MvpAVersion,
    comparisonBandVersion: mvpBComparisonBandV1,
    effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
    modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
  );
}
