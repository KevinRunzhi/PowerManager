import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';
import 'package:power_manager/data/db/app_database.dart';

final class DriftAppSettingsRepository implements AppSettingsRepository {
  const DriftAppSettingsRepository(this.dao);

  final AppSettingsDao dao;

  @override
  Future<AppSettings> get() async => _mapSettings(await dao.getSettings());

  @override
  Future<void> save(AppSettings settings) async {
    final changed = await dao.updateSettings(
      AppSettingsTableCompanion(
        activeRuleVersion: Value(settings.activeRuleVersion),
        pendingRuleVersion: Value(settings.pendingRuleVersion),
        pendingRuleEffectiveLifeDay: Value(
          settings.pendingRuleEffectiveLifeDay,
        ),
        onboardingCompleted: Value(settings.onboardingCompleted),
        baselineLearningMode: Value(settings.baselineLearningMode),
        activityImpactLearningMode: Value(settings.activityImpactLearningMode),
        baselineLearningSuspended: Value(settings.baselineLearningSuspended),
        baselineLearningSuspendedAt: Value(
          settings.baselineLearningSuspendedAt?.toUtc(),
        ),
        baselineLearningSuspensionReason: Value(
          settings.baselineLearningSuspensionReason,
        ),
        activityImpactLearningSuspended: Value(
          settings.activityImpactLearningSuspended,
        ),
        activityImpactLearningSuspendedAt: Value(
          settings.activityImpactLearningSuspendedAt?.toUtc(),
        ),
        activityImpactLearningSuspensionReason: Value(
          settings.activityImpactLearningSuspensionReason,
        ),
        baselineLearningCooldownUntil: Value(
          settings.baselineLearningCooldownUntil?.toUtc(),
        ),
        activityImpactLearningCooldownUntil: Value(
          settings.activityImpactLearningCooldownUntil?.toUtc(),
        ),
        updatedAt: Value(settings.updatedAt.toUtc()),
      ),
    );
    _expectOneChanged(changed, 'app settings');
  }
}

final class DriftPersonalizationVersionsRepository
    implements PersonalizationVersionsRepository {
  const DriftPersonalizationVersionsRepository(this.dao);

  final PersonalizationVersionsDao dao;

  @override
  Future<void> insert(PersonalizationVersion version) {
    return dao.insertVersion(_personalizationVersionCompanion(version));
  }

  @override
  Future<void> update(PersonalizationVersion version) async {
    final changed = await dao.updateById(
      version.id,
      PersonalizationVersionsTableCompanion(
        parentVersionId: Value(version.parentVersionId),
        effectiveModelFingerprint: Value(version.effectiveModelFingerprint),
        modelRegimeEpoch: Value(version.modelRegimeEpoch),
        creationSource: Value(version.creationSource),
        scheduleSource: Value(version.scheduleSource),
        sourceLearningRunId: Value(version.sourceLearningRunId),
        algorithmVersion: Value(version.algorithmVersion),
        configVersion: Value(version.configVersion),
        changedParameterFamily: Value(version.changedParameterFamily),
        baseEnergy: Value(version.baseEnergy),
        baselineAnchorEnergy: Value(version.baselineAnchorEnergy),
        status: Value(version.status),
        effectiveLifeDay: Value(version.effectiveLifeDay),
        createdAt: Value(version.createdAt.toUtc()),
        activatedAt: Value(version.activatedAt?.toUtc()),
        endedAt: Value(version.endedAt?.toUtc()),
        transitionReason: Value(version.transitionReason),
      ),
    );
    _expectOneChanged(changed, 'personalization version ${version.id}');
  }

  @override
  Future<bool> updateIfStatus(
    PersonalizationVersion version,
    PersonalizationVersionStatus expectedStatus,
  ) async {
    final companion = _personalizationVersionUpdateCompanion(version);
    final changed = await dao.updateByIdAndStatus(
      version.id,
      expectedStatus,
      companion,
    );
    if (changed > 1) {
      throw StateError(
        'Expected at most one personalization version ${version.id}',
      );
    }
    return changed == 1;
  }

  @override
  Future<PersonalizationVersion?> find(String id) async {
    final row = await dao.findById(id);
    return row == null ? null : _mapPersonalizationVersion(row);
  }

  @override
  Future<PersonalizationVersion> getActive() async {
    return _mapPersonalizationVersion(await dao.getActive());
  }

  @override
  Future<PersonalizationVersion?> findPending() async {
    final row = await dao.findPending();
    return row == null ? null : _mapPersonalizationVersion(row);
  }

  @override
  Future<List<PersonalizationVersion>> list() async {
    return (await dao.listAll()).map(_mapPersonalizationVersion).toList();
  }
}

final class DriftLearningConsentsRepository
    implements LearningConsentsRepository {
  const DriftLearningConsentsRepository(this.dao);

  final LearningConsentsDao dao;

  @override
  Future<void> insert(LearningConsent consent) {
    return dao.insertConsent(
      LearningConsentsTableCompanion.insert(
        parameterFamily: consent.parameterFamily,
        disclosureVersion: consent.disclosureVersion,
        acceptedAt: consent.acceptedAt.toUtc(),
      ),
    );
  }

  @override
  Future<bool> exists({
    required LearningParameterFamily parameterFamily,
    required String disclosureVersion,
  }) {
    return dao.exists(
      parameterFamily: parameterFamily,
      disclosureVersion: disclosureVersion,
    );
  }

  @override
  Future<List<LearningConsent>> list() async {
    return (await dao.listAll()).map(_mapLearningConsent).toList();
  }
}

