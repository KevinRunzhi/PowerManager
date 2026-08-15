import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:power_manager/application/model_activation_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/data/db/app_database.dart';
import 'package:power_manager/data/db/drift_transaction_runner.dart';
import 'package:power_manager/data/repositories/drift_repositories.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/energy/observation_comparison_service.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/canonical_json.dart';
import 'package:power_manager/domain/learning/personalization_identity.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';
import 'package:test/test.dart';

import '../data/db/test_database.dart';

const _algorithm = 'baseline-production-v1';
const _config = 'baseline-production-config-v1';
const _openGate = LearningProductionGate(
  baselineProductionLearningEnabled: true,
  activityImpactProductionLearningEnabled: true,
  isPreproductionValidationOverride: true,
  supportedBaselineAlgorithms: {_algorithm},
  supportedBaselineConfigs: {_config},
);

void main() {
  test('formal gate rejects mode enablement without writing consent', () async {
    final harness = await _Harness.create(
      gate: const LearningProductionGate.closed(),
    );

    await expectLater(
      harness.service.changeLearningMode(
        parameterFamily: LearningParameterFamily.baseline,
        mode: LearningMode.review,
        acceptCurrentDisclosure: true,
        at: DateTime.utc(2026, 8, 15, 8),
      ),
      throwsA(_stateError('productionLearningDisabled')),
    );
    expect(
      (await harness.settings.get()).baselineLearningMode,
      LearningMode.off,
    );
    expect(await harness.consents.list(), isEmpty);
  });

  test(
    'parameter-family modes and disclosure receipts stay independent',
    () async {
      final harness = await _Harness.create();
      final at = DateTime.utc(2026, 8, 15, 8);

      await harness.service.changeLearningMode(
        parameterFamily: LearningParameterFamily.baseline,
        mode: LearningMode.review,
        acceptCurrentDisclosure: true,
        at: at,
      );
      var settings = await harness.settings.get();
      expect(settings.baselineLearningMode, LearningMode.review);
      expect(settings.activityImpactLearningMode, LearningMode.off);

      await harness.service.changeLearningMode(
        parameterFamily: LearningParameterFamily.activityImpact,
        mode: LearningMode.automatic,
        acceptCurrentDisclosure: true,
        at: at.add(const Duration(minutes: 1)),
      );
      settings = await harness.settings.get();
      expect(settings.baselineLearningMode, LearningMode.review);
      expect(settings.activityImpactLearningMode, LearningMode.automatic);
      expect(
        (await harness.consents.list()).map((item) => item.parameterFamily),
        containsAll(LearningParameterFamily.values),
      );
    },
  );

  test(
    'review candidate defers, reopens, schedules and activates once',
    () async {
      final harness = await _Harness.create();
      final createdAt = DateTime.utc(2026, 8, 15, 10);
      await harness.enableBaseline(LearningMode.review, at: createdAt);
      final run = await harness.insertRun(
        triggeredAt: createdAt.subtract(const Duration(hours: 1)),
      );

      final registered = await harness.service.registerLearningCandidate(
        run: run,
        currentLifeDay: LifeDay(2026, 8, 15),
        atLocal: createdAt,
        ruleVersion: energyRulesV2MvpAVersion,
      );
      expect(registered.created, isTrue);
      expect(
        registered.version.status,
        PersonalizationVersionStatus.awaitingReview,
      );
      expect(registered.version.baseEnergy, 98);
      expect(registered.version.baselineAnchorEnergy, 100);
      expect(
        (await harness.notices.list()).single.type,
        LearningNoticeType.candidateAvailable,
      );

      final deferred = await harness.service.deferReviewCandidate(
        versionId: registered.version.id,
        at: createdAt.add(const Duration(hours: 1)),
      );
      expect(deferred.status, PersonalizationVersionStatus.deferred);
      await expectLater(
        harness.service.acceptReviewCandidate(
          versionId: deferred.id,
          currentLifeDay: LifeDay(2026, 8, 15),
          effectiveLifeDay: LifeDay(2026, 8, 16),
          at: createdAt.add(const Duration(hours: 2)),
        ),
        throwsA(_stateError('candidateNotReviewable')),
      );

      final reopened = await harness.service.reopenDeferredCandidate(
        versionId: deferred.id,
        at: createdAt.add(const Duration(hours: 2)),
      );
      final scheduled = await harness.service.acceptReviewCandidate(
        versionId: reopened.id,
        currentLifeDay: LifeDay(2026, 8, 15),
        effectiveLifeDay: LifeDay(2026, 8, 16),
        at: createdAt.add(const Duration(hours: 3)),
      );
      expect(scheduled.id, registered.version.id);
      expect(scheduled.status, PersonalizationVersionStatus.scheduled);
      expect(
        scheduled.scheduleSource,
        PersonalizationScheduleSource.reviewAccepted,
      );
      expect(
        (await harness.notices.list()).where(
          (item) => item.type == LearningNoticeType.changeScheduled,
        ),
        hasLength(1),
      );

      final early = await harness.service.activateDue(
        currentLifeDay: LifeDay(2026, 8, 15),
        at: DateTime.utc(2026, 8, 15, 23),
      );
      expect(early.activated, isFalse);
      final activated = await harness.service.activateDue(
        currentLifeDay: LifeDay(2026, 8, 16),
        at: DateTime.utc(2026, 8, 16, 4),
      );
      expect(activated.activated, isTrue);
      expect(activated.version!.baseEnergy, 98);
      expect(activated.version!.baselineAnchorEnergy, 100);
      expect((await harness.versions.getActive()).id, scheduled.id);

      final repeated = await harness.service.activateDue(
        currentLifeDay: LifeDay(2026, 8, 16),
        at: DateTime.utc(2026, 8, 16, 5),
      );
      expect(repeated.activated, isFalse);
      expect(
        (await harness.notices.list()).where(
          (item) => item.type == LearningNoticeType.changeActivated,
        ),
        hasLength(1),
      );
    },
  );

  test(
    'automatic effective day honors the exact 24-hour 04:00 boundary',
    () async {
      final harness = await _Harness.create();

      expect(
        harness.service.earliestAutomaticEffectiveLifeDay(
          currentLifeDay: LifeDay(2026, 8, 14),
          atLocal: DateTime(2026, 8, 15, 3, 59),
        ),
        LifeDay(2026, 8, 16),
      );
      expect(
        harness.service.earliestAutomaticEffectiveLifeDay(
          currentLifeDay: LifeDay(2026, 8, 15),
          atLocal: DateTime(2026, 8, 15, 4),
        ),
        LifeDay(2026, 8, 16),
      );
      expect(
        harness.service.earliestAutomaticEffectiveLifeDay(
          currentLifeDay: LifeDay(2026, 8, 15),
          atLocal: DateTime(2026, 8, 15, 4, 0, 1),
        ),
        LifeDay(2026, 8, 17),
      );
    },
  );

  test(
    'notice insert failure rolls the automatic schedule back atomically',
    () async {
      final harness = await _Harness.create(failNoticeInsert: true);
      final at = DateTime.utc(2026, 8, 15, 10);
      await harness.enableBaseline(LearningMode.automatic, at: at);
      final run = await harness.insertRun(
        triggeredAt: at.subtract(const Duration(hours: 1)),
      );

      await expectLater(
        harness.service.registerLearningCandidate(
          run: run,
          currentLifeDay: LifeDay(2026, 8, 15),
          atLocal: at,
          ruleVersion: energyRulesV2MvpAVersion,
        ),
        throwsA(_stateError('injectedNoticeFailure')),
      );
      expect(await harness.versions.findPending(), isNull);
      expect(await harness.versions.list(), hasLength(1));
      expect(await harness.notices.list(), isEmpty);
      expect(await harness.runs.find(run.id), isNotNull);
    },
  );

  test(
    'automatic downgrade, upgrade and off never auto-revive a candidate',
    () async {
      final harness = await _Harness.create();
      final at = DateTime.utc(2026, 8, 15, 10);
      await harness.enableBaseline(LearningMode.automatic, at: at);
      final run = await harness.insertRun(
        triggeredAt: at.subtract(const Duration(hours: 1)),
      );
      final automatic = await harness.service.registerLearningCandidate(
        run: run,
        currentLifeDay: LifeDay(2026, 8, 15),
        atLocal: at,
        ruleVersion: energyRulesV2MvpAVersion,
      );
      expect(automatic.version.status, PersonalizationVersionStatus.scheduled);

      await harness.service.changeLearningMode(
        parameterFamily: LearningParameterFamily.baseline,
        mode: LearningMode.review,
        acceptCurrentDisclosure: false,
        at: at.add(const Duration(hours: 1)),
      );
      var pending = await harness.versions.findPending();
      expect(pending!.status, PersonalizationVersionStatus.awaitingReview);
      expect(pending.scheduleSource, isNull);
      expect(pending.effectiveLifeDay, isNull);

      await harness.service.changeLearningMode(
        parameterFamily: LearningParameterFamily.baseline,
        mode: LearningMode.automatic,
        acceptCurrentDisclosure: false,
        at: at.add(const Duration(hours: 2)),
      );
      pending = await harness.versions.findPending();
      expect(pending!.status, PersonalizationVersionStatus.awaitingReview);

      await harness.service.changeLearningMode(
        parameterFamily: LearningParameterFamily.baseline,
        mode: LearningMode.off,
        acceptCurrentDisclosure: false,
        at: at.add(const Duration(hours: 3)),
      );
      expect(await harness.versions.findPending(), isNull);
      final terminal = await harness.versions.find(automatic.version.id);
      expect(terminal!.status, PersonalizationVersionStatus.canceled);
      final settings = await harness.settings.get();
      expect(settings.baselineLearningMode, LearningMode.off);
      expect(
        settings.baselineLearningCooldownUntil,
        at.add(const Duration(hours: 3, days: 14)),
      );
      expect(settings.activityImpactLearningMode, LearningMode.off);
    },
  );

  test(
    'manual schedule invalidates a candidate, resets anchor and is idempotent',
    () async {
      final harness = await _Harness.create();
      final at = DateTime.utc(2026, 8, 15, 10);
      await harness.enableBaseline(LearningMode.review, at: at);
      final run = await harness.insertRun(
        triggeredAt: at.subtract(const Duration(hours: 1)),
      );
      final candidate = await harness.service.registerLearningCandidate(
        run: run,
        currentLifeDay: LifeDay(2026, 8, 15),
        atLocal: at,
        ruleVersion: energyRulesV2MvpAVersion,
      );

      final manual = await harness.service.scheduleManualBaseline(
        baseEnergy: 110,
        currentLifeDay: LifeDay(2026, 8, 15),
        effectiveLifeDay: LifeDay(2026, 8, 16),
        at: at.add(const Duration(hours: 1)),
        ruleVersion: energyRulesV2MvpAVersion,
      );
      expect(manual.created, isTrue);
      expect(manual.version.baselineAnchorEnergy, 110);
      expect(
        manual.version.scheduleSource,
        PersonalizationScheduleSource.manual,
      );
      expect(
        (await harness.versions.find(candidate.version.id))!.status,
        PersonalizationVersionStatus.invalidated,
      );

      final repeated = await harness.service.scheduleManualBaseline(
        baseEnergy: 110,
        currentLifeDay: LifeDay(2026, 8, 15),
        effectiveLifeDay: LifeDay(2026, 8, 16),
        at: at.add(const Duration(hours: 2)),
        ruleVersion: energyRulesV2MvpAVersion,
      );
      expect(repeated.created, isFalse);
      expect(repeated.version.id, manual.version.id);
      expect(await harness.versions.findPending(), isNotNull);

      final activated = await harness.service.activateDue(
        currentLifeDay: LifeDay(2026, 8, 16),
        at: DateTime.utc(2026, 8, 16, 4),
      );
      expect(activated.activated, isTrue);
      expect(activated.version!.baseEnergy, 110);
      expect(activated.version!.baselineAnchorEnergy, 110);
    },
  );

  test(
    'restore invalidates due automatic but honors explicit review schedule',
    () async {
      final automaticHarness = await _Harness.create();
      final at = DateTime.utc(2026, 8, 15, 10);
      await automaticHarness.enableBaseline(LearningMode.automatic, at: at);
      final automaticRun = await automaticHarness.insertRun(
        triggeredAt: at.subtract(const Duration(hours: 1)),
      );
      final automatic = await automaticHarness.service
          .registerLearningCandidate(
            run: automaticRun,
            currentLifeDay: LifeDay(2026, 8, 15),
            atLocal: at,
            ruleVersion: energyRulesV2MvpAVersion,
          );
      final automaticRestore = await automaticHarness.service.activateDue(
        currentLifeDay: automatic.version.effectiveLifeDay!,
        at: DateTime.utc(2026, 8, 17, 4),
        afterRestore: true,
      );
      expect(automaticRestore.activated, isFalse);
      expect(
        automaticRestore.invalidationReason,
        'automaticRestoreDueOrMissed',
      );
      expect((await automaticHarness.versions.getActive()).baseEnergy, 100);
      await automaticHarness.close();

      final reviewHarness = await _Harness.create();
      await reviewHarness.enableBaseline(LearningMode.review, at: at);
      final reviewRun = await reviewHarness.insertRun(
        triggeredAt: at.subtract(const Duration(hours: 1)),
      );
      final review = await reviewHarness.service.registerLearningCandidate(
        run: reviewRun,
        currentLifeDay: LifeDay(2026, 8, 15),
        atLocal: at,
        ruleVersion: energyRulesV2MvpAVersion,
      );
      await reviewHarness.service.acceptReviewCandidate(
        versionId: review.version.id,
        currentLifeDay: LifeDay(2026, 8, 15),
        effectiveLifeDay: LifeDay(2026, 8, 16),
        at: at.add(const Duration(hours: 1)),
      );
      final explicitRestore = await reviewHarness.service.activateDue(
        currentLifeDay: LifeDay(2026, 8, 16),
        at: DateTime.utc(2026, 8, 16, 4),
        afterRestore: true,
      );
      expect(explicitRestore.activated, isTrue);
      expect((await reviewHarness.versions.getActive()).baseEnergy, 98);
    },
  );

  test(
    'activation revalidates production gate and required schedule notice',
    () async {
      final harness = await _Harness.create();
      final at = DateTime.utc(2026, 8, 15, 10);
      await harness.enableBaseline(LearningMode.automatic, at: at);
      final run = await harness.insertRun(
        triggeredAt: at.subtract(const Duration(hours: 1)),
      );
      final candidate = await harness.service.registerLearningCandidate(
        run: run,
        currentLifeDay: LifeDay(2026, 8, 15),
        atLocal: at,
        ruleVersion: energyRulesV2MvpAVersion,
      );
      final closed = harness.serviceWithGate(
        const LearningProductionGate.closed(),
      );
      final invalidated = await closed.activateDue(
        currentLifeDay: candidate.version.effectiveLifeDay!,
        at: DateTime.utc(2026, 8, 17, 4),
      );
      expect(invalidated.activated, isFalse);
      expect(invalidated.invalidationReason, 'productionGateClosed');
      await harness.close();

      final missingNoticeHarness = await _Harness.create();
      final active = await missingNoticeHarness.versions.getActive();
      final manual = scheduledManualPersonalizationVersion(
        parent: active,
        baseEnergy: 112,
        effectiveLifeDay: LifeDay(2026, 8, 16),
        createdAt: at,
        ruleVersion: energyRulesV2MvpAVersion,
        legacy: false,
      );
      await missingNoticeHarness.versions.insert(manual);
      final missingNotice = await missingNoticeHarness.service.activateDue(
        currentLifeDay: LifeDay(2026, 8, 16),
        at: DateTime.utc(2026, 8, 16, 4),
      );
      expect(missingNotice.activated, isFalse);
      expect(missingNotice.invalidationReason, 'missingScheduledNotice');
      expect((await missingNoticeHarness.versions.getActive()).baseEnergy, 100);
    },
  );

  test(
    'same-value revert creates a new epoch without resetting anchor',
    () async {
      final harness = await _Harness.create();
      final initial = await harness.versions.getActive();

      await harness.service.scheduleManualBaseline(
        baseEnergy: 110,
        currentLifeDay: LifeDay(2026, 8, 1),
        effectiveLifeDay: LifeDay(2026, 8, 2),
        at: DateTime.utc(2026, 8, 1, 5),
        ruleVersion: energyRulesV2MvpAVersion,
      );
      await harness.service.activateDue(
        currentLifeDay: LifeDay(2026, 8, 2),
        at: DateTime.utc(2026, 8, 2, 4),
      );
      await harness.service.scheduleManualBaseline(
        baseEnergy: 100,
        currentLifeDay: LifeDay(2026, 8, 2),
        effectiveLifeDay: LifeDay(2026, 8, 3),
        at: DateTime.utc(2026, 8, 2, 5),
        ruleVersion: energyRulesV2MvpAVersion,
      );
      await harness.service.activateDue(
        currentLifeDay: LifeDay(2026, 8, 3),
        at: DateTime.utc(2026, 8, 3, 4),
      );
      final current = await harness.versions.getActive();
      expect(current.baseEnergy, initial.baseEnergy);

      final revert = await harness.service.scheduleRevert(
        targetVersionId: initial.id,
        currentLifeDay: LifeDay(2026, 8, 3),
        effectiveLifeDay: LifeDay(2026, 8, 4),
        at: DateTime.utc(2026, 8, 3, 5),
      );
      expect(revert.baseEnergy, current.baseEnergy);
      expect(revert.baselineAnchorEnergy, current.baselineAnchorEnergy);
      expect(revert.modelRegimeEpoch, isNot(current.modelRegimeEpoch));
      expect(revert.modelRegimeEpoch, isNot(initial.modelRegimeEpoch));

      final activated = await harness.service.activateDue(
        currentLifeDay: LifeDay(2026, 8, 4),
        at: DateTime.utc(2026, 8, 4, 4),
      );
      expect(activated.activated, isTrue);
      expect(activated.version!.baseEnergy, 100);
      expect(activated.version!.id, revert.id);
      expect(
        (await harness.versions.find(current.id))!.status,
        PersonalizationVersionStatus.reverted,
      );
    },
  );

  test(
    'worsened run suspends only its family and resume is idempotent',
    () async {
      final harness = await _Harness.create();
      final at = DateTime.utc(2026, 8, 15, 10);
      await harness.enableBaseline(LearningMode.review, at: at);
      await harness.service.changeLearningMode(
        parameterFamily: LearningParameterFamily.activityImpact,
        mode: LearningMode.automatic,
        acceptCurrentDisclosure: true,
        at: at.add(const Duration(minutes: 1)),
      );
      final candidateRun = await harness.insertRun(
        triggeredAt: at.subtract(const Duration(hours: 1)),
      );
      final candidate = await harness.service.registerLearningCandidate(
        run: candidateRun,
        currentLifeDay: LifeDay(2026, 8, 15),
        atLocal: at,
        ruleVersion: energyRulesV2MvpAVersion,
      );
      final worsened = await harness.insertRun(
        triggeredAt: at,
        result: LearningRunResult.worsened,
        evidencePrefix: 'monitor',
      );

      final suspended = await harness.service.suspendLearning(
        parameterFamily: LearningParameterFamily.baseline,
        learningRunId: worsened.id,
        reasonCode: 'postActivationWorsened',
        at: at.add(const Duration(hours: 1)),
      );
      expect(suspended.baselineLearningSuspended, isTrue);
      expect(suspended.activityImpactLearningSuspended, isFalse);
      expect(suspended.activityImpactLearningMode, LearningMode.automatic);
      expect(
        (await harness.versions.find(candidate.version.id))!.status,
        PersonalizationVersionStatus.invalidated,
      );
      expect(
        (await harness.notices.list()).where(
          (item) => item.type == LearningNoticeType.learningSuspended,
        ),
        hasLength(1),
      );

      await harness.service.suspendLearning(
        parameterFamily: LearningParameterFamily.baseline,
        learningRunId: worsened.id,
        reasonCode: 'postActivationWorsened',
        at: at.add(const Duration(hours: 2)),
      );
      expect(
        (await harness.notices.list()).where(
          (item) => item.type == LearningNoticeType.learningSuspended,
        ),
        hasLength(1),
      );
      final resumed = await harness.service.resumeLearning(
        parameterFamily: LearningParameterFamily.baseline,
        at: at.add(const Duration(hours: 3)),
      );
      expect(resumed.baselineLearningSuspended, isFalse);
      expect(resumed.activityImpactLearningMode, LearningMode.automatic);
      expect(
        await harness.service.resumeLearning(
          parameterFamily: LearningParameterFamily.baseline,
          at: at.add(const Duration(hours: 4)),
        ),
        isA<AppSettings>(),
      );
    },
  );

  test(
    'candidate lifetime and rejection cooldown use exact boundaries',
    () async {
      final expiryHarness = await _Harness.create();
      final at = DateTime.utc(2026, 8, 15, 10);
      await expiryHarness.enableBaseline(LearningMode.review, at: at);
      final expiringRun = await expiryHarness.insertRun(
        triggeredAt: at.subtract(const Duration(hours: 1)),
      );
      final candidate = await expiryHarness.service.registerLearningCandidate(
        run: expiringRun,
        currentLifeDay: LifeDay(2026, 8, 15),
        atLocal: at,
        ruleVersion: energyRulesV2MvpAVersion,
      );
      await expiryHarness.service.deferReviewCandidate(
        versionId: candidate.version.id,
        at: at.add(const Duration(hours: 1)),
      );
      final expired = await expiryHarness.service.reopenDeferredCandidate(
        versionId: candidate.version.id,
        at: at.add(const Duration(days: 7)),
      );
      expect(expired.status, PersonalizationVersionStatus.invalidated);
      await expiryHarness.close();

      final cooldownHarness = await _Harness.create();
      await cooldownHarness.enableBaseline(LearningMode.review, at: at);
      final rejectedRun = await cooldownHarness.insertRun(
        triggeredAt: at.subtract(const Duration(hours: 1)),
      );
      final rejectedCandidate = await cooldownHarness.service
          .registerLearningCandidate(
            run: rejectedRun,
            currentLifeDay: LifeDay(2026, 8, 15),
            atLocal: at,
            ruleVersion: energyRulesV2MvpAVersion,
          );
      final rejectedAt = at.add(const Duration(hours: 1));
      await cooldownHarness.service.rejectReviewCandidate(
        versionId: rejectedCandidate.version.id,
        at: rejectedAt,
      );
      final blockedRun = await cooldownHarness.insertRun(
        triggeredAt: DateTime.utc(2026, 8, 20, 9),
        evidencePrefix: 'blocked',
      );
      await expectLater(
        cooldownHarness.service.registerLearningCandidate(
          run: blockedRun,
          currentLifeDay: LifeDay(2026, 8, 20),
          atLocal: rejectedAt.add(const Duration(days: 14, seconds: -1)),
          ruleVersion: energyRulesV2MvpAVersion,
        ),
        throwsA(_stateError('learningCooldownActive')),
      );
      final allowedRun = await cooldownHarness.insertRun(
        triggeredAt: DateTime.utc(2026, 8, 29, 9),
        evidencePrefix: 'allowed',
      );
      final allowed = await cooldownHarness.service.registerLearningCandidate(
        run: allowedRun,
        currentLifeDay: LifeDay(2026, 8, 29),
        atLocal: rejectedAt.add(const Duration(days: 14)),
        ruleVersion: energyRulesV2MvpAVersion,
      );
      expect(allowed.created, isTrue);
    },
  );

  test(
    'candidate registration requires the exact persisted learning run',
    () async {
      final harness = await _Harness.create();
      final at = DateTime.utc(2026, 8, 15, 10);
      await harness.enableBaseline(LearningMode.review, at: at);
      final run = await harness.buildRun(
        triggeredAt: at.subtract(const Duration(hours: 1)),
      );

      await expectLater(
        harness.service.registerLearningCandidate(
          run: run,
          currentLifeDay: LifeDay(2026, 8, 15),
          atLocal: at,
          ruleVersion: energyRulesV2MvpAVersion,
        ),
        throwsA(_stateError('sourceLearningRunNotPersisted')),
      );
      expect(await harness.versions.findPending(), isNull);
    },
  );

  test('candidate registration rejects a non-deterministic run id', () async {
    final harness = await _Harness.create();
    final at = DateTime.utc(2026, 8, 15, 10);
    await harness.enableBaseline(LearningMode.review, at: at);
    final original = await harness.buildRun(
      triggeredAt: at.subtract(const Duration(hours: 1)),
    );
    final invalid = _copyLearningRun(original, id: 'forged-candidate-run');
    await harness.runs.insert(invalid);

    await expectLater(
      harness.service.registerLearningCandidate(
        run: invalid,
        currentLifeDay: LifeDay(2026, 8, 15),
        atLocal: at,
        ruleVersion: energyRulesV2MvpAVersion,
      ),
      throwsA(_stateError('sourceLearningRunIdentityInvalid')),
    );
    expect(await harness.versions.findPending(), isNull);
  });

  test('candidate registration rechecks the 14-item readiness gate', () async {
    final harness = await _Harness.create();
    final at = DateTime.utc(2026, 8, 15, 10);
    await harness.enableBaseline(LearningMode.review, at: at);
    final original = await harness.buildRun(
      triggeredAt: at.subtract(const Duration(hours: 1)),
    );
    final snapshot =
        jsonDecode(original.evidenceSnapshotJson) as Map<String, Object?>;
    final hashInput = snapshot['hashInput']! as Map<String, Object?>;
    final selected = hashInput['selectedEligibleEvidence']! as List<Object?>;
    selected.removeLast();
    const encoder = CanonicalJsonEncoder();
    final evidenceHash = sha256
        .convert(utf8.encode(encoder.encode(hashInput)))
        .toString();
    final invalid = _copyLearningRun(
      original,
      id: deterministicLearningRunId(
        parameterFamily: original.parameterFamily,
        sourceModelIdentity: original.sourceModelIdentity,
        algorithmVersion: original.algorithmVersion,
        configVersion: original.configVersion,
        evidenceHash: evidenceHash,
      ),
      evidenceSnapshotJson: encoder.encode(snapshot),
      evidenceHash: evidenceHash,
    );
    await harness.runs.insert(invalid);

    await expectLater(
      harness.service.registerLearningCandidate(
        run: invalid,
        currentLifeDay: LifeDay(2026, 8, 15),
        atLocal: at,
        ruleVersion: energyRulesV2MvpAVersion,
      ),
      throwsA(_stateError('learningEvidenceMissing')),
    );
    expect(await harness.versions.findPending(), isNull);
  });

  test('candidate registration rejects untrusted readiness metadata', () async {
    final harness = await _Harness.create();
    final at = DateTime.utc(2026, 8, 15, 10);
    await harness.enableBaseline(LearningMode.review, at: at);
    final original = await harness.buildRun(
      triggeredAt: at.subtract(const Duration(hours: 1)),
    );
    final snapshot =
        jsonDecode(original.evidenceSnapshotJson) as Map<String, Object?>;
    final descriptive = snapshot['descriptive']! as Map<String, Object?>;
    final readiness = descriptive['readiness']! as Map<String, Object?>;
    readiness['spanCalendarDays'] = 999;
    final invalid = _copyLearningRun(
      original,
      evidenceSnapshotJson: const CanonicalJsonEncoder().encode(snapshot),
    );
    await harness.runs.insert(invalid);

    await expectLater(
      harness.service.registerLearningCandidate(
        run: invalid,
        currentLifeDay: LifeDay(2026, 8, 15),
        atLocal: at,
        ruleVersion: energyRulesV2MvpAVersion,
      ),
      throwsA(_stateError('learningEvidenceReadinessInvalid')),
    );
    expect(await harness.versions.findPending(), isNull);
  });
}

