import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/personalization_identity.dart';
import 'package:power_manager/domain/learning/personalization_lifecycle.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

final class LearningProductionGate {
  const LearningProductionGate({
    required this.baselineProductionLearningEnabled,
    required this.activityImpactProductionLearningEnabled,
    this.automaticLearningEngineEnabled = false,
    this.baselineAutoApplyEnabled = false,
    this.activityImpactAutoApplyEnabled = false,
    this.isPreproductionValidationOverride = false,
    this.supportedBaselineAlgorithms = const {},
    this.supportedBaselineConfigs = const {},
  });

  const LearningProductionGate.closed()
    : baselineProductionLearningEnabled = false,
      activityImpactProductionLearningEnabled = false,
      automaticLearningEngineEnabled = false,
      baselineAutoApplyEnabled = false,
      activityImpactAutoApplyEnabled = false,
      isPreproductionValidationOverride = false,
      supportedBaselineAlgorithms = const {},
      supportedBaselineConfigs = const {};

  final bool baselineProductionLearningEnabled;
  final bool activityImpactProductionLearningEnabled;

  /// Master switch for generating production learning runs. Formal providers
  /// use [closed]; tests must opt in explicitly when exercising lifecycle.
  final bool automaticLearningEngineEnabled;
  final bool baselineAutoApplyEnabled;
  final bool activityImpactAutoApplyEnabled;
  final bool isPreproductionValidationOverride;
  final Set<String> supportedBaselineAlgorithms;
  final Set<String> supportedBaselineConfigs;

  bool allows(LearningParameterFamily family) => switch (family) {
    LearningParameterFamily.baseline => baselineProductionLearningEnabled,
    LearningParameterFamily.activityImpact =>
      activityImpactProductionLearningEnabled,
  };

  bool allowsAutoApply(LearningParameterFamily family) => switch (family) {
    LearningParameterFamily.baseline => baselineAutoApplyEnabled,
    LearningParameterFamily.activityImpact => activityImpactAutoApplyEnabled,
  };
}

final class ManualBaselineScheduleResult {
  const ManualBaselineScheduleResult({
    required this.version,
    required this.created,
  });

  final PersonalizationVersion version;
  final bool created;
}

final class ModelActivationResult {
  const ModelActivationResult({
    required this.activated,
    required this.version,
    required this.invalidationReason,
  });

  final bool activated;
  final PersonalizationVersion? version;
  final String? invalidationReason;
}

final class PersonalizationCandidateResult {
  const PersonalizationCandidateResult({
    required this.version,
    required this.created,
  });

  final PersonalizationVersion version;
  final bool created;
}

final class ModelActivationService {
  const ModelActivationService({
    required this.transactionRunner,
    required this.settings,
    required this.versions,
    required this.learningRuns,
    required this.consents,
    required this.notices,
    this.productionGate = const LearningProductionGate.closed(),
    this.lifecycle = const PersonalizationLifecycle(),
    this.integrity = const PersonalizationIntegrityValidator(),
    this.identities = const PersonalizationIdentityBuilder(),
  });

  final TransactionRunner transactionRunner;
  final AppSettingsRepository settings;
  final PersonalizationVersionsRepository versions;
  final LearningRunsRepository learningRuns;
  final LearningConsentsRepository consents;
  final LearningNoticesRepository notices;
  final LearningProductionGate productionGate;
  final PersonalizationLifecycle lifecycle;
  final PersonalizationIntegrityValidator integrity;
  final PersonalizationIdentityBuilder identities;

  static const minimumAutomaticNoticeDuration = Duration(hours: 24);
  static const maximumEvidenceAge = Duration(days: 45);
  static const maximumCandidateLifetime = Duration(days: 7);
  static const rejectedOrCanceledCooldown = Duration(days: 14);
  static const activatedCooldown = Duration(days: 21);
  static const revertedCooldown = Duration(days: 28);

  Future<AppSettings> changeLearningMode({
    required LearningParameterFamily parameterFamily,
    required LearningMode mode,
    required bool acceptCurrentDisclosure,
    required DateTime at,
  }) {
    return transactionRunner.run(() async {
      final current = await settings.get();
      final currentMode = _modeFor(current, parameterFamily);
      if (mode == currentMode) return current;
      if (mode != LearningMode.off) {
        if (!productionGate.allows(parameterFamily)) {
          throw StateError('productionLearningDisabled');
        }
        final disclosure = _disclosureFor(parameterFamily);
        var accepted = await consents.exists(
          parameterFamily: parameterFamily,
          disclosureVersion: disclosure,
        );
        if (!accepted && acceptCurrentDisclosure) {
          await consents.insert(
            LearningConsent(
              parameterFamily: parameterFamily,
              disclosureVersion: disclosure,
              acceptedAt: at.toUtc(),
            ),
          );
          accepted = true;
        }
        if (!accepted) throw StateError('learningDisclosureNotAccepted');
      }

      final pending = await versions.findPending();
      if (pending != null &&
          pending.changedParameterFamily.parameterFamily == parameterFamily) {
        PersonalizationVersion? transitioned;
        String? reason;
        if (mode == LearningMode.off) {
          final target =
              pending.status == PersonalizationVersionStatus.candidate
              ? PersonalizationVersionStatus.invalidated
              : PersonalizationVersionStatus.canceled;
          transitioned = lifecycle.transition(
            version: pending,
            to: target,
            at: at,
            reason: 'learningModeOff',
          );
          reason = 'learningModeOff';
        } else if (currentMode == LearningMode.automatic &&
            mode == LearningMode.review &&
            pending.status == PersonalizationVersionStatus.scheduled &&
            pending.scheduleSource == PersonalizationScheduleSource.automatic) {
          transitioned = lifecycle.transition(
            version: pending,
            to: PersonalizationVersionStatus.awaitingReview,
            at: at,
            reason: 'automaticDowngradedToReview',
          );
          reason = 'automaticDowngradedToReview';
        }
        if (transitioned != null) {
          if (!await versions.updateIfStatus(transitioned, pending.status)) {
            throw StateError('personalizationVersionChangedConcurrently');
          }
          await _insertNotice(
            parameterFamily: parameterFamily,
            type: LearningNoticeType.changeCanceled,
            versionId: pending.id,
            learningRunId: pending.sourceLearningRunId,
            reasonCode: reason!,
            at: at,
          );
        }
      }

      final updated = _copySettingsMode(
        current,
        parameterFamily: parameterFamily,
        mode: mode,
        updatedAt: at,
      );
      final withCooldown =
          pending != null &&
              pending.changedParameterFamily.parameterFamily ==
                  parameterFamily &&
              mode == LearningMode.off
          ? _copySettingsCooldown(
              updated,
              parameterFamily: parameterFamily,
              cooldownUntil: at.toUtc().add(rejectedOrCanceledCooldown),
              updatedAt: at,
            )
          : updated;
      await settings.save(withCooldown);
      await _validateAll();
      return withCooldown;
    });
  }

