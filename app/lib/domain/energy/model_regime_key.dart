import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';

final class ModelRegimeKeyBuilder {
  const ModelRegimeKeyBuilder();

  String build({
    required ObservationReferenceType referenceType,
    required int baseEnergy,
    required String ruleVersion,
    required String comparisonBandVersion,
    required String effectiveModelFingerprint,
    required String modelRegimeEpoch,
  }) {
    _requireNonEmpty(ruleVersion, 'ruleVersion');
    _requireNonEmpty(comparisonBandVersion, 'comparisonBandVersion');
    _requireNonEmpty(effectiveModelFingerprint, 'effectiveModelFingerprint');
    _requireNonEmpty(modelRegimeEpoch, 'modelRegimeEpoch');
    final canonical = jsonEncode(<String, Object>{
      'referenceType': referenceType.code,
      'baseEnergy': baseEnergy,
      'ruleVersion': ruleVersion,
      'comparisonBandVersion': comparisonBandVersion,
      'effectiveModelFingerprint': effectiveModelFingerprint,
      'modelRegimeEpoch': modelRegimeEpoch,
    });
    final digest = sha256.convert(utf8.encode(canonical));
    return '$mvpBModelRegimeKeyVersion:$digest';
  }

  void _requireNonEmpty(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, '$name must not be empty');
    }
  }
}