final class DriftLearningNoticesRepository
    implements LearningNoticesRepository {
  const DriftLearningNoticesRepository(this.dao);

  final LearningNoticesDao dao;

  @override
  Future<void> insert(LearningNotice notice) {
    return dao.insertNotice(_learningNoticeCompanion(notice));
  }

  @override
  Future<void> update(LearningNotice notice) async {
    final changed = await dao.updateById(
      notice.id,
      LearningNoticesTableCompanion(
        parameterFamily: Value(notice.parameterFamily),
        type: Value(notice.type),
        personalizationVersionId: Value(notice.personalizationVersionId),
        learningRunId: Value(notice.learningRunId),
        dedupKey: Value(notice.dedupKey),
        status: Value(notice.status),
        reasonCode: Value(notice.reasonCode),
        createdAt: Value(notice.createdAt.toUtc()),
        seenAt: Value(notice.seenAt?.toUtc()),
        dismissedAt: Value(notice.dismissedAt?.toUtc()),
      ),
    );
    _expectOneChanged(changed, 'learning notice ${notice.id}');
  }

  @override
  Future<LearningNotice?> find(String id) async {
    final row = await dao.findById(id);
    return row == null ? null : _mapLearningNotice(row);
  }

  @override
  Future<List<LearningNotice>> list() async {
    return (await dao.listAll()).map(_mapLearningNotice).toList();
  }
}

final class DriftRuleConfigVersionsRepository
    implements RuleConfigVersionsRepository {
  const DriftRuleConfigVersionsRepository(this.dao);

  final RuleConfigVersionsDao dao;

  @override
  Future<void> insert(RuleConfigVersion version) {
    return dao.insertVersion(
      RuleConfigVersionsTableCompanion.insert(
        version: version.version,
        valuesJson: jsonEncode(version.values),
        createdAt: version.createdAt.toUtc(),
      ),
    );
  }

  @override
  Future<RuleConfigVersion?> find(String version) async {
    final row = await dao.findVersion(version);
    return row == null ? null : _mapRuleVersion(row);
  }

  @override
  Future<List<RuleConfigVersion>> list() async {
    return (await dao.listVersions()).map(_mapRuleVersion).toList();
  }
}

final class DriftMorningCheckInsRepository
    implements MorningCheckInsRepository {
  const DriftMorningCheckInsRepository(this.dao);

  final MorningCheckInsDao dao;

  @override
  Future<void> insert(MorningCheckIn checkIn) {
    return dao.insertCheckIn(_checkInCompanion(checkIn));
  }

  @override
  Future<MorningCheckIn?> findByLifeDay(LifeDay lifeDay) async {
    final row = await dao.findByLifeDay(lifeDay);
    return row == null ? null : _mapCheckIn(row);
  }

  @override
  Future<List<MorningCheckIn>> list() async {
    return (await dao.listAll()).map(_mapCheckIn).toList();
  }

  @override
  Future<void> update(MorningCheckIn checkIn) async {
    final changed = await dao.updateById(
      checkIn.id,
      MorningCheckInsTableCompanion(
        lifeDay: Value(checkIn.lifeDay),
        overallState: Value(checkIn.overallState),
        freeTimeLevel: Value(checkIn.freeTimeLevel),
        pressureSource: Value(checkIn.pressureSource),
        sleepRecovery: Value(checkIn.sleepRecovery),
        morningAdjustment: Value(checkIn.morningAdjustment),
        completedAt: Value(checkIn.completedAt.toUtc()),
      ),
    );
    _expectOneChanged(changed, 'morning check-in ${checkIn.id}');
  }

  @override
  Future<void> delete(String id) async {
    _expectOneChanged(await dao.deleteById(id), 'morning check-in $id');
  }
}

final class DriftActivityRecordsRepository
    implements ActivityRecordsRepository {
  const DriftActivityRecordsRepository(this.dao);

  final ActivityRecordsDao dao;

  @override
  Future<void> insert(StoredEstimatedActivity activity) {
    _validateActivityCategory(activity);
    return dao.insertRecord(_activityCompanion(activity));
  }

  @override
  Future<StoredEstimatedActivity?> find(String id) async {
    final row = await dao.findById(id);
    return row == null ? null : _mapActivity(row);
  }

  @override
  Future<List<StoredEstimatedActivity>> listActiveForLifeDay(
    LifeDay lifeDay,
  ) async {
    return (await dao.listActiveForLifeDay(lifeDay)).map(_mapActivity).toList();
  }

  @override
  Future<List<StoredEstimatedActivity>> listAllForLifeDay(
    LifeDay lifeDay,
  ) async {
    return (await dao.listAllForLifeDay(lifeDay)).map(_mapActivity).toList();
  }

  @override
  Future<List<StoredEstimatedActivity>> listAllForExport() async {
    return (await dao.listAllForExport()).map(_mapActivity).toList();
  }

  @override
  Future<void> update(StoredEstimatedActivity activity) async {
    _validateActivityCategory(activity);
    final changed = await dao.updateById(
      activity.id,
      ActivityRecordsTableCompanion(
        lifeDay: Value(activity.lifeDay),
        completedAt: Value(activity.completedAt.toUtc()),
        updatedAt: Value(activity.updatedAt.toUtc()),
        category: Value(activity.category),
        subcategory: Value(activity.subcategory),
        duration: Value(activity.duration),
        theoreticalDelta: Value(activity.theoreticalDelta),
        appliedDelta: Value(activity.appliedDelta),
        defaultTheoreticalDelta: Value(activity.defaultTheoreticalDelta),
        factor: Value(activity.factor),
        personalizedTheoreticalDelta: Value(
          activity.personalizedTheoreticalDelta,
        ),
        personalizationVersionId: Value(activity.personalizationVersionId),
        factorRegimeStartedLifeDay: Value(activity.factorRegimeStartedLifeDay),
        ruleVersion: Value(activity.ruleVersion),
        status: Value(activity.status),
        deletedAt: Value(activity.deletedAt?.toUtc()),
      ),
    );
    _expectOneChanged(changed, 'activity ${activity.id}');
  }

  @override
  Future<void> logicallyDelete(String id, DateTime deletedAt) async {
    final utcDeletedAt = deletedAt.toUtc();
    final changed = await dao.updateById(
      id,
      ActivityRecordsTableCompanion(
        status: const Value(ActivityRecordStatus.deleted),
        deletedAt: Value(utcDeletedAt),
        updatedAt: Value(utcDeletedAt),
      ),
    );
    _expectOneChanged(changed, 'activity $id');
  }
}