  Future<PersonalizationCandidateResult> registerLearningCandidate({
    required LearningRun run,
    required LifeDay currentLifeDay,
    required DateTime atLocal,
    required String ruleVersion,
  }) {
    return transactionRunner.run(() async {
      final existing = (await versions.list())
          .where((version) => version.sourceLearningRunId == run.id)
          .firstOrNull;
      if (existing != null) {
        return PersonalizationCandidateResult(
          version: existing,
          created: false,
        );
      }
      final persistedRun = await learningRuns.find(run.id);
      if (persistedRun == null || !_sameLearningRun(persistedRun, run)) {
        throw StateError('sourceLearningRunNotPersisted');
      }
      if (run.parameterFamily != LearningParameterFamily.baseline) {
        throw StateError('activityImpactModelNotImplemented');
      }
      final now = atLocal.toUtc();
      final appSettings = await settings.get();
      final mode = _modeFor(appSettings, run.parameterFamily);
      _requireLearningEnabled(
        appSettings,
        parameterFamily: run.parameterFamily,
        mode: mode,
        at: now,
      );
      if (!await consents.exists(
        parameterFamily: run.parameterFamily,
        disclosureVersion: _disclosureFor(run.parameterFamily),
      )) {
        throw StateError('learningDisclosureNotAccepted');
      }
      final active = await versions.getActive();
      final candidateBase = _validateCandidateRun(
        run,
        active: active,
        activeRuleVersion: ruleVersion,
        at: now,
      );
      final pending = await versions.findPending();
      if (pending != null) throw StateError('pendingPersonalizationExists');
      if ((candidateBase - active.baselineAnchorEnergy).abs() > 8) {
        throw StateError('candidateOutsideAnchorBoundary');
      }

      var candidate = learningPersonalizationVersion(
        parent: active,
        sourceRun: run,
        baseEnergy: candidateBase,
        createdAt: now,
        ruleVersion: ruleVersion,
        identities: identities,
      );
      final LearningNoticeType noticeType;
      final String noticeReason;
      switch (mode) {
        case LearningMode.off:
          throw StateError('learningModeOff');
        case LearningMode.review:
          candidate = lifecycle.transition(
            version: candidate,
            to: PersonalizationVersionStatus.awaitingReview,
            at: now,
            reason: 'reviewCandidateAvailable',
          );
          noticeType = LearningNoticeType.candidateAvailable;
          noticeReason = 'reviewCandidateAvailable';
        case LearningMode.automatic:
          if (!productionGate.allowsAutoApply(run.parameterFamily)) {
            throw StateError('automaticApplyDisabled');
          }
          candidate = lifecycle.transition(
            version: candidate,
            to: PersonalizationVersionStatus.scheduled,
            at: now,
            reason: 'automaticCandidateScheduled',
            effectiveLifeDay: earliestAutomaticEffectiveLifeDay(
              currentLifeDay: currentLifeDay,
              atLocal: atLocal,
            ),
            scheduleSource: PersonalizationScheduleSource.automatic,
          );
          noticeType = LearningNoticeType.changeScheduled;
          noticeReason = 'automaticCandidateScheduled';
      }
      await versions.insert(candidate);
      await _insertNotice(
        parameterFamily: run.parameterFamily,
        type: noticeType,
        versionId: candidate.id,
        learningRunId: run.id,
        reasonCode: noticeReason,
        at: now,
      );
      await _validateAll();
      return PersonalizationCandidateResult(version: candidate, created: true);
    });
  }

  LifeDay earliestAutomaticEffectiveLifeDay({
    required LifeDay currentLifeDay,
    required DateTime atLocal,
  }) {
    final local = atLocal.isUtc ? atLocal.toLocal() : atLocal;
    var candidate = currentLifeDay.next;
    while (DateTime(
          candidate.year,
          candidate.month,
          candidate.day,
          4,
        ).toUtc().difference(local.toUtc()) <
        minimumAutomaticNoticeDuration) {
      candidate = candidate.next;
    }
    return candidate;
  }

  Future<PersonalizationVersion> acceptReviewCandidate({
    required String versionId,
    required LifeDay currentLifeDay,
    required LifeDay effectiveLifeDay,
    required DateTime at,
  }) {
    if (effectiveLifeDay.compareTo(currentLifeDay) <= 0) {
      throw StateError('effectiveLifeDayNotFuture');
    }
    return transactionRunner.run(() async {
      final candidate = await _requirePendingVersion(versionId);
      if (candidate.status != PersonalizationVersionStatus.awaitingReview) {
        throw StateError('candidateNotReviewable');
      }
      final expired = await _invalidateIfExpired(candidate, at);
      if (expired != null) return expired;
      final family = candidate.changedParameterFamily.parameterFamily!;
      final appSettings = await settings.get();
      final mode = _modeFor(appSettings, family);
      _requireLearningEnabled(
        appSettings,
        parameterFamily: family,
        mode: mode,
        at: at,
      );
      if (!await consents.exists(
        parameterFamily: family,
        disclosureVersion: _disclosureFor(family),
      )) {
        throw StateError('learningDisclosureNotAccepted');
      }
      final run = await learningRuns.find(candidate.sourceLearningRunId!);
      if (run == null) throw StateError('sourceLearningRunMissing');
      final candidateBase = _validateCandidateRun(
        run,
        active: await versions.getActive(),
        activeRuleVersion: appSettings.activeRuleVersion,
        at: at.toUtc(),
      );
      if (candidateBase != candidate.baseEnergy) {
        throw StateError('candidateValuesChanged');
      }
      final scheduled = lifecycle.transition(
        version: candidate,
        to: PersonalizationVersionStatus.scheduled,
        at: at,
        reason: 'reviewCandidateAccepted',
        effectiveLifeDay: effectiveLifeDay,
        scheduleSource: PersonalizationScheduleSource.reviewAccepted,
      );
      await _updateConditionally(scheduled, candidate.status);
      await _insertNotice(
        parameterFamily: family,
        type: LearningNoticeType.changeScheduled,
        versionId: candidate.id,
        learningRunId: candidate.sourceLearningRunId,
        reasonCode: 'reviewCandidateAccepted',
        at: at,
      );
      await _validateAll();
      return scheduled;
    });
  }

  Future<PersonalizationVersion> deferReviewCandidate({
    required String versionId,
    required DateTime at,
  }) {
    return transactionRunner.run(() async {
      final candidate = await _requirePendingVersion(versionId);
      if (candidate.status != PersonalizationVersionStatus.awaitingReview) {
        throw StateError('candidateNotAwaitingReview');
      }
      final deferred = lifecycle.transition(
        version: candidate,
        to: PersonalizationVersionStatus.deferred,
        at: at,
        reason: 'reviewCandidateDeferred',
      );
      await _updateConditionally(deferred, candidate.status);
      await _validateAll();
      return deferred;
    });
  }

