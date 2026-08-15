import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/personalization_identity.dart';
import 'package:power_manager/domain/learning/personalization_lifecycle.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:test/test.dart';

void main() {
  const lifecycle = PersonalizationLifecycle();

  const allowed =
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

  for (final from in PersonalizationVersionStatus.values) {
    for (final to in PersonalizationVersionStatus.values) {
      if (from == to) continue;
      final legal = allowed[from]?.contains(to) ?? false;
      test('${from.code} -> ${to.code} is ${legal ? 'legal' : 'illegal'}', () {
        final source = _versionInStatus(from);
        PersonalizationVersion act() => lifecycle.transition(
          version: source,
          to: to,
          at: DateTime.utc(2026, 8, 16, 5),
          reason: 'truthTableTest',
          effectiveLifeDay: to == PersonalizationVersionStatus.scheduled
              ? LifeDay(2026, 8, 18)
              : null,
          scheduleSource: to == PersonalizationVersionStatus.scheduled
              ? PersonalizationScheduleSource.automatic
              : null,
        );

        if (!legal) {
          expect(act, throwsA(isA<PersonalizationLifecycleException>()));
          return;
        }
        final transitioned = act();
        expect(transitioned.status, to);
        expect(transitioned.id, source.id);
        expect(transitioned.modelRegimeEpoch, source.modelRegimeEpoch);
        expect(transitioned.transitionReason, 'truthTableTest');
        if (to == PersonalizationVersionStatus.scheduled) {
          expect(
            transitioned.scheduleSource,
            PersonalizationScheduleSource.automatic,
          );
          expect(transitioned.effectiveLifeDay, LifeDay(2026, 8, 18));
        }
        if (from == PersonalizationVersionStatus.scheduled &&
            to == PersonalizationVersionStatus.awaitingReview) {
          expect(transitioned.scheduleSource, isNull);
          expect(transitioned.effectiveLifeDay, isNull);
        }
      });
    }
  }

  test('schedule metadata never participates in deterministic version id', () {
    final candidate = _versionInStatus(PersonalizationVersionStatus.candidate);
    final scheduled = lifecycle.transition(
      version: candidate,
      to: PersonalizationVersionStatus.scheduled,
      at: DateTime.utc(2026, 8, 15, 12),
      reason: 'automaticCandidateScheduled',
      effectiveLifeDay: LifeDay(2026, 8, 17),
      scheduleSource: PersonalizationScheduleSource.automatic,
    );
    final reopened = lifecycle.transition(
      version: scheduled,
      to: PersonalizationVersionStatus.awaitingReview,
      at: DateTime.utc(2026, 8, 15, 13),
      reason: 'automaticDowngradedToReview',
    );

    expect(scheduled.id, candidate.id);
    expect(reopened.id, candidate.id);
    expect(scheduled.modelRegimeEpoch, candidate.modelRegimeEpoch);
    expect(reopened.modelRegimeEpoch, candidate.modelRegimeEpoch);
  });

  test(
    'integrity requires one root, one active and pending on that active',
    () {
      const validator = PersonalizationIntegrityValidator();
      final initial = initialPersonalizationVersion(
        baseEnergy: 100,
        createdAt: DateTime.utc(2026, 8, 1),
      );
      final candidate = _candidate(initial);
      expect(() => validator.validate([initial, candidate]), returnsNormally);

      expect(
        () => validator.validate([candidate]),
        throwsA(
          isA<PersonalizationLifecycleException>().having(
            (error) => error.code,
            'code',
            'activeCountNotOne',
          ),
        ),
      );

      final activeChild = _activate(_schedule(candidate));
      final endedInitial = lifecycle.transition(
        version: initial,
        to: PersonalizationVersionStatus.superseded,
        at: DateTime.utc(2026, 8, 3),
        reason: 'replacementActivated',
      );
      final stalePending = _candidate(
        initial,
        runId: 'stale-run',
        baseEnergy: 96,
      );
      expect(
        () => validator.validate([endedInitial, activeChild, stalePending]),
        throwsA(
          isA<PersonalizationLifecycleException>().having(
            (error) => error.code,
            'code',
            'invalidPendingParent',
          ),
        ),
      );
    },
  );

  test('unarranged and activated shapes reject stray schedule metadata', () {
    final candidate = _versionInStatus(PersonalizationVersionStatus.candidate);
    final malformedCandidate = _copy(
      candidate,
      scheduleSource: PersonalizationScheduleSource.automatic,
    );
    final active = _versionInStatus(PersonalizationVersionStatus.active);
    final malformedActive = _copy(
      active,
      scheduleSource: null,
      effectiveLifeDay: null,
    );

    expect(
      () => lifecycle.validateShape(malformedCandidate),
      throwsA(isA<PersonalizationLifecycleException>()),
    );
    expect(
      () => lifecycle.validateShape(malformedActive),
      throwsA(isA<PersonalizationLifecycleException>()),
    );
  });
}

