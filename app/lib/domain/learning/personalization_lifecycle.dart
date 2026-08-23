import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

final class PersonalizationLifecycleException implements Exception {
  const PersonalizationLifecycleException(this.code);

  final String code;

  @override
  String toString() => code;
}

final class PersonalizationLifecycle {
  const PersonalizationLifecycle();

  static const _allowed =
      <PersonalizationVersionStatus, Set<PersonalizationVersionStatus>>{
        PersonalizationVersionStatus.candidate: {
          PersonalizationVersionStatus.awaitingReview,
          PersonalizationVersionStatus.scheduled,
          PersonalizationVersionStatus.invalidated,
        },
        PersonalizationVersionStatus.awaitingReview: {
          PersonalizationVersionStatus.deferred,
          PersonalizationVersionStatus.scheduled,
          PersonalizationVersionStatus.rejected,
          PersonalizationVersionStatus.canceled,
          PersonalizationVersionStatus.invalidated,
        },
        PersonalizationVersionStatus.deferred: {
          PersonalizationVersionStatus.awaitingReview,
          PersonalizationVersionStatus.rejected,
          PersonalizationVersionStatus.canceled,
          PersonalizationVersionStatus.invalidated,
        },
        PersonalizationVersionStatus.scheduled: {
          PersonalizationVersionStatus.active,
          PersonalizationVersionStatus.awaitingReview,
          PersonalizationVersionStatus.canceled,
          PersonalizationVersionStatus.invalidated,
        },
        PersonalizationVersionStatus.active: {
          PersonalizationVersionStatus.superseded,
          PersonalizationVersionStatus.reverted,
        },
      };

  PersonalizationVersion transition({
    required PersonalizationVersion version,
    required PersonalizationVersionStatus to,
    required DateTime at,
    required String reason,
    LifeDay? effectiveLifeDay,
    PersonalizationScheduleSource? scheduleSource,
  }) {
    if (!(_allowed[version.status]?.contains(to) ?? false)) {
      throw PersonalizationLifecycleException(
        'illegalTransition:${version.status.code}->${to.code}',
      );
    }
    if (reason.trim().isEmpty) {
      throw const PersonalizationLifecycleException('emptyTransitionReason');
    }
    final now = at.toUtc();
    if (now.isBefore(version.createdAt.toUtc())) {
      throw const PersonalizationLifecycleException('transitionBeforeCreate');
    }

    final scheduling = to == PersonalizationVersionStatus.scheduled;
    if (scheduling && (effectiveLifeDay == null || scheduleSource == null)) {
      throw const PersonalizationLifecycleException('missingScheduleShape');
    }
    final clearsSchedule =
        version.status == PersonalizationVersionStatus.scheduled &&
        to == PersonalizationVersionStatus.awaitingReview;
    final activates = to == PersonalizationVersionStatus.active;
    final ends = to.isTerminal;
    final result = _copy(
      version,
      status: to,
      scheduleSource: scheduling
          ? scheduleSource
          : clearsSchedule
          ? null
          : version.scheduleSource,
      effectiveLifeDay: scheduling
          ? effectiveLifeDay
          : clearsSchedule
          ? null
          : version.effectiveLifeDay,
      activatedAt: activates ? now : version.activatedAt,
      endedAt: ends ? now : version.endedAt,
      transitionReason: reason,
    );
    validateShape(result);
    return result;
  }