  Future<PersonalizationVersion> reopenDeferredCandidate({
    required String versionId,
    required DateTime at,
  }) {
    return transactionRunner.run(() async {
      final candidate = await _requirePendingVersion(versionId);
      if (candidate.status != PersonalizationVersionStatus.deferred) {
        throw StateError('candidateNotDeferred');
      }
      final expired = await _invalidateIfExpired(candidate, at);
      if (expired != null) return expired;
      final reopened = lifecycle.transition(
        version: candidate,
        to: PersonalizationVersionStatus.awaitingReview,
        at: at,
        reason: 'deferredCandidateReopened',
      );
      await _updateConditionally(reopened, candidate.status);
      await _validateAll();
      return reopened;
    });
  }

  Future<PersonalizationVersion> rejectReviewCandidate({
    required String versionId,
    required DateTime at,
  }) {
    return transactionRunner.run(() async {
      final candidate = await _requirePendingVersion(versionId);
      if (candidate.status != PersonalizationVersionStatus.awaitingReview &&
          candidate.status != PersonalizationVersionStatus.deferred) {
        throw StateError('candidateNotRejectable');
      }
      final rejected = lifecycle.transition(
        version: candidate,
        to: PersonalizationVersionStatus.rejected,
        at: at,
        reason: 'reviewCandidateRejected',
      );
      await _updateConditionally(rejected, candidate.status);
      final family = candidate.changedParameterFamily.parameterFamily!;
      await settings.save(
        _copySettingsCooldown(
          await settings.get(),
          parameterFamily: family,
          cooldownUntil: at.toUtc().add(rejectedOrCanceledCooldown),
          updatedAt: at,
        ),
      );
      await _insertNotice(
        parameterFamily: family,
        type: LearningNoticeType.changeCanceled,
        versionId: candidate.id,
        learningRunId: candidate.sourceLearningRunId,
        reasonCode: 'reviewCandidateRejected',
        at: at,
      );
      await _validateAll();
      return rejected;
    });
  }

  Future<PersonalizationVersion> cancelPendingChange({
    required String versionId,
    required DateTime at,
  }) {
    return transactionRunner.run(() async {
      final pending = await _requirePendingVersion(versionId);
      final target = pending.status == PersonalizationVersionStatus.candidate
          ? PersonalizationVersionStatus.invalidated
          : PersonalizationVersionStatus.canceled;
      final canceled = lifecycle.transition(
        version: pending,
        to: target,
        at: at,
        reason: 'pendingChangeCanceledByUser',
      );
      await _updateConditionally(canceled, pending.status);
      final family = pending.changedParameterFamily.parameterFamily!;
      await settings.save(
        _copySettingsCooldown(
          await settings.get(),
          parameterFamily: family,
          cooldownUntil: at.toUtc().add(rejectedOrCanceledCooldown),
          updatedAt: at,
        ),
      );
      await _insertNotice(
        parameterFamily: family,
        type: LearningNoticeType.changeCanceled,
        versionId: pending.id,
        learningRunId: pending.sourceLearningRunId,
        reasonCode: 'pendingChangeCanceledByUser',
        at: at,
      );
      await _validateAll();
      return canceled;
    });
  }

  Future<PersonalizationVersion> scheduleRevert({
    required String targetVersionId,
    required LifeDay currentLifeDay,
    required LifeDay effectiveLifeDay,
    required DateTime at,
  }) {
    if (effectiveLifeDay.compareTo(currentLifeDay) <= 0) {
      throw StateError('effectiveLifeDayNotFuture');
    }
    return transactionRunner.run(() async {
      if (await versions.findPending() != null) {
        throw StateError('pendingPersonalizationExists');
      }
      final active = await versions.getActive();
      final target = await versions.find(targetVersionId);
      if (target == null ||
          target.id == active.id ||
          target.activatedAt == null) {
        throw StateError('invalidRevertTarget');
      }
      if (!_isAncestor(target.id, active.id, await versions.list())) {
        throw StateError('revertTargetNotAncestor');
      }
      final appSettings = await settings.get();
      final scheduled = scheduledRevertPersonalizationVersion(
        parent: active,
        target: target,
        effectiveLifeDay: effectiveLifeDay,
        createdAt: at,
        ruleVersion: appSettings.activeRuleVersion,
        identities: identities,
      );
      lifecycle.validateShape(scheduled);
      await versions.insert(scheduled);
      await _insertNotice(
        parameterFamily: scheduled.changedParameterFamily.parameterFamily!,
        type: LearningNoticeType.changeScheduled,
        versionId: scheduled.id,
        learningRunId: null,
        reasonCode: 'revertScheduled',
        at: at,
      );
      await _validateAll();
      return scheduled;
    });
  }

  Future<AppSettings> suspendLearning({
    required LearningParameterFamily parameterFamily,
    required String learningRunId,
    required String reasonCode,
    required DateTime at,
  }) {
    if (reasonCode.trim().isEmpty) throw StateError('emptySuspensionReason');
    return transactionRunner.run(() async {
      final current = await settings.get();
      final alreadySuspended =
          parameterFamily == LearningParameterFamily.baseline
          ? current.baselineLearningSuspended
          : current.activityImpactLearningSuspended;
      if (alreadySuspended) return current;
      final run = await learningRuns.find(learningRunId);
      final active = await versions.getActive();
      if (run == null ||
          run.status != LearningRunStatus.completed ||
          run.result != LearningRunResult.worsened ||
          run.parameterFamily != parameterFamily ||
          run.sourcePersonalizationVersionId != active.id) {
        throw StateError('invalidWorsenedLearningRun');
      }
      final pending = await versions.findPending();
      if (pending != null &&
          pending.changedParameterFamily.parameterFamily == parameterFamily) {
        final invalidated = lifecycle.transition(
          version: pending,
          to: PersonalizationVersionStatus.invalidated,
          at: at,
          reason: 'learningSuspended',
        );
        await _updateConditionally(invalidated, pending.status);
      }
      final updated = _copySettingsSuspension(
        current,
        parameterFamily: parameterFamily,
        suspended: true,
        suspendedAt: at,
        reason: reasonCode,
        updatedAt: at,
      );
      await settings.save(updated);
      await _insertNotice(
        parameterFamily: parameterFamily,
        type: LearningNoticeType.learningSuspended,
        versionId: active.id,
        learningRunId: run.id,
        reasonCode: reasonCode,
        at: at,
      );
      await _validateAll();
      return updated;
    });
  }

  Future<AppSettings> resumeLearning({
    required LearningParameterFamily parameterFamily,
    required DateTime at,
  }) {
    return transactionRunner.run(() async {
      final current = await settings.get();
      final suspended = parameterFamily == LearningParameterFamily.baseline
          ? current.baselineLearningSuspended
          : current.activityImpactLearningSuspended;
      if (!suspended) return current;
      if (_modeFor(current, parameterFamily) == LearningMode.off ||
          !productionGate.allows(parameterFamily)) {
        throw StateError('learningCannotResume');
      }
      final updated = _copySettingsSuspension(
        current,
        parameterFamily: parameterFamily,
        suspended: false,
        suspendedAt: null,
        reason: null,
        updatedAt: at,
      );
      await settings.save(updated);
      await _validateAll();
      return updated;
    });
  }