Matcher _stateError(String message) =>
    isA<StateError>().having((error) => error.message, 'message', message);

LearningRun _copyLearningRun(
  LearningRun source, {
  String? id,
  String? evidenceSnapshotJson,
  String? evidenceHash,
}) {
  return LearningRun(
    id: id ?? source.id,
    parameterFamily: source.parameterFamily,
    sourceModelIdentity: source.sourceModelIdentity,
    sourcePersonalizationVersionId: source.sourcePersonalizationVersionId,
    status: source.status,
    result: source.result,
    evidenceSnapshotJson: evidenceSnapshotJson ?? source.evidenceSnapshotJson,
    evidenceHash: evidenceHash ?? source.evidenceHash,
    evidenceHashVersion: source.evidenceHashVersion,
    algorithmVersion: source.algorithmVersion,
    configVersion: source.configVersion,
    currentValuesJson: source.currentValuesJson,
    candidateValuesJson: source.candidateValuesJson,
    reasonCodesJson: source.reasonCodesJson,
    triggeredAt: source.triggeredAt,
    completedAt: source.completedAt,
  );
}

final class _Harness {
  _Harness({
    required this.database,
    required this.settings,
    required this.versions,
    required this.runs,
    required this.consents,
    required this.notices,
    required this.service,
  });

