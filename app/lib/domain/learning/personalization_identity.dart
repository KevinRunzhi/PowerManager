import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

final class PersonalizationIdentityBuilder {
  const PersonalizationIdentityBuilder({
    this.canonicalEncoder = const CanonicalJsonEncoder(),
  });

  final CanonicalJsonEncoder canonicalEncoder;

  String versionId({
    required String? parentVersionId,
    required PersonalizationCreationSource creationSource,
    required String? sourceLearningRunId,
    required String algorithmVersion,
    required String configVersion,
    required PersonalizationChangedParameterFamily changedParameterFamily,
    required int baseEnergy,
    required int baselineAnchorEnergy,
    required DateTime createdAt,
  }) {
    final identity = canonicalEncoder.encode({
      'algorithmVersion': algorithmVersion,
      'baseEnergy': baseEnergy,
      'baselineAnchorEnergy': baselineAnchorEnergy,
      'changedParameterFamily': changedParameterFamily.code,
      'configVersion': configVersion,
      'createdAt': canonicalUtcIso8601Micros(createdAt),
      'creationSource': creationSource.code,
      'parentVersionId': parentVersionId,
      'sourceLearningRunId': sourceLearningRunId,
    });
    return '$deterministicPersonalizationVersionIdV1:${_hash(identity)}';
  }

  String effectiveFingerprint({
    required int baseEnergy,
    required String ruleVersion,
  }) {
    final identity = canonicalEncoder.encode({
      'activityFactors': const <Object?>[],
      'baseEnergy': baseEnergy,
      'fingerprintVersion': effectiveModelFingerprintV1,
      'ruleVersion': ruleVersion,
    });
    return '$effectiveModelFingerprintV1:${_hash(identity)}';
  }

  String regimeEpoch({required String versionId}) {
    final identity = canonicalEncoder.encode({
      'epochVersion': modelRegimeEpochV1,
      'personalizationVersionId': versionId,
    });
    return '$modelRegimeEpochV1:${_hash(identity)}';
  }

  String noticeDedupKey({
    required LearningParameterFamily parameterFamily,
    required LearningNoticeType type,
    required String? personalizationVersionId,
    required String? learningRunId,
    required String reasonCode,
  }) {
    return canonicalEncoder.encode({
      'learningRunId': learningRunId,
      'parameterFamily': parameterFamily.code,
      'personalizationVersionId': personalizationVersionId,
      'reasonCode': reasonCode,
      'type': type.code,
    });
  }

  String noticeId(String dedupKey) =>
      '$deterministicLearningNoticeIdV1:${_hash(dedupKey)}';

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();
}

PersonalizationVersion initialPersonalizationVersion({
  required int baseEnergy,
  required DateTime createdAt,
  String transitionReason = 'schemaV4InitialBridge',
  PersonalizationIdentityBuilder identities =
      const PersonalizationIdentityBuilder(),
}) {
  final utc = createdAt.toUtc();
  final id = identities.versionId(
    parentVersionId: null,
    creationSource: PersonalizationCreationSource.initial,
    sourceLearningRunId: null,
    algorithmVersion: initialPersonalizationAlgorithmV1,
    configVersion: initialPersonalizationConfigV1,
    changedParameterFamily: PersonalizationChangedParameterFamily.none,
    baseEnergy: baseEnergy,
    baselineAnchorEnergy: baseEnergy,
    createdAt: utc,
  );
  return PersonalizationVersion(
    id: id,
    parentVersionId: null,
    effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
    modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
    creationSource: PersonalizationCreationSource.initial,
    scheduleSource: null,
    sourceLearningRunId: null,
    algorithmVersion: initialPersonalizationAlgorithmV1,
    configVersion: initialPersonalizationConfigV1,
    changedParameterFamily: PersonalizationChangedParameterFamily.none,
    baseEnergy: baseEnergy,
    baselineAnchorEnergy: baseEnergy,
    status: PersonalizationVersionStatus.active,
    effectiveLifeDay: null,
    createdAt: utc,
    activatedAt: utc,
    endedAt: null,
    transitionReason: transitionReason,
  );
}

PersonalizationVersion scheduledManualPersonalizationVersion({
  required PersonalizationVersion parent,
  required int baseEnergy,
  required LifeDay effectiveLifeDay,
  required DateTime createdAt,
  required String ruleVersion,
  required bool legacy,
  PersonalizationIdentityBuilder identities =
      const PersonalizationIdentityBuilder(),
}) {
  final utc = createdAt.toUtc();
  final creationSource = legacy
      ? PersonalizationCreationSource.legacyManualPending
      : PersonalizationCreationSource.manual;
  final scheduleSource = legacy
      ? PersonalizationScheduleSource.legacyManualPending
      : PersonalizationScheduleSource.manual;
  final version = legacy
      ? legacyStage19PendingVersionV1
      : manualBaselineVersionV1;
  final id = identities.versionId(
    parentVersionId: parent.id,
    creationSource: creationSource,
    sourceLearningRunId: null,
    algorithmVersion: version,
    configVersion: version,
    changedParameterFamily: PersonalizationChangedParameterFamily.baseline,
    baseEnergy: baseEnergy,
    baselineAnchorEnergy: baseEnergy,
    createdAt: utc,
  );
  return PersonalizationVersion(
    id: id,
    parentVersionId: parent.id,
    effectiveModelFingerprint: identities.effectiveFingerprint(
      baseEnergy: baseEnergy,
      ruleVersion: ruleVersion,
    ),
    modelRegimeEpoch: identities.regimeEpoch(versionId: id),
    creationSource: creationSource,
    scheduleSource: scheduleSource,
    sourceLearningRunId: null,
    algorithmVersion: version,
    configVersion: version,
    changedParameterFamily: PersonalizationChangedParameterFamily.baseline,
    baseEnergy: baseEnergy,
    baselineAnchorEnergy: baseEnergy,
    status: PersonalizationVersionStatus.scheduled,
    effectiveLifeDay: effectiveLifeDay,
    createdAt: utc,
    activatedAt: null,
    endedAt: null,
    transitionReason: legacy
        ? 'legacyStage19PendingBridge'
        : 'manualBaselineScheduled',
  );
}