  Future<ManualBaselineScheduleResult> scheduleManualBaseline({
    required int baseEnergy,
    required LifeDay currentLifeDay,
    required LifeDay effectiveLifeDay,
    required DateTime at,
    required String ruleVersion,
  }) {
    if (baseEnergy < 60 || baseEnergy > 140) {
      throw RangeError.range(baseEnergy, 60, 140, 'baseEnergy');
    }
    if (effectiveLifeDay.compareTo(currentLifeDay) <= 0) {
      throw StateError('effectiveLifeDayNotFuture');
    }
    return transactionRunner.run(() async {
      final active = await versions.getActive();
      final pending = await versions.findPending();
      final sameManualSchedule =
          pending != null &&
          pending.status == PersonalizationVersionStatus.scheduled &&
          pending.changedParameterFamily ==
              PersonalizationChangedParameterFamily.baseline &&
          (pending.scheduleSource == PersonalizationScheduleSource.manual ||
              pending.scheduleSource ==
                  PersonalizationScheduleSource.legacyManualPending) &&
          pending.baseEnergy == baseEnergy &&
          pending.effectiveLifeDay == effectiveLifeDay;
      if (sameManualSchedule) {
        await _validateAll();
        return ManualBaselineScheduleResult(version: pending, created: false);
      }
      if (pending != null) {
        if (pending.changedParameterFamily !=
            PersonalizationChangedParameterFamily.baseline) {
          throw StateError('pendingOtherParameterFamily');
        }
        final invalidated = lifecycle.transition(
          version: pending,
          to: PersonalizationVersionStatus.invalidated,
          at: at,
          reason: 'manualBaselineConflict',
        );
        if (!await versions.updateIfStatus(invalidated, pending.status)) {
          throw StateError('personalizationVersionChangedConcurrently');
        }
        await _insertNotice(
          parameterFamily: LearningParameterFamily.baseline,
          type: LearningNoticeType.changeCanceled,
          versionId: pending.id,
          learningRunId: pending.sourceLearningRunId,
          reasonCode: 'manualBaselineConflict',
          at: at,
        );
      }
      if (active.baseEnergy == baseEnergy) {
        if (pending != null) {
          await settings.save(
            _copySettingsCooldown(
              await settings.get(),
              parameterFamily: LearningParameterFamily.baseline,
              cooldownUntil: at.toUtc().add(activatedCooldown),
              updatedAt: at,
            ),
          );
        }
        await _validateAll();
        return ManualBaselineScheduleResult(version: active, created: false);
      }
      await settings.save(
        _copySettingsCooldown(
          await settings.get(),
          parameterFamily: LearningParameterFamily.baseline,
          cooldownUntil: at.toUtc().add(activatedCooldown),
          updatedAt: at,
        ),
      );
      final scheduled = scheduledManualPersonalizationVersion(
        parent: active,
        baseEnergy: baseEnergy,
        effectiveLifeDay: effectiveLifeDay,
        createdAt: at,
        ruleVersion: ruleVersion,
        legacy: false,
        identities: identities,
      );
      lifecycle.validateShape(scheduled);
      await versions.insert(scheduled);
      await _insertNotice(
        parameterFamily: LearningParameterFamily.baseline,
        type: LearningNoticeType.changeScheduled,
        versionId: scheduled.id,
        learningRunId: null,
        reasonCode: 'manualBaselineScheduled',
        at: at,
      );
      await _validateAll();
      return ManualBaselineScheduleResult(version: scheduled, created: true);
    });
  }

  Future<ModelActivationResult> activateDue({
    required LifeDay currentLifeDay,
    required DateTime at,
    bool afterRestore = false,
  }) {
    return transactionRunner.run(() async {
      final pending = await versions.findPending();
      if (pending == null ||
          pending.status != PersonalizationVersionStatus.scheduled) {
        await _validateAll();
        return const ModelActivationResult(
          activated: false,
          version: null,
          invalidationReason: null,
        );
      }
      final automatic =
          pending.scheduleSource == PersonalizationScheduleSource.automatic;
      final due = pending.effectiveLifeDay!.compareTo(currentLifeDay) <= 0;
      String? earlyInvalidationReason;
      if (_isExpired(pending, at) &&
          pending.creationSource == PersonalizationCreationSource.learningRun) {
        earlyInvalidationReason = 'candidateExpired';
      } else if (afterRestore && automatic && due) {
        earlyInvalidationReason = 'automaticRestoreDueOrMissed';
      }
      if (earlyInvalidationReason != null) {
        return _invalidateScheduled(
          pending,
          reason: earlyInvalidationReason,
          at: at,
        );
      }
      if (!due) {
        await _validateAll();
        return const ModelActivationResult(
          activated: false,
          version: null,
          invalidationReason: null,
        );
      }
      final invalidReason = await _activationInvalidationReason(pending, at);
      if (invalidReason != null) {
        return _invalidateScheduled(pending, reason: invalidReason, at: at);
      }

      final active = await versions.getActive();
      final oldTerminal =
          pending.scheduleSource == PersonalizationScheduleSource.revert
          ? PersonalizationVersionStatus.reverted
          : PersonalizationVersionStatus.superseded;
      final ended = lifecycle.transition(
        version: active,
        to: oldTerminal,
        at: at,
        reason: pending.scheduleSource == PersonalizationScheduleSource.revert
            ? 'futureRevertActivated'
            : 'replacementActivated',
      );
      if (!await versions.updateIfStatus(
        ended,
        PersonalizationVersionStatus.active,
      )) {
        throw StateError('activePersonalizationVersionChangedConcurrently');
      }
      final activated = lifecycle.transition(
        version: pending,
        to: PersonalizationVersionStatus.active,
        at: at,
        reason: 'scheduledChangeActivated',
      );
      if (!await versions.updateIfStatus(
        activated,
        PersonalizationVersionStatus.scheduled,
      )) {
        throw StateError('scheduledPersonalizationVersionChangedConcurrently');
      }
      await _insertNotice(
        parameterFamily: pending.changedParameterFamily.parameterFamily!,
        type: pending.scheduleSource == PersonalizationScheduleSource.revert
            ? LearningNoticeType.changeReverted
            : LearningNoticeType.changeActivated,
        versionId: pending.id,
        learningRunId: pending.sourceLearningRunId,
        reasonCode: 'scheduledChangeActivated',
        at: at,
      );
      await settings.save(
        _copySettingsCooldown(
          await settings.get(),
          parameterFamily: pending.changedParameterFamily.parameterFamily!,
          cooldownUntil: at.toUtc().add(
            pending.scheduleSource == PersonalizationScheduleSource.revert
                ? revertedCooldown
                : activatedCooldown,
          ),
          updatedAt: at,
        ),
      );
      await _validateAll();
      return ModelActivationResult(
        activated: true,
        version: activated,
        invalidationReason: null,
      );
    });
  }