  final AppDatabase database;
  final DriftAppSettingsRepository settings;
  final DriftPersonalizationVersionsRepository versions;
  final DriftLearningRunsRepository runs;
  final DriftLearningConsentsRepository consents;
  final DriftLearningNoticesRepository notices;
  final ModelActivationService service;
  bool _closed = false;

  static Future<_Harness> create({
    LearningProductionGate gate = _openGate,
    bool failNoticeInsert = false,
  }) async {
    final database = createTestDatabase(clock: const _SeedClock());
    final settings = DriftAppSettingsRepository(database.appSettingsDao);
    final versions = DriftPersonalizationVersionsRepository(
      database.personalizationVersionsDao,
    );
    final runs = DriftLearningRunsRepository(database.learningRunsDao);
    final consents = DriftLearningConsentsRepository(
      database.learningConsentsDao,
    );
    final notices = DriftLearningNoticesRepository(database.learningNoticesDao);
    await versions.getActive();
    final noticeWriter = failNoticeInsert
        ? _FailingLearningNoticesRepository(notices)
        : notices;
    final service = ModelActivationService(
      transactionRunner: DriftTransactionRunner(database),
      settings: settings,
      versions: versions,
      learningRuns: runs,
      consents: consents,
      notices: noticeWriter,
      productionGate: gate,
    );
    final harness = _Harness(
      database: database,
      settings: settings,
      versions: versions,
      runs: runs,
      consents: consents,
      notices: notices,
      service: service,
    );
    addTearDown(harness.close);
    return harness;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await database.close();
  }