final class DriftEnergyObservationsRepository
    implements EnergyObservationsRepository {
  const DriftEnergyObservationsRepository(this.dao);

  final EnergyObservationsDao dao;

  @override
  Future<void> insert(EnergyObservation observation) {
    return dao.insertObservation(
      EnergyObservationsTableCompanion.insert(
        id: observation.id,
        lifeDay: observation.lifeDay,
        type: observation.type,
        absoluteState: Value(observation.absoluteState),
        relativeState: Value(observation.relativeState),
        estimateAtObservation: Value(observation.estimateAtObservation),
        contractVersion: Value(observation.contractVersion),
        referenceType: Value(observation.referenceType),
        initialEstimateAtObservation: Value(
          observation.initialEstimateAtObservation,
        ),
        estimatedOrdinalAtObservation: Value(
          observation.estimatedOrdinalAtObservation,
        ),
        baseEnergyAtObservation: Value(observation.baseEnergyAtObservation),
        ruleVersionAtObservation: Value(observation.ruleVersionAtObservation),
        comparisonBandVersion: Value(observation.comparisonBandVersion),
        personalizationVersionAtObservation: Value(
          observation.personalizationVersionAtObservation,
        ),
        effectiveModelFingerprintAtObservation: Value(
          observation.effectiveModelFingerprintAtObservation,
        ),
        modelRegimeEpochAtObservation: Value(
          observation.modelRegimeEpochAtObservation,
        ),
        activeActivityCountAtObservation: Value(
          observation.activeActivityCountAtObservation,
        ),
        coverageState: Value(observation.coverageState),
        modelRegimeKey: Value(observation.modelRegimeKey),
        observedAt: observation.observedAt.toUtc(),
      ),
    );
  }

  @override
  Future<void> update(EnergyObservation observation) async {
    final changed = await dao.updateById(
      observation.id,
      EnergyObservationsTableCompanion(
        lifeDay: Value(observation.lifeDay),
        type: Value(observation.type),
        absoluteState: Value(observation.absoluteState),
        relativeState: Value(observation.relativeState),
        estimateAtObservation: Value(observation.estimateAtObservation),
        contractVersion: Value(observation.contractVersion),
        referenceType: Value(observation.referenceType),
        initialEstimateAtObservation: Value(
          observation.initialEstimateAtObservation,
        ),
        estimatedOrdinalAtObservation: Value(
          observation.estimatedOrdinalAtObservation,
        ),
        baseEnergyAtObservation: Value(observation.baseEnergyAtObservation),
        ruleVersionAtObservation: Value(observation.ruleVersionAtObservation),
        comparisonBandVersion: Value(observation.comparisonBandVersion),
        personalizationVersionAtObservation: Value(
          observation.personalizationVersionAtObservation,
        ),
        effectiveModelFingerprintAtObservation: Value(
          observation.effectiveModelFingerprintAtObservation,
        ),
        modelRegimeEpochAtObservation: Value(
          observation.modelRegimeEpochAtObservation,
        ),
        activeActivityCountAtObservation: Value(
          observation.activeActivityCountAtObservation,
        ),
        coverageState: Value(observation.coverageState),
        modelRegimeKey: Value(observation.modelRegimeKey),
        observedAt: Value(observation.observedAt.toUtc()),
      ),
    );
    _expectOneChanged(changed, 'observation ${observation.id}');
  }

  @override
  Future<EnergyObservation?> find(String id) async {
    final row = await dao.findById(id);
    return row == null ? null : _mapObservation(row);
  }

  @override
  Future<List<EnergyObservation>> listForLifeDay(LifeDay lifeDay) async {
    return (await dao.listForLifeDay(lifeDay)).map(_mapObservation).toList();
  }

  @override
  Future<List<EnergyObservation>> list() async {
    return (await dao.listAll()).map(_mapObservation).toList();
  }
}

final class DriftActivityFeedbackRepository
    implements ActivityFeedbackRepository {
  const DriftActivityFeedbackRepository(this.dao);

  final ActivityFeedbackDao dao;

  @override
  Future<void> insert(ActivityFeedback feedback) {
    return dao.insertFeedback(_feedbackCompanion(feedback));
  }

  @override
  Future<void> update(ActivityFeedback feedback) async {
    final changed = await dao.updateById(
      feedback.id,
      ActivityFeedbackTableCompanion(
        activityRecordId: Value(feedback.activityRecordId),
        lifeDay: Value(feedback.lifeDay),
        subcategorySnapshot: Value(feedback.subcategorySnapshot),
        durationSnapshot: Value(feedback.durationSnapshot),
        theoreticalDeltaSnapshot: Value(feedback.theoreticalDeltaSnapshot),
        appliedDeltaSnapshot: Value(feedback.appliedDeltaSnapshot),
        impactSignSnapshot: Value(feedback.impactSignSnapshot),
        ruleVersionSnapshot: Value(feedback.ruleVersionSnapshot),
        activityUpdatedAtSnapshot: Value(
          feedback.activityUpdatedAtSnapshot.toUtc(),
        ),
        direction: Value(feedback.direction),
        status: Value(feedback.status),
        invalidationReason: Value(feedback.invalidationReason),
        defaultTheoreticalDeltaSnapshot: Value(
          feedback.defaultTheoreticalDeltaSnapshot,
        ),
        factorSnapshot: Value(feedback.factorSnapshot),
        personalizedTheoreticalDeltaSnapshot: Value(
          feedback.personalizedTheoreticalDeltaSnapshot,
        ),
        personalizationVersionId: Value(feedback.personalizationVersionId),
        factorRegimeStartedLifeDay: Value(feedback.factorRegimeStartedLifeDay),
        collectionSource: Value(feedback.collectionSource),
        samplingPolicyVersion: Value(feedback.samplingPolicyVersion),
        sampledAt: Value(feedback.sampledAt?.toUtc()),
        sampleId: Value(feedback.sampleId),
        observedAt: Value(feedback.observedAt.toUtc()),
      ),
    );
    _expectOneChanged(changed, 'activity feedback ${feedback.id}');
  }

  @override
  Future<ActivityFeedback?> find(String id) async {
    final row = await dao.findById(id);
    return row == null ? null : _mapFeedback(row);
  }

  @override
  Future<ActivityFeedback?> findActiveForActivity(
    String activityRecordId,
  ) async {
    final row = await dao.findActiveForActivity(activityRecordId);
    return row == null ? null : _mapFeedback(row);
  }

  @override
  Future<List<ActivityFeedback>> listForActivity(
    String activityRecordId,
  ) async {
    return (await dao.listForActivity(
      activityRecordId,
    )).map(_mapFeedback).toList();
  }

  @override
  Future<List<ActivityFeedback>> list() async {
    return (await dao.listAll()).map(_mapFeedback).toList();
  }
}