  Future<String?> _activationInvalidationReason(
    PersonalizationVersion scheduled,
    DateTime at,
  ) async {
    final active = await versions.getActive();
    if (scheduled.parentVersionId != active.id) return 'sourceModelChanged';
    final source = scheduled.scheduleSource!;
    if (source != PersonalizationScheduleSource.legacyManualPending &&
        !await _hasValidScheduleNotice(scheduled)) {
      return 'missingScheduledNotice';
    }
    if (source == PersonalizationScheduleSource.manual ||
        source == PersonalizationScheduleSource.legacyManualPending ||
        source == PersonalizationScheduleSource.revert) {
      return null;
    }

    final family = scheduled.changedParameterFamily.parameterFamily!;
    final appSettings = await settings.get();
    final mode = family == LearningParameterFamily.baseline
        ? appSettings.baselineLearningMode
        : appSettings.activityImpactLearningMode;
    try {
      _requireLearningEnabled(
        appSettings,
        parameterFamily: family,
        mode: mode,
        at: at,
      );
    } on StateError catch (error) {
      return error.message.toString();
    }
    if (!await consents.exists(
      parameterFamily: family,
      disclosureVersion: _disclosureFor(family),
    )) {
      return 'learningDisclosureNotAccepted';
    }
    if (source == PersonalizationScheduleSource.automatic &&
        mode != LearningMode.automatic) {
      return 'automaticModeChanged';
    }
    if (source == PersonalizationScheduleSource.automatic &&
        !await _hasMinimumAutomaticNotice(scheduled)) {
      return 'automaticNoticeTooShort';
    }
    if (source == PersonalizationScheduleSource.reviewAccepted &&
        mode == LearningMode.off) {
      return 'reviewModeChanged';
    }
    final runId = scheduled.sourceLearningRunId;
    final run = runId == null ? null : await learningRuns.find(runId);
    if (run == null) {
      return 'sourceLearningRunInvalid';
    }
    try {
      final candidateBase = _validateCandidateRun(
        run,
        active: active,
        activeRuleVersion: appSettings.activeRuleVersion,
        at: at.toUtc(),
      );
      if (candidateBase != scheduled.baseEnergy) {
        return 'candidateValuesChanged';
      }
    } on StateError catch (error) {
      return error.message.toString();
    }
    return null;
  }

  Future<ModelActivationResult> _invalidateScheduled(
    PersonalizationVersion pending, {
    required String reason,
    required DateTime at,
  }) async {
    final invalidated = lifecycle.transition(
      version: pending,
      to: PersonalizationVersionStatus.invalidated,
      at: at,
      reason: reason,
    );
    await _updateConditionally(
      invalidated,
      PersonalizationVersionStatus.scheduled,
    );
    await _insertNotice(
      parameterFamily: pending.changedParameterFamily.parameterFamily!,
      type: LearningNoticeType.changeCanceled,
      versionId: pending.id,
      learningRunId: pending.sourceLearningRunId,
      reasonCode: reason,
      at: at,
    );
    await _validateAll();
    return ModelActivationResult(
      activated: false,
      version: invalidated,
      invalidationReason: reason,
    );
  }

  Future<PersonalizationVersion?> _invalidateIfExpired(
    PersonalizationVersion candidate,
    DateTime at,
  ) async {
    if (!_isExpired(candidate, at)) return null;
    final invalidated = lifecycle.transition(
      version: candidate,
      to: PersonalizationVersionStatus.invalidated,
      at: at,
      reason: 'candidateExpired',
    );
    await _updateConditionally(invalidated, candidate.status);
    await _insertNotice(
      parameterFamily: candidate.changedParameterFamily.parameterFamily!,
      type: LearningNoticeType.changeCanceled,
      versionId: candidate.id,
      learningRunId: candidate.sourceLearningRunId,
      reasonCode: 'candidateExpired',
      at: at,
    );
    await _validateAll();
    return invalidated;
  }

  bool _isExpired(PersonalizationVersion version, DateTime at) {
    return !at.toUtc().isBefore(
      version.createdAt.toUtc().add(maximumCandidateLifetime),
    );
  }

  Future<bool> _hasMinimumAutomaticNotice(
    PersonalizationVersion version,
  ) async {
    final notice = await _scheduleNotice(version);
    if (notice == null) return false;
    final day = version.effectiveLifeDay!;
    final boundary = DateTime(day.year, day.month, day.day, 4).toUtc();
    return boundary.difference(notice.createdAt.toUtc()) >=
        minimumAutomaticNoticeDuration;
  }

  Future<bool> _hasValidScheduleNotice(PersonalizationVersion version) async =>
      await _scheduleNotice(version) != null;

  Future<LearningNotice?> _scheduleNotice(
    PersonalizationVersion version,
  ) async {
    return (await notices.list())
        .where(
          (notice) =>
              notice.type == LearningNoticeType.changeScheduled &&
              notice.personalizationVersionId == version.id &&
              notice.parameterFamily ==
                  version.changedParameterFamily.parameterFamily &&
              notice.learningRunId == version.sourceLearningRunId &&
              !notice.createdAt.toUtc().isBefore(version.createdAt.toUtc()),
        )
        .firstOrNull;
  }

  Future<PersonalizationVersion> _requirePendingVersion(String id) async {
    final version = await versions.find(id);
    if (version == null || !version.status.isPending) {
      throw StateError('pendingPersonalizationNotFound');
    }
    return version;
  }

  Future<void> _updateConditionally(
    PersonalizationVersion version,
    PersonalizationVersionStatus expectedStatus,
  ) async {
    if (!await versions.updateIfStatus(version, expectedStatus)) {
      throw StateError('personalizationVersionChangedConcurrently');
    }
  }

  void _requireLearningEnabled(
    AppSettings value, {
    required LearningParameterFamily parameterFamily,
    required LearningMode mode,
    required DateTime at,
  }) {
    if (!productionGate.allows(parameterFamily)) {
      throw StateError('productionGateClosed');
    }
    if (!productionGate.automaticLearningEngineEnabled) {
      throw StateError('automaticLearningEngineDisabled');
    }
    if (mode == LearningMode.off) throw StateError('learningModeOff');
    final suspended = parameterFamily == LearningParameterFamily.baseline
        ? value.baselineLearningSuspended
        : value.activityImpactLearningSuspended;
    if (suspended) throw StateError('learningSuspended');
    final cooldown = parameterFamily == LearningParameterFamily.baseline
        ? value.baselineLearningCooldownUntil
        : value.activityImpactLearningCooldownUntil;
    if (cooldown != null && cooldown.toUtc().isAfter(at.toUtc())) {
      throw StateError('learningCooldownActive');
    }
  }