PersonalizationVersion _versionInStatus(PersonalizationVersionStatus status) {
  final initial = initialPersonalizationVersion(
    baseEnergy: 100,
    createdAt: DateTime.utc(2026, 8, 1),
  );
  final candidate = _candidate(initial);
  final awaiting = const PersonalizationLifecycle().transition(
    version: candidate,
    to: PersonalizationVersionStatus.awaitingReview,
    at: DateTime.utc(2026, 8, 1, 1),
    reason: 'reviewCandidateAvailable',
  );
  final deferred = const PersonalizationLifecycle().transition(
    version: awaiting,
    to: PersonalizationVersionStatus.deferred,
    at: DateTime.utc(2026, 8, 1, 2),
    reason: 'reviewCandidateDeferred',
  );
  final scheduled = _schedule(candidate);
  final active = _activate(scheduled);
  return switch (status) {
    PersonalizationVersionStatus.candidate => candidate,
    PersonalizationVersionStatus.awaitingReview => awaiting,
    PersonalizationVersionStatus.deferred => deferred,
    PersonalizationVersionStatus.scheduled => scheduled,
    PersonalizationVersionStatus.active => active,
    PersonalizationVersionStatus.superseded =>
      const PersonalizationLifecycle().transition(
        version: active,
        to: PersonalizationVersionStatus.superseded,
        at: DateTime.utc(2026, 8, 4),
        reason: 'replacementActivated',
      ),
    PersonalizationVersionStatus.rejected =>
      const PersonalizationLifecycle().transition(
        version: awaiting,
        to: PersonalizationVersionStatus.rejected,
        at: DateTime.utc(2026, 8, 2),
        reason: 'reviewCandidateRejected',
      ),
    PersonalizationVersionStatus.reverted =>
      const PersonalizationLifecycle().transition(
        version: active,
        to: PersonalizationVersionStatus.reverted,
        at: DateTime.utc(2026, 8, 4),
        reason: 'futureRevertActivated',
      ),
    PersonalizationVersionStatus.canceled =>
      const PersonalizationLifecycle().transition(
        version: awaiting,
        to: PersonalizationVersionStatus.canceled,
        at: DateTime.utc(2026, 8, 2),
        reason: 'pendingChangeCanceledByUser',
      ),
    PersonalizationVersionStatus.invalidated =>
      const PersonalizationLifecycle().transition(
        version: candidate,
        to: PersonalizationVersionStatus.invalidated,
        at: DateTime.utc(2026, 8, 2),
        reason: 'candidateExpired',
      ),
  };
}

PersonalizationVersion _candidate(
  PersonalizationVersion parent, {
  String runId = 'candidate-run',
  int baseEnergy = 98,
}) {
  return learningPersonalizationVersion(
    parent: parent,
    sourceRun: LearningRun(
      id: runId,
      parameterFamily: LearningParameterFamily.baseline,
      sourceModelIdentity: 'source-model',
      sourcePersonalizationVersionId: parent.id,
      status: LearningRunStatus.completed,
      result: LearningRunResult.candidate,
      evidenceSnapshotJson: '{}',
      evidenceHash: List.filled(64, 'a').join(),
      evidenceHashVersion: canonicalEvidenceHashV1,
      algorithmVersion: 'baseline-production-v1',
      configVersion: 'baseline-production-config-v1',
      currentValuesJson: '{"baseEnergy":100}',
      candidateValuesJson: '{"baseEnergy":$baseEnergy}',
      reasonCodesJson: '["candidate"]',
      triggeredAt: DateTime.utc(2026, 8, 1),
      completedAt: DateTime.utc(2026, 8, 1, 0, 1),
    ),
    baseEnergy: baseEnergy,
    createdAt: DateTime.utc(2026, 8, 1, 0, 2),
    ruleVersion: 'energy-rules-v2-mvp-a',
  );
}

PersonalizationVersion _schedule(PersonalizationVersion candidate) {
  return const PersonalizationLifecycle().transition(
    version: candidate,
    to: PersonalizationVersionStatus.scheduled,
    at: DateTime.utc(2026, 8, 2),
    reason: 'automaticCandidateScheduled',
    effectiveLifeDay: LifeDay(2026, 8, 3),
    scheduleSource: PersonalizationScheduleSource.automatic,
  );
}

PersonalizationVersion _activate(PersonalizationVersion scheduled) {
  return const PersonalizationLifecycle().transition(
    version: scheduled,
    to: PersonalizationVersionStatus.active,
    at: DateTime.utc(2026, 8, 3, 4),
    reason: 'scheduledChangeActivated',
  );
}

PersonalizationVersion _copy(
  PersonalizationVersion value, {
  PersonalizationScheduleSource? scheduleSource,
  LifeDay? effectiveLifeDay,
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
    status: value.status,
    effectiveLifeDay: effectiveLifeDay,
    createdAt: value.createdAt,
    activatedAt: value.activatedAt,
    endedAt: value.endedAt,
    transitionReason: value.transitionReason,
  );
}