final class DriftPersonalizationActivityFactorsRepository
    implements PersonalizationActivityFactorsRepository {
  const DriftPersonalizationActivityFactorsRepository(this.dao);

  final PersonalizationActivityFactorsDao dao;

  @override
  Future<void> insert(PersonalizationActivityFactor factor) {
    return dao.insertFactor(_activityFactorCompanion(factor));
  }

  @override
  Future<void> update(PersonalizationActivityFactor factor) async {
    final changed = await dao.updateByKey(
      factor.personalizationVersionId,
      factor.subcategory,
      factor.impactSign,
      PersonalizationActivityFactorsTableCompanion(
        factor: Value(factor.factor),
        baseActivityRuleVersion: Value(factor.baseActivityRuleVersion),
        sourceLearningRunId: Value(factor.sourceLearningRunId),
        factorRegimeStartedLifeDay: Value(factor.factorRegimeStartedLifeDay),
      ),
    );
    _expectOneChanged(
      changed,
      'activity factor ${factor.personalizationVersionId}/${factor.subcategory.code}/${factor.impactSign.code}',
    );
  }

  @override
  Future<PersonalizationActivityFactor?> find({
    required String personalizationVersionId,
    required ActivitySubcategory subcategory,
    required ActivityImpactSign impactSign,
  }) async {
    final row = await dao.findByKey(
      personalizationVersionId: personalizationVersionId,
      subcategory: subcategory,
      impactSign: impactSign,
    );
    return row == null ? null : _mapActivityFactor(row);
  }

  @override
  Future<List<PersonalizationActivityFactor>> listForVersion(
    String personalizationVersionId,
  ) async => (await dao.listForVersion(
    personalizationVersionId,
  )).map(_mapActivityFactor).toList();

  @override
  Future<List<PersonalizationActivityFactor>> list() async =>
      (await dao.listAll()).map(_mapActivityFactor).toList();
}

final class DriftActivityFeedbackSamplesRepository
    implements ActivityFeedbackSamplesRepository {
  const DriftActivityFeedbackSamplesRepository(this.dao);

  final ActivityFeedbackSamplesDao dao;

  @override
  Future<void> insert(ActivityFeedbackSample sample) =>
      dao.insertSample(_activityFeedbackSampleCompanion(sample));

  @override
  Future<void> update(ActivityFeedbackSample sample) async {
    final changed = await dao.updateById(
      sample.id,
      ActivityFeedbackSamplesTableCompanion(
        activityRecordId: Value(sample.activityRecordId),
        lifeDay: Value(sample.lifeDay),
        samplingPolicyVersion: Value(sample.samplingPolicyVersion),
        status: Value(sample.status),
        selectedAt: Value(sample.selectedAt.toUtc()),
        promptedAt: Value(sample.promptedAt?.toUtc()),
        respondedAt: Value(sample.respondedAt?.toUtc()),
        feedbackId: Value(sample.feedbackId),
        invalidatedAt: Value(sample.invalidatedAt?.toUtc()),
        invalidationReason: Value(sample.invalidationReason),
      ),
    );
    _expectOneChanged(changed, 'activity feedback sample ${sample.id}');
  }

  @override
  Future<ActivityFeedbackSample?> find(String id) async {
    final row = await dao.findById(id);
    return row == null ? null : _mapActivityFeedbackSample(row);
  }

  @override
  Future<ActivityFeedbackSample?> findActiveForActivityPolicy({
    required String activityRecordId,
    required String samplingPolicyVersion,
  }) async {
    final row = await dao.findActiveForActivityPolicy(
      activityRecordId: activityRecordId,
      samplingPolicyVersion: samplingPolicyVersion,
    );
    return row == null ? null : _mapActivityFeedbackSample(row);
  }

  @override
  Future<List<ActivityFeedbackSample>> list() async =>
      (await dao.listAll()).map(_mapActivityFeedbackSample).toList();
}

final class DriftLearningRunsRepository implements LearningRunsRepository {
  const DriftLearningRunsRepository(this.dao);

  final LearningRunsDao dao;

  @override
  Future<void> insert(LearningRun run) {
    return dao.insertRun(_learningRunCompanion(run));
  }

  @override
  Future<void> update(LearningRun run) async {
    final changed = await dao.updateById(
      run.id,
      LearningRunsTableCompanion(
        parameterFamily: Value(run.parameterFamily),
        sourceModelIdentity: Value(run.sourceModelIdentity),
        sourcePersonalizationVersionId: Value(
          run.sourcePersonalizationVersionId,
        ),
        status: Value(run.status),
        result: Value(run.result),
        evidenceSnapshotJson: Value(run.evidenceSnapshotJson),
        evidenceHash: Value(run.evidenceHash),
        evidenceHashVersion: Value(run.evidenceHashVersion),
        algorithmVersion: Value(run.algorithmVersion),
        configVersion: Value(run.configVersion),
        currentValuesJson: Value(run.currentValuesJson),
        candidateValuesJson: Value(run.candidateValuesJson),
        reasonCodesJson: Value(run.reasonCodesJson),
        triggeredAt: Value(run.triggeredAt.toUtc()),
        completedAt: Value(run.completedAt?.toUtc()),
      ),
    );
    _expectOneChanged(changed, 'learning run ${run.id}');
  }

  @override
  Future<LearningRun?> find(String id) async {
    final row = await dao.findById(id);
    return row == null ? null : _mapLearningRun(row);
  }