  int _validateCandidateRun(
    LearningRun run, {
    required PersonalizationVersion active,
    required String activeRuleVersion,
    required DateTime at,
  }) {
    if (run.parameterFamily != LearningParameterFamily.baseline ||
        run.status != LearningRunStatus.completed ||
        run.result != LearningRunResult.candidate ||
        run.completedAt == null ||
        run.completedAt!.toUtc().isBefore(run.triggeredAt.toUtc()) ||
        run.completedAt!.toUtc().isAfter(at.toUtc()) ||
        run.sourcePersonalizationVersionId != active.id ||
        !productionGate.allows(run.parameterFamily) ||
        !productionGate.supportedBaselineAlgorithms.contains(
          run.algorithmVersion,
        ) ||
        !productionGate.supportedBaselineConfigs.contains(run.configVersion) ||
        run.evidenceHashVersion != canonicalEvidenceHashV1 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(run.evidenceHash) ||
        _containsForbiddenWatermark(run.algorithmVersion) ||
        _containsForbiddenWatermark(run.configVersion) ||
        _containsForbiddenWatermark(run.evidenceSnapshotJson) ||
        _containsForbiddenWatermark(run.candidateValuesJson ?? '')) {
      throw StateError('sourceLearningRunInvalid');
    }
    final expectedRunId = deterministicLearningRunId(
      parameterFamily: run.parameterFamily,
      sourceModelIdentity: run.sourceModelIdentity,
      algorithmVersion: run.algorithmVersion,
      configVersion: run.configVersion,
      evidenceHash: run.evidenceHash,
    );
    if (run.id != expectedRunId) {
      throw StateError('sourceLearningRunIdentityInvalid');
    }
    final reasonCodes = _jsonList(run.reasonCodesJson, 'reasonCodes');
    if (const CanonicalJsonEncoder().encode(reasonCodes) !=
            run.reasonCodesJson ||
        reasonCodes.isEmpty ||
        reasonCodes.any((value) => value is! String || value.trim().isEmpty) ||
        reasonCodes.toSet().length != reasonCodes.length) {
      throw StateError('sourceLearningRunReasonsInvalid');
    }
    final current = _jsonObject(run.currentValuesJson, 'currentValues');
    final candidate = _jsonObject(run.candidateValuesJson!, 'candidateValues');
    if (!_isCanonicalBaseObject(current, run.currentValuesJson) ||
        !_isCanonicalBaseObject(candidate, run.candidateValuesJson!) ||
        current['baseEnergy'] != active.baseEnergy) {
      throw StateError('sourceLearningRunValuesInvalid');
    }
    final candidateBase = candidate['baseEnergy'];
    if (candidateBase is! int ||
        candidateBase < 60 ||
        candidateBase > 140 ||
        candidateBase == active.baseEnergy) {
      throw StateError('candidateValuesInvalid');
    }

    final snapshot = _jsonObject(run.evidenceSnapshotJson, 'evidenceSnapshot');
    if (const CanonicalJsonEncoder().encode(snapshot) !=
            run.evidenceSnapshotJson ||
        !_hasExactKeys(snapshot, const {'descriptive', 'hashInput'})) {
      throw StateError('learningEvidenceShapeInvalid');
    }
    final descriptive = snapshot['descriptive'];
    final hashInput = snapshot['hashInput'];
    if (descriptive is! Map<String, Object?> ||
        hashInput is! Map<String, Object?> ||
        !_hasExactKeys(hashInput, const {
          'algorithmVersion',
          'configVersion',
          'evidenceHashVersion',
          'parameterFamily',
          'readinessThresholds',
          'referenceType',
          'scopedExcludedEvidence',
          'selectedEligibleEvidence',
          'sourceModelIdentity',
        }) ||
        hashInput['algorithmVersion'] != run.algorithmVersion ||
        hashInput['configVersion'] != run.configVersion ||
        hashInput['evidenceHashVersion'] != run.evidenceHashVersion ||
        hashInput['parameterFamily'] != run.parameterFamily.code ||
        hashInput['sourceModelIdentity'] != run.sourceModelIdentity) {
      throw StateError('learningEvidenceIdentityInvalid');
    }
    final recomputedHash = sha256
        .convert(utf8.encode(const CanonicalJsonEncoder().encode(hashInput)))
        .toString();
    if (recomputedHash != run.evidenceHash) {
      throw StateError('learningEvidenceHashChanged');
    }
    final referenceType = ObservationReferenceType.values
        .where((value) => value.code == hashInput['referenceType'])
        .firstOrNull;
    if (referenceType == null) {
      throw StateError('learningEvidenceReferenceInvalid');
    }
    final expectedRegime = const ModelRegimeKeyBuilder().build(
      referenceType: referenceType,
      baseEnergy: active.baseEnergy,
      ruleVersion: activeRuleVersion,
      comparisonBandVersion: mvpBComparisonBandV1,
      effectiveModelFingerprint: active.effectiveModelFingerprint,
      modelRegimeEpoch: active.modelRegimeEpoch,
    );
    if (run.sourceModelIdentity != expectedRegime) {
      throw StateError('sourceModelChanged');
    }
    final thresholds = hashInput['readinessThresholds'];
    if (thresholds is! Map<String, Object?> ||
        !_hasExactKeys(thresholds, const {
          'minimumEligibleObservationPairs',
          'minimumObservationSpanCalendarDays',
          'shadowWindowCount',
          'shadowWindowEligiblePairs',
        }) ||
        thresholds['minimumEligibleObservationPairs'] != 14 ||
        thresholds['minimumObservationSpanCalendarDays'] != 21 ||
        thresholds['shadowWindowCount'] != 2 ||
        thresholds['shadowWindowEligiblePairs'] != 7) {
      throw StateError('learningEvidenceThresholdsInvalid');
    }
    final selected = hashInput['selectedEligibleEvidence'];
    final excluded = hashInput['scopedExcludedEvidence'];
    if (selected is! List<Object?> ||
        selected.length != 14 ||
        excluded is! List<Object?>) {
      throw StateError('learningEvidenceMissing');
    }
    final evidenceIds = <String>{};
    DateTime? oldest;
    LifeDay? earliestLifeDay;
    LifeDay? latestLifeDay;
    LifeDay? previousLifeDay;
    DateTime? previousObservedAt;
    String? previousId;
    for (final raw in selected) {
      if (raw is! Map<String, Object?> ||
          !_hasExactKeys(raw, const {
            'absoluteState',
            'activeActivityCountAtObservation',
            'actualOrdinal',
            'alignmentDirection',
            'baseEnergyAtObservation',
            'comparisonBandVersion',
            'contractVersion',
            'coverageState',
            'effectiveModelFingerprintAtObservation',
            'estimateAtObservation',
            'estimatedOrdinalAtObservation',
            'hasMorningCheckIn',
            'id',
            'initialEstimateAtObservation',
            'lifeDay',
            'modelRegimeEpochAtObservation',
            'modelRegimeKey',
            'observedAt',
            'personalizationVersionAtObservation',
            'referenceType',
            'ruleVersionAtObservation',
            'settled',
          }) ||
          raw['effectiveModelFingerprintAtObservation'] !=
              active.effectiveModelFingerprint ||
          raw['modelRegimeEpochAtObservation'] != active.modelRegimeEpoch ||
          raw['modelRegimeKey'] != run.sourceModelIdentity ||
          raw['baseEnergyAtObservation'] != active.baseEnergy ||
          raw['ruleVersionAtObservation'] != activeRuleVersion ||
          raw['contractVersion'] != mvpBObservationContractV1 ||
          raw['comparisonBandVersion'] != mvpBComparisonBandV1 ||
          raw['referenceType'] != referenceType.code ||
          raw['coverageState'] != ObservationCoverageState.confirmed.code ||
          raw['hasMorningCheckIn'] != true ||
          raw['settled'] != true ||
          raw['activeActivityCountAtObservation'] is! int ||
          (raw['activeActivityCountAtObservation']! as int) < 0) {
        throw StateError('learningEvidenceSourceChanged');
      }
      final id = raw['id'];
      final lifeDayText = raw['lifeDay'];
      if (id is! String ||
          id.isEmpty ||
          !evidenceIds.add(id) ||
          lifeDayText is! String) {
        throw StateError('learningEvidenceIdentityInvalid');
      }
      final LifeDay lifeDay;
      try {
        lifeDay = LifeDay.parse(lifeDayText);
      } on Object {
        throw StateError('learningEvidenceLifeDayInvalid');
      }
      final observedAt = DateTime.tryParse('${raw['observedAt']}')?.toUtc();
      if (observedAt == null || observedAt.isAfter(run.triggeredAt.toUtc())) {
        throw StateError('learningEvidenceTimeInvalid');
      }
      if (previousLifeDay != null) {
        final dayOrder = previousLifeDay.compareTo(lifeDay);
        final timeOrder = previousObservedAt!.compareTo(observedAt);
        if (dayOrder > 0 ||
            (dayOrder == 0 &&
                (timeOrder > 0 ||
                    (timeOrder == 0 && previousId!.compareTo(id) >= 0)))) {
          throw StateError('learningEvidenceOrderInvalid');
        }
      }
      if (!_observationVersionMatches(raw, active)) {
        throw StateError('learningEvidenceSourceChanged');
      }
      if (oldest == null || observedAt.isBefore(oldest)) oldest = observedAt;
      earliestLifeDay ??= lifeDay;
      latestLifeDay = lifeDay;
      previousLifeDay = lifeDay;
      previousObservedAt = observedAt;
      previousId = id;
    }
    final spanCalendarDays =
        DateTime.utc(
              latestLifeDay!.year,
              latestLifeDay.month,
              latestLifeDay.day,
            )
            .difference(
              DateTime.utc(
                earliestLifeDay!.year,
                earliestLifeDay.month,
                earliestLifeDay.day,
              ),
            )
            .inDays;
    if (spanCalendarDays < 21) {
      throw StateError('learningEvidenceSpanInvalid');
    }
    final readiness = descriptive['readiness'];
    final windowSizes = descriptive['windowSizes'];
    if (!_hasExactKeys(descriptive, const {
          'directionCounts',
          'earliestSelectedLifeDay',
          'eligibleTotal',
          'excludedReasonCounts',
          'excludedTotal',
          'latestSelectedLifeDay',
          'missingToMinimum',
          'readiness',
          'selectedEligible',
          'windowDirectionCounts',
          'windowSizes',
        }) ||
        descriptive['selectedEligible'] != 14 ||
        descriptive['eligibleTotal'] is! int ||
        (descriptive['eligibleTotal']! as int) < 14 ||
        descriptive['excludedTotal'] != excluded.length ||
        descriptive['missingToMinimum'] != 0 ||
        descriptive['earliestSelectedLifeDay'] != earliestLifeDay.toString() ||
        descriptive['latestSelectedLifeDay'] != latestLifeDay.toString() ||
        readiness is! Map<String, Object?> ||
        !_hasExactKeys(readiness, const {
          'hasCompleteWindows',
          'hasMinimumCount',
          'hasMinimumSpan',
          'spanCalendarDays',
        }) ||
        readiness['hasCompleteWindows'] != true ||
        readiness['hasMinimumCount'] != true ||
        readiness['hasMinimumSpan'] != true ||
        readiness['spanCalendarDays'] != spanCalendarDays ||
        windowSizes is! List<Object?> ||
        windowSizes.length != 2 ||
        windowSizes[0] != 7 ||
        windowSizes[1] != 7) {
      throw StateError('learningEvidenceReadinessInvalid');
    }
    if (!at.toUtc().isBefore(oldest!.add(maximumEvidenceAge))) {
      throw StateError('learningEvidenceExpired');
    }
    return candidateBase;
  }