  ModelActivationService serviceWithGate(LearningProductionGate gate) {
    return ModelActivationService(
      transactionRunner: DriftTransactionRunner(database),
      settings: settings,
      versions: versions,
      learningRuns: runs,
      consents: consents,
      notices: notices,
      productionGate: gate,
    );
  }

  Future<void> enableBaseline(LearningMode mode, {required DateTime at}) async {
    await service.changeLearningMode(
      parameterFamily: LearningParameterFamily.baseline,
      mode: mode,
      acceptCurrentDisclosure: true,
      at: at,
    );
  }

  Future<LearningRun> insertRun({
    required DateTime triggeredAt,
    LearningRunResult result = LearningRunResult.candidate,
    String evidencePrefix = 'candidate',
    int candidateBase = 98,
  }) async {
    final run = await buildRun(
      triggeredAt: triggeredAt,
      result: result,
      evidencePrefix: evidencePrefix,
      candidateBase: candidateBase,
    );
    await runs.insert(run);
    return run;
  }

  Future<LearningRun> buildRun({
    required DateTime triggeredAt,
    LearningRunResult result = LearningRunResult.candidate,
    String evidencePrefix = 'candidate',
    int candidateBase = 98,
  }) async {
    final active = await versions.getActive();
    final observations = <EnergyObservation>[
      for (var index = 0; index < 14; index++)
        _observation(index, active: active, idPrefix: evidencePrefix),
    ];
    final evidence = const ShadowEvidenceBuilder()
        .buildAll(
          observations: observations,
          morningLifeDays: {for (final item in observations) item.lifeDay},
          settledLifeDays: {for (final item in observations) item.lifeDay},
          config: ShadowLearningConfig.evidenceReadinessV1(),
        )
        .single;
    final snapshot =
        jsonDecode(evidence.evidenceSnapshotJson) as Map<String, Object?>;
    final hashInput = snapshot['hashInput']! as Map<String, Object?>;
    hashInput['algorithmVersion'] = _algorithm;
    hashInput['configVersion'] = _config;
    const encoder = CanonicalJsonEncoder();
    final evidenceHash = sha256
        .convert(utf8.encode(encoder.encode(hashInput)))
        .toString();
    final candidateValues = result == LearningRunResult.candidate
        ? encoder.encode({'baseEnergy': candidateBase})
        : null;
    final reasons = switch (result) {
      LearningRunResult.candidate => const ['stableCandidate'],
      LearningRunResult.worsened => const ['postActivationWorsened'],
      LearningRunResult.improved => const ['postActivationImproved'],
      LearningRunResult.noChange => const ['noUsefulChange'],
      LearningRunResult.unstable => const ['directionUnstable'],
      _ => const ['testResult'],
    };
    return LearningRun(
      id: deterministicLearningRunId(
        parameterFamily: LearningParameterFamily.baseline,
        sourceModelIdentity: evidence.sourceModelIdentity,
        algorithmVersion: _algorithm,
        configVersion: _config,
        evidenceHash: evidenceHash,
      ),
      parameterFamily: LearningParameterFamily.baseline,
      sourceModelIdentity: evidence.sourceModelIdentity,
      sourcePersonalizationVersionId: active.id,
      status: LearningRunStatus.completed,
      result: result,
      evidenceSnapshotJson: encoder.encode(snapshot),
      evidenceHash: evidenceHash,
      evidenceHashVersion: canonicalEvidenceHashV1,
      algorithmVersion: _algorithm,
      configVersion: _config,
      currentValuesJson: encoder.encode({'baseEnergy': active.baseEnergy}),
      candidateValuesJson: candidateValues,
      reasonCodesJson: encoder.encode(reasons),
      triggeredAt: triggeredAt.toUtc(),
      completedAt: triggeredAt.toUtc().add(const Duration(minutes: 1)),
    );
  }
}