  @override
  Future<LearningRun?> findByIdempotency({
    required LearningParameterFamily parameterFamily,
    required String sourceModelIdentity,
    required String algorithmVersion,
    required String configVersion,
    required String evidenceHash,
  }) async {
    final row = await dao.findByIdempotency(
      parameterFamily: parameterFamily,
      sourceModelIdentity: sourceModelIdentity,
      algorithmVersion: algorithmVersion,
      configVersion: configVersion,
      evidenceHash: evidenceHash,
    );
    return row == null ? null : _mapLearningRun(row);
  }

  @override
  Future<List<LearningRun>> list() async {
    return (await dao.listAll()).map(_mapLearningRun).toList();
  }
}

final class DriftDailySummariesRepository implements DailySummariesRepository {
  const DriftDailySummariesRepository(this.dao);

  final DailySummariesDao dao;

  @override
  Future<DailySummary> insertOrGet(DailySummary summary) async {
    return _mapSummary(
      await dao.insertOrGet(
        DailySummariesTableCompanion.insert(
          lifeDay: summary.lifeDay,
          baseEstimatedEnergy: summary.baseEstimatedEnergy,
          ruleVersion: summary.ruleVersion,
          morningAdjustment: summary.morningAdjustment,
          shortTermAdjustment: summary.shortTermAdjustment,
          initialEstimatedEnergy: summary.initialEstimatedEnergy,
          finalEstimatedEnergy: summary.finalEstimatedEnergy,
          totalConsumption: summary.totalConsumption,
          totalRecovery: summary.totalRecovery,
          categorySummaryJson: _encodeCategorySummaries(
            summary.categorySummaries,
          ),
          isStandardEffectiveDay: summary.isStandardEffectiveDay,
          isWeakEffectiveDay: summary.isWeakEffectiveDay,
          modelSnapshotSource: summary.modelSnapshotSource,
          personalizationVersionId: Value(summary.personalizationVersionId),
          settledAt: summary.settledAt.toUtc(),
        ),
      ),
    );
  }

  @override
  Future<DailySummary?> findByLifeDay(LifeDay lifeDay) async {
    final row = await dao.findByLifeDay(lifeDay);
    return row == null ? null : _mapSummary(row);
  }

  @override
  Future<List<DailySummary>> list() async {
    return (await dao.listAll()).map(_mapSummary).toList();
  }
}

final class DriftPromptReceiptsRepository implements PromptReceiptsRepository {
  const DriftPromptReceiptsRepository(this.dao);

  final PromptReceiptsDao dao;

  @override
  Future<void> insert(PromptReceipt receipt) {
    return dao.insertReceipt(
      PromptReceiptsTableCompanion.insert(
        id: receipt.id,
        type: receipt.type,
        scopeKey: receipt.scopeKey,
        action: receipt.action,
        occurredAt: receipt.occurredAt.toUtc(),
      ),
    );
  }

  @override
  Future<bool> exists({
    required PromptReceiptType type,
    required String scopeKey,
    required PromptReceiptAction action,
  }) {
    return dao.exists(type: type, scopeKey: scopeKey, action: action);
  }

  @override
  Future<List<PromptReceipt>> list() async {
    return (await dao.listAll()).map(_mapReceipt).toList();
  }
}

AppSettings _mapSettings(AppSettingsRow row) {
  return AppSettings(
    activeRuleVersion: row.activeRuleVersion,
    pendingRuleVersion: row.pendingRuleVersion,
    pendingRuleEffectiveLifeDay: row.pendingRuleEffectiveLifeDay,
    onboardingCompleted: row.onboardingCompleted,
    baselineLearningMode: row.baselineLearningMode,
    activityImpactLearningMode: row.activityImpactLearningMode,
    baselineLearningSuspended: row.baselineLearningSuspended,
    baselineLearningSuspendedAt: row.baselineLearningSuspendedAt?.toUtc(),
    baselineLearningSuspensionReason: row.baselineLearningSuspensionReason,
    activityImpactLearningSuspended: row.activityImpactLearningSuspended,
    activityImpactLearningSuspendedAt: row.activityImpactLearningSuspendedAt
        ?.toUtc(),
    activityImpactLearningSuspensionReason:
        row.activityImpactLearningSuspensionReason,
    baselineLearningCooldownUntil: row.baselineLearningCooldownUntil?.toUtc(),
    activityImpactLearningCooldownUntil: row.activityImpactLearningCooldownUntil
        ?.toUtc(),
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
  );
}

PersonalizationVersion _mapPersonalizationVersion(
  PersonalizationVersionRow row,
) {
  return PersonalizationVersion(
    id: row.id,
    parentVersionId: row.parentVersionId,
    effectiveModelFingerprint: row.effectiveModelFingerprint,
    modelRegimeEpoch: row.modelRegimeEpoch,
    creationSource: row.creationSource,
    scheduleSource: row.scheduleSource,
    sourceLearningRunId: row.sourceLearningRunId,
    algorithmVersion: row.algorithmVersion,
    configVersion: row.configVersion,
    changedParameterFamily: row.changedParameterFamily,
    baseEnergy: row.baseEnergy,
    baselineAnchorEnergy: row.baselineAnchorEnergy,
    status: row.status,
    effectiveLifeDay: row.effectiveLifeDay,
    createdAt: row.createdAt.toUtc(),
    activatedAt: row.activatedAt?.toUtc(),
    endedAt: row.endedAt?.toUtc(),
    transitionReason: row.transitionReason,
  );
}

PersonalizationVersionsTableCompanion _personalizationVersionCompanion(
  PersonalizationVersion version,
) {
  return PersonalizationVersionsTableCompanion.insert(
    id: version.id,
    parentVersionId: Value(version.parentVersionId),
    effectiveModelFingerprint: version.effectiveModelFingerprint,
    modelRegimeEpoch: version.modelRegimeEpoch,
    creationSource: version.creationSource,
    scheduleSource: Value(version.scheduleSource),
    sourceLearningRunId: Value(version.sourceLearningRunId),
    algorithmVersion: version.algorithmVersion,
    configVersion: version.configVersion,
    changedParameterFamily: version.changedParameterFamily,
    baseEnergy: version.baseEnergy,
    baselineAnchorEnergy: version.baselineAnchorEnergy,
    status: version.status,
    effectiveLifeDay: Value(version.effectiveLifeDay),
    createdAt: version.createdAt.toUtc(),
    activatedAt: Value(version.activatedAt?.toUtc()),
    endedAt: Value(version.endedAt?.toUtc()),
    transitionReason: version.transitionReason,
  );
}