  bool _observationVersionMatches(
    Map<String, Object?> observation,
    PersonalizationVersion active,
  ) {
    final observedVersion = observation['personalizationVersionAtObservation'];
    if (observedVersion == active.id) return true;
    return active.creationSource == PersonalizationCreationSource.initial &&
        active.effectiveModelFingerprint ==
            fixedMvpAEffectiveModelFingerprint &&
        active.modelRegimeEpoch == fixedMvpAInitialModelRegimeEpoch &&
        observedVersion == fixedMvpAPersonalizationVersion;
  }

  bool _sameLearningRun(LearningRun left, LearningRun right) {
    return left.id == right.id &&
        left.parameterFamily == right.parameterFamily &&
        left.sourceModelIdentity == right.sourceModelIdentity &&
        left.sourcePersonalizationVersionId ==
            right.sourcePersonalizationVersionId &&
        left.status == right.status &&
        left.result == right.result &&
        left.evidenceSnapshotJson == right.evidenceSnapshotJson &&
        left.evidenceHash == right.evidenceHash &&
        left.evidenceHashVersion == right.evidenceHashVersion &&
        left.algorithmVersion == right.algorithmVersion &&
        left.configVersion == right.configVersion &&
        left.currentValuesJson == right.currentValuesJson &&
        left.candidateValuesJson == right.candidateValuesJson &&
        left.reasonCodesJson == right.reasonCodesJson &&
        left.triggeredAt.toUtc() == right.triggeredAt.toUtc() &&
        left.completedAt?.toUtc() == right.completedAt?.toUtc();
  }