  void validateShape(PersonalizationVersion version) {
    if (version.id.trim().isEmpty ||
        version.effectiveModelFingerprint.trim().isEmpty ||
        version.modelRegimeEpoch.trim().isEmpty ||
        version.algorithmVersion.trim().isEmpty ||
        version.configVersion.trim().isEmpty ||
        version.transitionReason.trim().isEmpty ||
        version.baseEnergy < 60 ||
        version.baseEnergy > 140 ||
        version.baselineAnchorEnergy < 60 ||
        version.baselineAnchorEnergy > 140) {
      throw const PersonalizationLifecycleException('invalidCoreShape');
    }
    final initial =
        version.creationSource == PersonalizationCreationSource.initial;
    if (initial != (version.parentVersionId == null) ||
        (initial &&
            (version.scheduleSource != null ||
                version.sourceLearningRunId != null ||
                version.changedParameterFamily !=
                    PersonalizationChangedParameterFamily.none)) ||
        (!initial &&
            version.changedParameterFamily ==
                PersonalizationChangedParameterFamily.none)) {
      throw const PersonalizationLifecycleException('invalidSourceShape');
    }
    final learning =
        version.creationSource == PersonalizationCreationSource.learningRun;
    if (learning != (version.sourceLearningRunId != null)) {
      throw const PersonalizationLifecycleException('invalidLearningSource');
    }

    final unarranged = switch (version.status) {
      PersonalizationVersionStatus.candidate ||
      PersonalizationVersionStatus.awaitingReview ||
      PersonalizationVersionStatus.deferred =>
        version.scheduleSource == null &&
            version.effectiveLifeDay == null &&
            version.activatedAt == null &&
            version.endedAt == null,
      _ => true,
    };
    final scheduleShape =
        (version.scheduleSource == null) == (version.effectiveLifeDay == null);
    final scheduled =
        version.status != PersonalizationVersionStatus.scheduled ||
        (version.scheduleSource != null &&
            version.effectiveLifeDay != null &&
            version.activatedAt == null &&
            version.endedAt == null);
    final active =
        version.status != PersonalizationVersionStatus.active ||
        (version.activatedAt != null &&
            version.endedAt == null &&
            (initial ||
                (version.scheduleSource != null &&
                    version.effectiveLifeDay != null)));
    final activatedTerminal = switch (version.status) {
      PersonalizationVersionStatus.superseded ||
      PersonalizationVersionStatus.reverted =>
        version.activatedAt != null &&
            version.endedAt != null &&
            (initial ||
                (version.scheduleSource != null &&
                    version.effectiveLifeDay != null)),
      _ => true,
    };
    final inactiveTerminal = switch (version.status) {
      PersonalizationVersionStatus.rejected ||
      PersonalizationVersionStatus.canceled ||
      PersonalizationVersionStatus.invalidated =>
        version.activatedAt == null && version.endedAt != null,
      _ => true,
    };
    if (!unarranged ||
        !scheduleShape ||
        !scheduled ||
        !active ||
        !activatedTerminal ||
        !inactiveTerminal) {
      throw const PersonalizationLifecycleException('invalidStatusShape');
    }
    if (version.activatedAt case final activated?
        when activated.toUtc().isBefore(version.createdAt.toUtc())) {
      throw const PersonalizationLifecycleException('activationBeforeCreate');
    }
    if (version.endedAt case final ended?
        when ended.toUtc().isBefore(
          (version.activatedAt ?? version.createdAt).toUtc(),
        )) {
      throw const PersonalizationLifecycleException('endBeforeStart');
    }
  }

  PersonalizationVersion _copy(
    PersonalizationVersion value, {
    required PersonalizationVersionStatus status,
    required PersonalizationScheduleSource? scheduleSource,
    required LifeDay? effectiveLifeDay,
    required DateTime? activatedAt,
    required DateTime? endedAt,
    required String transitionReason,
  }) {
    return PersonalizationVersion(
      id: value.id,
      parentVersionId: value.parentVersionId,
      effectiveModelFingerprint: value.effectiveModelFingerprint,
      modelRegimeEpoch: value.modelRegimeEpoch,
      creationSource: value.creationSource,
      scheduleSource: scheduleSource,
      sourceLearningRunId: value.sourceLearningRunId,
      algorithmVersion: value.algorithmVersion,
      configVersion: value.configVersion,
      changedParameterFamily: value.changedParameterFamily,
      baseEnergy: value.baseEnergy,
      baselineAnchorEnergy: value.baselineAnchorEnergy,
      status: status,
      effectiveLifeDay: effectiveLifeDay,
      createdAt: value.createdAt,
      activatedAt: activatedAt,
      endedAt: endedAt,
      transitionReason: transitionReason,
    );
  }
}

final class PersonalizationIntegrityValidator {
  const PersonalizationIntegrityValidator({
    this.lifecycle = const PersonalizationLifecycle(),
  });

  final PersonalizationLifecycle lifecycle;