PersonalizationVersion learningPersonalizationVersion({
  required PersonalizationVersion parent,
  required LearningRun sourceRun,
  required int baseEnergy,
  required DateTime createdAt,
  required String ruleVersion,
  PersonalizationIdentityBuilder identities =
      const PersonalizationIdentityBuilder(),
}) {
  final utc = createdAt.toUtc();
  final family = switch (sourceRun.parameterFamily) {
    LearningParameterFamily.baseline =>
      PersonalizationChangedParameterFamily.baseline,
    LearningParameterFamily.activityImpact =>
      PersonalizationChangedParameterFamily.activityImpact,
  };
  final id = identities.versionId(
    parentVersionId: parent.id,
    creationSource: PersonalizationCreationSource.learningRun,
    sourceLearningRunId: sourceRun.id,
    algorithmVersion: sourceRun.algorithmVersion,
    configVersion: sourceRun.configVersion,
    changedParameterFamily: family,
    baseEnergy: baseEnergy,
    baselineAnchorEnergy: parent.baselineAnchorEnergy,
    createdAt: utc,
  );
  return PersonalizationVersion(
    id: id,
    parentVersionId: parent.id,
    effectiveModelFingerprint: identities.effectiveFingerprint(
      baseEnergy: baseEnergy,
      ruleVersion: ruleVersion,
    ),
    modelRegimeEpoch: identities.regimeEpoch(versionId: id),
    creationSource: PersonalizationCreationSource.learningRun,
    scheduleSource: null,
    sourceLearningRunId: sourceRun.id,
    algorithmVersion: sourceRun.algorithmVersion,
    configVersion: sourceRun.configVersion,
    changedParameterFamily: family,
    baseEnergy: baseEnergy,
    baselineAnchorEnergy: parent.baselineAnchorEnergy,
    status: PersonalizationVersionStatus.candidate,
    effectiveLifeDay: null,
    createdAt: utc,
    activatedAt: null,
    endedAt: null,
    transitionReason: 'learningCandidateCreated',
  );
}

PersonalizationVersion scheduledRevertPersonalizationVersion({
  required PersonalizationVersion parent,
  required PersonalizationVersion target,
  required LifeDay effectiveLifeDay,
  required DateTime createdAt,
  required String ruleVersion,
  PersonalizationIdentityBuilder identities =
      const PersonalizationIdentityBuilder(),
}) {
  final utc = createdAt.toUtc();
  final id = identities.versionId(
    parentVersionId: parent.id,
    creationSource: PersonalizationCreationSource.revert,
    sourceLearningRunId: null,
    algorithmVersion: revertPersonalizationVersionV1,
    configVersion: revertPersonalizationVersionV1,
    changedParameterFamily:
        target.changedParameterFamily ==
            PersonalizationChangedParameterFamily.activityImpact
        ? PersonalizationChangedParameterFamily.activityImpact
        : PersonalizationChangedParameterFamily.baseline,
    baseEnergy: target.baseEnergy,
    baselineAnchorEnergy: parent.baselineAnchorEnergy,
    createdAt: utc,
  );
  final family =
      target.changedParameterFamily ==
          PersonalizationChangedParameterFamily.activityImpact
      ? PersonalizationChangedParameterFamily.activityImpact
      : PersonalizationChangedParameterFamily.baseline;
  return PersonalizationVersion(
    id: id,
    parentVersionId: parent.id,
    effectiveModelFingerprint: identities.effectiveFingerprint(
      baseEnergy: target.baseEnergy,
      ruleVersion: ruleVersion,
    ),
    modelRegimeEpoch: identities.regimeEpoch(versionId: id),
    creationSource: PersonalizationCreationSource.revert,
    scheduleSource: PersonalizationScheduleSource.revert,
    sourceLearningRunId: null,
    algorithmVersion: revertPersonalizationVersionV1,
    configVersion: revertPersonalizationVersionV1,
    changedParameterFamily: family,
    baseEnergy: target.baseEnergy,
    baselineAnchorEnergy: parent.baselineAnchorEnergy,
    status: PersonalizationVersionStatus.scheduled,
    effectiveLifeDay: effectiveLifeDay,
    createdAt: utc,
    activatedAt: null,
    endedAt: null,
    transitionReason: 'revertScheduled',
  );
}
