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
        baseEstimatedEnergy: Value(settings.baseEstimatedEnergy),
        pendingBaseEstimatedEnergy: Value(settings.pendingBaseEstimatedEnergy),
        baseEnergyEffectiveLifeDay: Value(settings.baseEnergyEffectiveLifeDay),
        activeRuleVersion: Value(settings.activeRuleVersion),
        pendingRuleVersion: Value(settings.pendingRuleVersion),
        pendingRuleEffectiveLifeDay: Value(
          settings.pendingRuleEffectiveLifeDay,
        ),
        onboardingCompleted: Value(settings.onboardingCompleted),
        updatedAt: Value(settings.updatedAt.toUtc()),
      ),
    );
    _expectOneChanged(changed, 'app settings');
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
    baseEstimatedEnergy: row.baseEstimatedEnergy,
    pendingBaseEstimatedEnergy: row.pendingBaseEstimatedEnergy,
    baseEnergyEffectiveLifeDay: row.baseEnergyEffectiveLifeDay,
    activeRuleVersion: row.activeRuleVersion,
    pendingRuleVersion: row.pendingRuleVersion,
    pendingRuleEffectiveLifeDay: row.pendingRuleEffectiveLifeDay,
    onboardingCompleted: row.onboardingCompleted,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
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
    observedAt: feedback.observedAt.toUtc(),
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