  void validate(List<PersonalizationVersion> versions) {
    final activeVersions = versions
        .where((item) => item.status == PersonalizationVersionStatus.active)
        .toList(growable: false);
    if (activeVersions.length != 1) {
      throw const PersonalizationLifecycleException('activeCountNotOne');
    }
    final initialVersions = versions
        .where(
          (item) =>
              item.creationSource == PersonalizationCreationSource.initial,
        )
        .toList(growable: false);
    if (initialVersions.length != 1) {
      throw const PersonalizationLifecycleException('initialCountNotOne');
    }
    if (versions.where((item) => item.status.isPending).length > 1) {
      throw const PersonalizationLifecycleException('pendingCountAboveOne');
    }
    final byId = <String, PersonalizationVersion>{};
    final epochs = <String>{};
    final sourceRuns = <String>{};
    for (final version in versions) {
      lifecycle.validateShape(version);
      if (byId.containsKey(version.id)) {
        throw const PersonalizationLifecycleException('duplicateVersionId');
      }
      byId[version.id] = version;
      if (!epochs.add(version.modelRegimeEpoch)) {
        throw const PersonalizationLifecycleException('duplicateRegimeEpoch');
      }
      if (version.sourceLearningRunId case final runId?
          when !sourceRuns.add(runId)) {
        throw const PersonalizationLifecycleException('duplicateSourceRun');
      }
    }
    final active = activeVersions.single;
    final initial = initialVersions.single;
    if (initial.status != PersonalizationVersionStatus.active &&
        initial.status != PersonalizationVersionStatus.superseded &&
        initial.status != PersonalizationVersionStatus.reverted) {
      throw const PersonalizationLifecycleException('invalidInitialStatus');
    }
    for (final version in versions) {
      final parentId = version.parentVersionId;
      if (parentId == null) continue;
      final parent = byId[parentId];
      if (parent == null || parent.createdAt.isAfter(version.createdAt)) {
        throw const PersonalizationLifecycleException('invalidParent');
      }
      final visited = <String>{version.id};
      PersonalizationVersion? cursor = parent;
      while (cursor != null) {
        if (!visited.add(cursor.id)) {
          throw const PersonalizationLifecycleException('parentCycle');
        }
        cursor = cursor.parentVersionId == null
            ? null
            : byId[cursor.parentVersionId!];
      }
      final baselineChanged =
          parent.baseEnergy != version.baseEnergy ||
          parent.baselineAnchorEnergy != version.baselineAnchorEnergy;
      if (version.changedParameterFamily ==
              PersonalizationChangedParameterFamily.baseline &&
          !baselineChanged &&
          version.creationSource !=
              PersonalizationCreationSource.legacyManualPending &&
          version.creationSource != PersonalizationCreationSource.revert) {
        throw const PersonalizationLifecycleException('baselineDidNotChange');
      }
      if (version.changedParameterFamily ==
              PersonalizationChangedParameterFamily.activityImpact &&
          baselineChanged) {
        throw const PersonalizationLifecycleException(
          'activityImpactChangedBaseline',
        );
      }
      final resetsBaselineAnchor = switch (version.creationSource) {
        PersonalizationCreationSource.manual ||
        PersonalizationCreationSource.legacyManualPending =>
          version.baselineAnchorEnergy == version.baseEnergy,
        PersonalizationCreationSource.learningRun ||
        PersonalizationCreationSource.revert =>
          version.baselineAnchorEnergy == parent.baselineAnchorEnergy,
        PersonalizationCreationSource.initial => true,
      };
      if (!resetsBaselineAnchor) {
        throw const PersonalizationLifecycleException('invalidBaselineAnchor');
      }
      final sourceShape = switch (version.creationSource) {
        PersonalizationCreationSource.manual =>
          version.scheduleSource == PersonalizationScheduleSource.manual,
        PersonalizationCreationSource.legacyManualPending =>
          version.scheduleSource ==
              PersonalizationScheduleSource.legacyManualPending,
        PersonalizationCreationSource.revert =>
          version.scheduleSource == PersonalizationScheduleSource.revert,
        PersonalizationCreationSource.learningRun =>
          version.scheduleSource == null ||
              version.scheduleSource ==
                  PersonalizationScheduleSource.automatic ||
              version.scheduleSource ==
                  PersonalizationScheduleSource.reviewAccepted,
        PersonalizationCreationSource.initial => true,
      };
      if (!sourceShape) {
        throw const PersonalizationLifecycleException('invalidScheduleSource');
      }
      if (version.status.isPending && version.parentVersionId != active.id) {
        throw const PersonalizationLifecycleException('invalidPendingParent');
      }
    }
  }
}