PersonalizationVersionsTableCompanion _personalizationVersionUpdateCompanion(
  PersonalizationVersion version,
) {
  return PersonalizationVersionsTableCompanion(
    parentVersionId: Value(version.parentVersionId),
    effectiveModelFingerprint: Value(version.effectiveModelFingerprint),
    modelRegimeEpoch: Value(version.modelRegimeEpoch),
    creationSource: Value(version.creationSource),
    scheduleSource: Value(version.scheduleSource),
    sourceLearningRunId: Value(version.sourceLearningRunId),
    algorithmVersion: Value(version.algorithmVersion),
    configVersion: Value(version.configVersion),
    changedParameterFamily: Value(version.changedParameterFamily),
    baseEnergy: Value(version.baseEnergy),
    baselineAnchorEnergy: Value(version.baselineAnchorEnergy),
    status: Value(version.status),
    effectiveLifeDay: Value(version.effectiveLifeDay),
    createdAt: Value(version.createdAt.toUtc()),
    activatedAt: Value(version.activatedAt?.toUtc()),
    endedAt: Value(version.endedAt?.toUtc()),
    transitionReason: Value(version.transitionReason),
  );
}

LearningConsent _mapLearningConsent(LearningConsentRow row) {
  return LearningConsent(
    parameterFamily: row.parameterFamily,
    disclosureVersion: row.disclosureVersion,
    acceptedAt: row.acceptedAt.toUtc(),
  );
}

LearningNotice _mapLearningNotice(LearningNoticeRow row) {
  return LearningNotice(
    id: row.id,
    parameterFamily: row.parameterFamily,
    type: row.type,
    personalizationVersionId: row.personalizationVersionId,
    learningRunId: row.learningRunId,
    dedupKey: row.dedupKey,
    status: row.status,
    reasonCode: row.reasonCode,
    createdAt: row.createdAt.toUtc(),
    seenAt: row.seenAt?.toUtc(),
    dismissedAt: row.dismissedAt?.toUtc(),
  );
}

LearningNoticesTableCompanion _learningNoticeCompanion(LearningNotice notice) {
  return LearningNoticesTableCompanion.insert(
    id: notice.id,
    parameterFamily: notice.parameterFamily,
    type: notice.type,
    personalizationVersionId: Value(notice.personalizationVersionId),
    learningRunId: Value(notice.learningRunId),
    dedupKey: notice.dedupKey,
    status: notice.status,
    reasonCode: notice.reasonCode,
    createdAt: notice.createdAt.toUtc(),
    seenAt: Value(notice.seenAt?.toUtc()),
    dismissedAt: Value(notice.dismissedAt?.toUtc()),
  );
}

RuleConfigVersion _mapRuleVersion(RuleConfigVersionRow row) {
  final decoded = jsonDecode(row.valuesJson);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Rule config JSON must be an object');
  }
  return RuleConfigVersion(
    version: row.version,
    values: decoded,
    createdAt: row.createdAt.toUtc(),
  );
}

MorningCheckIn _mapCheckIn(MorningCheckInRow row) {
  return MorningCheckIn(
    id: row.id,
    lifeDay: row.lifeDay,
    overallState: row.overallState,
    freeTimeLevel: row.freeTimeLevel,
    pressureSource: row.pressureSource,
    sleepRecovery: row.sleepRecovery,
    morningAdjustment: row.morningAdjustment,
    completedAt: row.completedAt.toUtc(),
  );
}

MorningCheckInsTableCompanion _checkInCompanion(MorningCheckIn checkIn) {
  return MorningCheckInsTableCompanion.insert(
    id: checkIn.id,
    lifeDay: checkIn.lifeDay,
    overallState: checkIn.overallState,
    freeTimeLevel: checkIn.freeTimeLevel,
    pressureSource: checkIn.pressureSource,
    sleepRecovery: checkIn.sleepRecovery,
    morningAdjustment: checkIn.morningAdjustment,
    completedAt: checkIn.completedAt.toUtc(),
  );
}

StoredEstimatedActivity _mapActivity(ActivityRecordRow row) {
  return StoredEstimatedActivity(
    id: row.id,
    lifeDay: row.lifeDay,
    completedAt: row.completedAt.toUtc(),
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    category: row.category,
    subcategory: row.subcategory,
    duration: row.duration,
    theoreticalDelta: row.theoreticalDelta,
    appliedDelta: row.appliedDelta,
    defaultTheoreticalDelta: row.defaultTheoreticalDelta,
    factor: row.factor,
    personalizedTheoreticalDelta: row.personalizedTheoreticalDelta,
    personalizationVersionId: row.personalizationVersionId,
    factorRegimeStartedLifeDay: row.factorRegimeStartedLifeDay,
    ruleVersion: row.ruleVersion,
    status: row.status,
    deletedAt: row.deletedAt?.toUtc(),
  );
}

ActivityRecordsTableCompanion _activityCompanion(
  StoredEstimatedActivity activity,
) {
  return ActivityRecordsTableCompanion.insert(
    id: activity.id,
    lifeDay: activity.lifeDay,
    completedAt: activity.completedAt.toUtc(),
    createdAt: activity.createdAt.toUtc(),
    updatedAt: activity.updatedAt.toUtc(),
    category: activity.category,
    subcategory: activity.subcategory,
    duration: activity.duration,
    theoreticalDelta: activity.theoreticalDelta,
    appliedDelta: activity.appliedDelta,
    defaultTheoreticalDelta: Value(activity.defaultTheoreticalDelta),
    factor: Value(activity.factor),
    personalizedTheoreticalDelta: Value(activity.personalizedTheoreticalDelta),
    personalizationVersionId: Value(activity.personalizationVersionId),
    factorRegimeStartedLifeDay: Value(activity.factorRegimeStartedLifeDay),
    ruleVersion: activity.ruleVersion,
    status: activity.status,
    deletedAt: Value(activity.deletedAt?.toUtc()),
  );
}