EnergyObservation _observation(
  int index, {
  required PersonalizationVersion active,
  required String idPrefix,
}) {
  final date = DateTime.utc(2026, 7, 19).add(Duration(days: index * 2));
  final lifeDay = LifeDay(date.year, date.month, date.day);
  const actualState = AbsoluteEnergyState.okay;
  const estimate = 50;
  const initialEstimate = 100;
  final comparison = const ObservationComparisonService().compare(
    actualState: actualState,
    estimate: estimate,
    initialEstimate: initialEstimate,
  );
  final regime = const ModelRegimeKeyBuilder().build(
    referenceType: ObservationReferenceType.currentMoment,
    baseEnergy: active.baseEnergy,
    ruleVersion: energyRulesV2MvpAVersion,
    comparisonBandVersion: mvpBComparisonBandV1,
    effectiveModelFingerprint: active.effectiveModelFingerprint,
    modelRegimeEpoch: active.modelRegimeEpoch,
  );
  return EnergyObservation(
    id: '$idPrefix-${index.toString().padLeft(2, '0')}',
    lifeDay: lifeDay,
    type: EnergyObservationType.dailyAbsolute,
    absoluteState: actualState,
    relativeState: null,
    estimateAtObservation: estimate,
    observedAt: DateTime.utc(lifeDay.year, lifeDay.month, lifeDay.day, 12),
    contractVersion: mvpBObservationContractV1,
    referenceType: ObservationReferenceType.currentMoment,
    initialEstimateAtObservation: initialEstimate,
    estimatedOrdinalAtObservation: comparison.estimatedOrdinal,
    baseEnergyAtObservation: active.baseEnergy,
    ruleVersionAtObservation: energyRulesV2MvpAVersion,
    comparisonBandVersion: mvpBComparisonBandV1,
    personalizationVersionAtObservation:
        active.creationSource == PersonalizationCreationSource.initial
        ? fixedMvpAPersonalizationVersion
        : active.id,
    effectiveModelFingerprintAtObservation: active.effectiveModelFingerprint,
    modelRegimeEpochAtObservation: active.modelRegimeEpoch,
    activeActivityCountAtObservation: 1,
    coverageState: ObservationCoverageState.confirmed,
    modelRegimeKey: regime,
  );
}

final class _FailingLearningNoticesRepository
    implements LearningNoticesRepository {
  const _FailingLearningNoticesRepository(this.delegate);

  final LearningNoticesRepository delegate;

  @override
  Future<void> insert(LearningNotice notice) {
    throw StateError('injectedNoticeFailure');
  }

  @override
  Future<LearningNotice?> find(String id) => delegate.find(id);

  @override
  Future<List<LearningNotice>> list() => delegate.list();

  @override
  Future<void> update(LearningNotice notice) => delegate.update(notice);
}

final class _SeedClock implements Clock {
  const _SeedClock();

  @override
  DateTime now() => DateTime.utc(2026, 8, 1, 4);
}