  Map<String, Object?> _jsonObject(String value, String name) {
    final Object? decoded;
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      throw StateError('$name:invalidJson');
    }
    if (decoded is! Map<String, Object?>) {
      throw StateError('$name:notObject');
    }
    return decoded;
  }

  List<Object?> _jsonList(String value, String name) {
    final Object? decoded;
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      throw StateError('$name:invalidJson');
    }
    if (decoded is! List<Object?>) {
      throw StateError('$name:notList');
    }
    return decoded;
  }

  bool _hasExactKeys(Map<String, Object?> value, Set<String> expected) {
    return value.length == expected.length &&
        value.keys.toSet().containsAll(expected);
  }

  bool _isCanonicalBaseObject(Map<String, Object?> value, String encoded) {
    final base = value['baseEnergy'];
    return value.length == 1 &&
        base is int &&
        const CanonicalJsonEncoder().encode(value) == encoded;
  }

  bool _containsForbiddenWatermark(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('preproduction_only_do_not_activate_or_ship') ||
        normalized.contains('do-not-ship');
  }

  bool _isAncestor(
    String possibleAncestorId,
    String childId,
    List<PersonalizationVersion> all,
  ) {
    final byId = {for (final version in all) version.id: version};
    var cursor = byId[childId];
    while (cursor != null && cursor.parentVersionId != null) {
      final parentId = cursor.parentVersionId!;
      if (parentId == possibleAncestorId) return true;
      cursor = byId[parentId];
    }
    return false;
  }

  Future<void> _insertNotice({
    required LearningParameterFamily parameterFamily,
    required LearningNoticeType type,
    required String? versionId,
    required String? learningRunId,
    required String reasonCode,
    required DateTime at,
  }) async {
    final dedupKey = identities.noticeDedupKey(
      parameterFamily: parameterFamily,
      type: type,
      personalizationVersionId: versionId,
      learningRunId: learningRunId,
      reasonCode: reasonCode,
    );
    final notice = LearningNotice(
      id: identities.noticeId(dedupKey),
      parameterFamily: parameterFamily,
      type: type,
      personalizationVersionId: versionId,
      learningRunId: learningRunId,
      dedupKey: dedupKey,
      status: LearningNoticeStatus.unseen,
      reasonCode: reasonCode,
      createdAt: at.toUtc(),
      seenAt: null,
      dismissedAt: null,
    );
    final existing = await notices.find(notice.id);
    if (existing != null) {
      if (!_sameNoticeIdentity(existing, notice)) {
        throw StateError('learningNoticeIdentityCollision');
      }
      return;
    }
    await notices.insert(notice);
  }

  bool _sameNoticeIdentity(LearningNotice left, LearningNotice right) {
    return left.id == right.id &&
        left.parameterFamily == right.parameterFamily &&
        left.type == right.type &&
        left.personalizationVersionId == right.personalizationVersionId &&
        left.learningRunId == right.learningRunId &&
        left.dedupKey == right.dedupKey &&
        left.reasonCode == right.reasonCode &&
        left.createdAt.toUtc() == right.createdAt.toUtc();
  }

  Future<void> _validateAll() async {
    integrity.validate(await versions.list());
  }

  LearningMode _modeFor(AppSettings value, LearningParameterFamily family) =>
      switch (family) {
        LearningParameterFamily.baseline => value.baselineLearningMode,
        LearningParameterFamily.activityImpact =>
          value.activityImpactLearningMode,
      };

  String _disclosureFor(LearningParameterFamily family) => switch (family) {
    LearningParameterFamily.baseline => baselineLearningDisclosureV1,
    LearningParameterFamily.activityImpact =>
      activityImpactLearningDisclosureV1,
  };

  AppSettings _copySettingsMode(
    AppSettings value, {
    required LearningParameterFamily parameterFamily,
    required LearningMode mode,
    required DateTime updatedAt,
  }) {
    return _copySettings(
      value,
      baselineLearningMode: parameterFamily == LearningParameterFamily.baseline
          ? mode
          : value.baselineLearningMode,
      activityImpactLearningMode:
          parameterFamily == LearningParameterFamily.activityImpact
          ? mode
          : value.activityImpactLearningMode,
      baselineCooldown: value.baselineLearningCooldownUntil,
      activityCooldown: value.activityImpactLearningCooldownUntil,
      updatedAt: updatedAt,
    );
  }

  AppSettings _copySettingsCooldown(
    AppSettings value, {
    required LearningParameterFamily parameterFamily,
    required DateTime cooldownUntil,
    required DateTime updatedAt,
  }) {
    return _copySettings(
      value,
      baselineLearningMode: value.baselineLearningMode,
      activityImpactLearningMode: value.activityImpactLearningMode,
      baselineCooldown: parameterFamily == LearningParameterFamily.baseline
          ? cooldownUntil.toUtc()
          : value.baselineLearningCooldownUntil,
      activityCooldown:
          parameterFamily == LearningParameterFamily.activityImpact
          ? cooldownUntil.toUtc()
          : value.activityImpactLearningCooldownUntil,
      updatedAt: updatedAt,
    );
  }

  AppSettings _copySettingsSuspension(
    AppSettings value, {
    required LearningParameterFamily parameterFamily,
    required bool suspended,
    required DateTime? suspendedAt,
    required String? reason,
    required DateTime updatedAt,
  }) {
    return AppSettings(
      activeRuleVersion: value.activeRuleVersion,
      pendingRuleVersion: value.pendingRuleVersion,
      pendingRuleEffectiveLifeDay: value.pendingRuleEffectiveLifeDay,
      onboardingCompleted: value.onboardingCompleted,
      baselineLearningMode: value.baselineLearningMode,
      activityImpactLearningMode: value.activityImpactLearningMode,
      baselineLearningSuspended:
          parameterFamily == LearningParameterFamily.baseline
          ? suspended
          : value.baselineLearningSuspended,
      baselineLearningSuspendedAt:
          parameterFamily == LearningParameterFamily.baseline
          ? suspendedAt?.toUtc()
          : value.baselineLearningSuspendedAt,
      baselineLearningSuspensionReason:
          parameterFamily == LearningParameterFamily.baseline
          ? reason
          : value.baselineLearningSuspensionReason,
      activityImpactLearningSuspended:
          parameterFamily == LearningParameterFamily.activityImpact
          ? suspended
          : value.activityImpactLearningSuspended,
      activityImpactLearningSuspendedAt:
          parameterFamily == LearningParameterFamily.activityImpact
          ? suspendedAt?.toUtc()
          : value.activityImpactLearningSuspendedAt,
      activityImpactLearningSuspensionReason:
          parameterFamily == LearningParameterFamily.activityImpact
          ? reason
          : value.activityImpactLearningSuspensionReason,
      baselineLearningCooldownUntil: value.baselineLearningCooldownUntil,
      activityImpactLearningCooldownUntil:
          value.activityImpactLearningCooldownUntil,
      createdAt: value.createdAt,
      updatedAt: updatedAt.toUtc(),
    );
  }

  AppSettings _copySettings(
    AppSettings value, {
    required LearningMode baselineLearningMode,
    required LearningMode activityImpactLearningMode,
    required DateTime? baselineCooldown,
    required DateTime? activityCooldown,
    required DateTime updatedAt,
  }) {
    return AppSettings(
      activeRuleVersion: value.activeRuleVersion,
      pendingRuleVersion: value.pendingRuleVersion,
      pendingRuleEffectiveLifeDay: value.pendingRuleEffectiveLifeDay,
      onboardingCompleted: value.onboardingCompleted,
      baselineLearningMode: baselineLearningMode,
      activityImpactLearningMode: activityImpactLearningMode,
      baselineLearningSuspended: value.baselineLearningSuspended,
      baselineLearningSuspendedAt: value.baselineLearningSuspendedAt,
      baselineLearningSuspensionReason: value.baselineLearningSuspensionReason,
      activityImpactLearningSuspended: value.activityImpactLearningSuspended,
      activityImpactLearningSuspendedAt:
          value.activityImpactLearningSuspendedAt,
      activityImpactLearningSuspensionReason:
          value.activityImpactLearningSuspensionReason,
      baselineLearningCooldownUntil: baselineCooldown,
      activityImpactLearningCooldownUntil: activityCooldown,
      createdAt: value.createdAt,
      updatedAt: updatedAt.toUtc(),
    );
  }
}