EnergyObservation _mapObservation(EnergyObservationRow row) {
  return EnergyObservation(
    id: row.id,
    lifeDay: row.lifeDay,
    type: row.type,
    absoluteState: row.absoluteState,
    relativeState: row.relativeState,
    estimateAtObservation: row.estimateAtObservation,
    observedAt: row.observedAt.toUtc(),
    contractVersion: row.contractVersion,
    referenceType: row.referenceType,
    initialEstimateAtObservation: row.initialEstimateAtObservation,
    estimatedOrdinalAtObservation: row.estimatedOrdinalAtObservation,
    baseEnergyAtObservation: row.baseEnergyAtObservation,
    ruleVersionAtObservation: row.ruleVersionAtObservation,
    comparisonBandVersion: row.comparisonBandVersion,
    personalizationVersionAtObservation:
        row.personalizationVersionAtObservation,
    effectiveModelFingerprintAtObservation:
        row.effectiveModelFingerprintAtObservation,
    modelRegimeEpochAtObservation: row.modelRegimeEpochAtObservation,
    activeActivityCountAtObservation: row.activeActivityCountAtObservation,
    coverageState: row.coverageState,
    modelRegimeKey: row.modelRegimeKey,
  );
}

ActivityFeedback _mapFeedback(ActivityFeedbackRow row) {
  return ActivityFeedback(
    id: row.id,
    activityRecordId: row.activityRecordId,
    lifeDay: row.lifeDay,
    subcategorySnapshot: row.subcategorySnapshot,
    durationSnapshot: row.durationSnapshot,
    theoreticalDeltaSnapshot: row.theoreticalDeltaSnapshot,
    appliedDeltaSnapshot: row.appliedDeltaSnapshot,
    impactSignSnapshot: row.impactSignSnapshot,
    ruleVersionSnapshot: row.ruleVersionSnapshot,
    activityUpdatedAtSnapshot: row.activityUpdatedAtSnapshot.toUtc(),
    direction: row.direction,
    status: row.status,
    invalidationReason: row.invalidationReason,
    defaultTheoreticalDeltaSnapshot: row.defaultTheoreticalDeltaSnapshot,
    factorSnapshot: row.factorSnapshot,
    personalizedTheoreticalDeltaSnapshot:
        row.personalizedTheoreticalDeltaSnapshot,
    personalizationVersionId: row.personalizationVersionId,
    factorRegimeStartedLifeDay: row.factorRegimeStartedLifeDay,
    collectionSource: row.collectionSource,
    samplingPolicyVersion: row.samplingPolicyVersion,
    sampledAt: row.sampledAt?.toUtc(),
    sampleId: row.sampleId,
    observedAt: row.observedAt.toUtc(),
  );
}

ActivityFeedbackTableCompanion _feedbackCompanion(ActivityFeedback feedback) {
  return ActivityFeedbackTableCompanion.insert(
    id: feedback.id,
    activityRecordId: feedback.activityRecordId,
    lifeDay: feedback.lifeDay,
    subcategorySnapshot: feedback.subcategorySnapshot,
    durationSnapshot: feedback.durationSnapshot,
    theoreticalDeltaSnapshot: feedback.theoreticalDeltaSnapshot,
    appliedDeltaSnapshot: feedback.appliedDeltaSnapshot,
    impactSignSnapshot: feedback.impactSignSnapshot,
    ruleVersionSnapshot: feedback.ruleVersionSnapshot,
    activityUpdatedAtSnapshot: feedback.activityUpdatedAtSnapshot.toUtc(),
    direction: feedback.direction,
    status: feedback.status,
    invalidationReason: Value(feedback.invalidationReason),
    defaultTheoreticalDeltaSnapshot: Value(
      feedback.defaultTheoreticalDeltaSnapshot,
    ),
    factorSnapshot: Value(feedback.factorSnapshot),
    personalizedTheoreticalDeltaSnapshot: Value(
      feedback.personalizedTheoreticalDeltaSnapshot,
    ),
    personalizationVersionId: Value(feedback.personalizationVersionId),
    factorRegimeStartedLifeDay: Value(feedback.factorRegimeStartedLifeDay),
    collectionSource: Value(feedback.collectionSource),
    samplingPolicyVersion: Value(feedback.samplingPolicyVersion),
    sampledAt: Value(feedback.sampledAt?.toUtc()),
    sampleId: Value(feedback.sampleId),
    observedAt: feedback.observedAt.toUtc(),
  );
}

PersonalizationActivityFactor _mapActivityFactor(
  PersonalizationActivityFactorRow row,
) => PersonalizationActivityFactor(
  personalizationVersionId: row.personalizationVersionId,
  subcategory: row.subcategory,
  impactSign: row.impactSign,
  factor: row.factor,
  baseActivityRuleVersion: row.baseActivityRuleVersion,
  sourceLearningRunId: row.sourceLearningRunId,
  factorRegimeStartedLifeDay: row.factorRegimeStartedLifeDay,
);

PersonalizationActivityFactorsTableCompanion _activityFactorCompanion(
  PersonalizationActivityFactor factor,
) => PersonalizationActivityFactorsTableCompanion.insert(
  personalizationVersionId: factor.personalizationVersionId,
  subcategory: factor.subcategory,
  impactSign: factor.impactSign,
  factor: factor.factor,
  baseActivityRuleVersion: factor.baseActivityRuleVersion,
  sourceLearningRunId: Value(factor.sourceLearningRunId),
  factorRegimeStartedLifeDay: factor.factorRegimeStartedLifeDay,
);

ActivityFeedbackSample _mapActivityFeedbackSample(
  ActivityFeedbackSampleRow row,
) => ActivityFeedbackSample(
  id: row.id,
  activityRecordId: row.activityRecordId,
  lifeDay: row.lifeDay,
  samplingPolicyVersion: row.samplingPolicyVersion,
  status: row.status,
  selectedAt: row.selectedAt.toUtc(),
  promptedAt: row.promptedAt?.toUtc(),
  respondedAt: row.respondedAt?.toUtc(),
  feedbackId: row.feedbackId,
  invalidatedAt: row.invalidatedAt?.toUtc(),
  invalidationReason: row.invalidationReason,
);

ActivityFeedbackSamplesTableCompanion _activityFeedbackSampleCompanion(
  ActivityFeedbackSample sample,
) => ActivityFeedbackSamplesTableCompanion.insert(
  id: sample.id,
  activityRecordId: sample.activityRecordId,
  lifeDay: sample.lifeDay,
  samplingPolicyVersion: sample.samplingPolicyVersion,
  status: sample.status,
  selectedAt: sample.selectedAt.toUtc(),
  promptedAt: Value(sample.promptedAt?.toUtc()),
  respondedAt: Value(sample.respondedAt?.toUtc()),
  feedbackId: Value(sample.feedbackId),
  invalidatedAt: Value(sample.invalidatedAt?.toUtc()),
  invalidationReason: Value(sample.invalidationReason),
);

LearningRun _mapLearningRun(LearningRunRow row) {
  return LearningRun(
    id: row.id,
    parameterFamily: row.parameterFamily,
    sourceModelIdentity: row.sourceModelIdentity,
    sourcePersonalizationVersionId: row.sourcePersonalizationVersionId,
    status: row.status,
    result: row.result,
    evidenceSnapshotJson: row.evidenceSnapshotJson,
    evidenceHash: row.evidenceHash,
    evidenceHashVersion: row.evidenceHashVersion,
    algorithmVersion: row.algorithmVersion,
    configVersion: row.configVersion,
    currentValuesJson: row.currentValuesJson,
    candidateValuesJson: row.candidateValuesJson,
    reasonCodesJson: row.reasonCodesJson,
    triggeredAt: row.triggeredAt.toUtc(),
    completedAt: row.completedAt?.toUtc(),
  );
}

LearningRunsTableCompanion _learningRunCompanion(LearningRun run) {
  return LearningRunsTableCompanion.insert(
    id: run.id,
    parameterFamily: run.parameterFamily,
    sourceModelIdentity: run.sourceModelIdentity,
    sourcePersonalizationVersionId: Value(run.sourcePersonalizationVersionId),
    status: run.status,
    result: Value(run.result),
    evidenceSnapshotJson: run.evidenceSnapshotJson,
    evidenceHash: run.evidenceHash,
    evidenceHashVersion: run.evidenceHashVersion,
    algorithmVersion: run.algorithmVersion,
    configVersion: run.configVersion,
    currentValuesJson: run.currentValuesJson,
    candidateValuesJson: Value(run.candidateValuesJson),
    reasonCodesJson: run.reasonCodesJson,
    triggeredAt: run.triggeredAt.toUtc(),
    completedAt: Value(run.completedAt?.toUtc()),
  );
}

DailySummary _mapSummary(DailySummaryRow row) {
  return DailySummary(
    lifeDay: row.lifeDay,
    baseEstimatedEnergy: row.baseEstimatedEnergy,
    ruleVersion: row.ruleVersion,
    morningAdjustment: row.morningAdjustment,
    shortTermAdjustment: row.shortTermAdjustment,
    initialEstimatedEnergy: row.initialEstimatedEnergy,
    finalEstimatedEnergy: row.finalEstimatedEnergy,
    totalConsumption: row.totalConsumption,
    totalRecovery: row.totalRecovery,
    categorySummaries: _decodeCategorySummaries(row.categorySummaryJson),
    isStandardEffectiveDay: row.isStandardEffectiveDay,
    isWeakEffectiveDay: row.isWeakEffectiveDay,
    modelSnapshotSource: row.modelSnapshotSource,
    personalizationVersionId: row.personalizationVersionId,
    settledAt: row.settledAt.toUtc(),
  );
}

PromptReceipt _mapReceipt(PromptReceiptRow row) {
  return PromptReceipt(
    id: row.id,
    type: row.type,
    scopeKey: row.scopeKey,
    action: row.action,
    occurredAt: row.occurredAt.toUtc(),
  );
}

String _encodeCategorySummaries(
  Map<ActivityCategory, CategoryEstimatedSummary> summaries,
) {
  return jsonEncode({
    for (final entry in summaries.entries)
      entry.key.code: {
        'durationMinutes': entry.value.durationMinutes,
        'netDelta': entry.value.netDelta,
        'grossDelta': entry.value.grossDelta,
      },
  });
}

Map<ActivityCategory, CategoryEstimatedSummary> _decodeCategorySummaries(
  String source,
) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Category summary JSON must be an object');
  }

  return {
    for (final entry in decoded.entries)
      _categoryFromCode(entry.key): _decodeCategorySummary(
        _categoryFromCode(entry.key),
        entry.value,
      ),
  };
}

CategoryEstimatedSummary _decodeCategorySummary(
  ActivityCategory category,
  Object? source,
) {
  if (source is! Map<String, Object?>) {
    throw FormatException('${category.code} summary must be an object');
  }
  final durationMinutes = source['durationMinutes'];
  final netDelta = source['netDelta'];
  final grossDelta = source['grossDelta'];
  if (durationMinutes is! int || netDelta is! int || grossDelta is! int) {
    throw FormatException('${category.code} summary has invalid fields');
  }
  return CategoryEstimatedSummary(
    category: category,
    durationMinutes: durationMinutes,
    netDelta: netDelta,
    grossDelta: grossDelta,
  );
}

ActivityCategory _categoryFromCode(String code) {
  return ActivityCategory.values.firstWhere(
    (category) => category.code == code,
    orElse: () => throw FormatException('Unknown category code: $code'),
  );
}

void _validateActivityCategory(StoredEstimatedActivity activity) {
  if (activity.category != activity.subcategory.category) {
    throw ArgumentError(
      'Activity category ${activity.category.code} does not match '
      '${activity.subcategory.code}',
    );
  }
}

void _expectOneChanged(int changed, String description) {
  if (changed != 1) {
    throw StateError(
      'Expected to change one $description row, changed $changed',
    );
  }
}
