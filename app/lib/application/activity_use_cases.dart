import 'package:power_manager/application/activity_feedback_use_cases.dart';
import 'package:power_manager/application/business_write_coordinator.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/energy_rule_config_loader.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/domain/energy/energy_calculator.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day_calculator.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

final class ActivityDraft {
  const ActivityDraft({
    required this.operationId,
    required this.category,
    required this.subcategory,
    required this.duration,
    required this.completedAt,
  });

  final String operationId;
  final ActivityCategory category;
  final ActivitySubcategory subcategory;
  final DurationSlot duration;
  final DateTime completedAt;
}

final class ActivityMutationResult {
  const ActivityMutationResult({
    required this.activity,
    required this.current,
    required this.wasAlreadyApplied,
  });

  final StoredEstimatedActivity activity;
  final CurrentDayProjection current;
  final bool wasAlreadyApplied;
}

abstract interface class ActivityMutator {
  Future<ActivityMutationResult> create(ActivityDraft draft);

  Future<ActivityMutationResult> edit({
    required String activityId,
    required ActivityCategory category,
    required ActivitySubcategory subcategory,
    required DurationSlot duration,
    required DateTime completedAt,
  });

  Future<ActivityMutationResult> delete(String activityId);

  Future<ActivityMutationResult> restore(String activityId);
}

final class ActivityUseCases implements ActivityMutator {
  ActivityUseCases({
    required this.lifeDayCalculator,
    required this.writeCoordinator,
    required this.transactionRunner,
    required this.preparer,
    required this.activities,
    required RuleConfigVersionsRepository rules,
    required this.summaries,
    required this.projectionService,
    required this.feedbackMaintenance,
    this.calculator = const EnergyCalculator(),
  }) : ruleLoader = EnergyRuleConfigLoader(rules);

  final LifeDayCalculator lifeDayCalculator;
  final BusinessWriteCoordinator writeCoordinator;
  final TransactionRunner transactionRunner;
  final OperationPreparer preparer;
  final ActivityRecordsRepository activities;
  final DailySummariesRepository summaries;
  final CurrentDayProjectionService projectionService;
  final ActivityFeedbackMaintenance feedbackMaintenance;
  final EnergyCalculator calculator;
  final EnergyRuleConfigLoader ruleLoader;

  @override
  Future<ActivityMutationResult> create(ActivityDraft draft) {
    return writeCoordinator.run(() async {
      _validateDraft(draft);
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        final existing = await activities.find(draft.operationId);
        if (existing != null) {
          return ActivityMutationResult(
            activity: existing,
            current: prepared.current,
            wasAlreadyApplied: true,
          );
        }
        final completedAt = _validateCompletion(draft.completedAt, prepared);
        await _ensureWritable(prepared);
        final config = await ruleLoader.load(prepared.current.ruleVersion);
        final theoreticalDelta = calculator.calculateTheoreticalDelta(
          config: config,
          subcategory: draft.subcategory,
          duration: draft.duration,
        );
        final nowUtc = prepared.nowUtc;
        final activity = StoredEstimatedActivity(
          id: draft.operationId,
          lifeDay: prepared.current.lifeDay,
          completedAt: completedAt,
          createdAt: nowUtc,
          updatedAt: nowUtc,
          category: draft.category,
          subcategory: draft.subcategory,
          duration: draft.duration,
          theoreticalDelta: theoreticalDelta,
          appliedDelta: theoreticalDelta,
          ruleVersion: prepared.current.ruleVersion,
          status: ActivityRecordStatus.active,
          deletedAt: null,
        );
        await activities.insert(activity);
        final current = await _replayAndPersist(
          prepared.current,
          nowUtc: prepared.nowUtc,
        );
        return ActivityMutationResult(
          activity: (await activities.find(activity.id))!,
          current: current,
          wasAlreadyApplied: false,
        );
      });
    });
  }

  @override
  Future<ActivityMutationResult> edit({
    required String activityId,
    required ActivityCategory category,
    required ActivitySubcategory subcategory,
    required DurationSlot duration,
    required DateTime completedAt,
  }) {
    return writeCoordinator.run(() async {
      _validateCategory(category, subcategory);
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        await _ensureWritable(prepared);
        final existing = await activities.find(activityId);
        _ensureActiveCurrent(existing, prepared);
        final validatedCompletion = _validateCompletion(completedAt, prepared);
        final config = await ruleLoader.load(prepared.current.ruleVersion);
        final theoreticalDelta = calculator.calculateTheoreticalDelta(
          config: config,
          subcategory: subcategory,
          duration: duration,
        );
        final projectedAppliedDelta = prepared.current.projection.activities
            .singleWhere((item) => item.record.id == existing!.id)
            .appliedDelta;
        final isNoOp =
            existing!.category == category &&
            existing.subcategory == subcategory &&
            existing.duration == duration &&
            existing.completedAt.toUtc().isAtSameMomentAs(
              validatedCompletion,
            ) &&
            existing.theoreticalDelta == theoreticalDelta &&
            existing.appliedDelta == projectedAppliedDelta &&
            existing.ruleVersion == prepared.current.ruleVersion;
        if (isNoOp) {
          return ActivityMutationResult(
            activity: existing,
            current: prepared.current,
            wasAlreadyApplied: true,
          );
        }
        final changed = StoredEstimatedActivity(
          id: existing.id,
          lifeDay: existing.lifeDay,
          completedAt: validatedCompletion,
          createdAt: existing.createdAt,
          updatedAt: nextActivityUpdatedAt(
            previous: existing.updatedAt,
            nowUtc: prepared.nowUtc,
          ),
          category: category,
          subcategory: subcategory,
          duration: duration,
          theoreticalDelta: theoreticalDelta,
          appliedDelta: existing.appliedDelta,
          ruleVersion: prepared.current.ruleVersion,
          status: ActivityRecordStatus.active,
          deletedAt: null,
        );
        await feedbackMaintenance.invalidateForSnapshotChange(
          before: existing,
          after: changed,
        );
        await activities.update(changed);
        final current = await _replayAndPersist(
          prepared.current,
          nowUtc: prepared.nowUtc,
        );
        return ActivityMutationResult(
          activity: (await activities.find(activityId))!,
          current: current,
          wasAlreadyApplied: false,
        );
      });
    });
  }

  @override
  Future<ActivityMutationResult> delete(String activityId) {
    return writeCoordinator.run(() async {
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        await _ensureWritable(prepared);
        final existing = await activities.find(activityId);
        if (existing == null) {
          throw StateError('Activity $activityId does not exist');
        }
        if (existing.status == ActivityRecordStatus.deleted) {
          return ActivityMutationResult(
            activity: existing,
            current: prepared.current,
            wasAlreadyApplied: true,
          );
        }
        _ensureActiveCurrent(existing, prepared);
        await feedbackMaintenance.invalidateActive(
          activityId,
          ActivityFeedbackInvalidationReason.activityDeleted,
        );
        await activities.logicallyDelete(
          activityId,
          nextActivityUpdatedAt(
            previous: existing.updatedAt,
            nowUtc: prepared.nowUtc,
          ),
        );
        final current = await _replayAndPersist(
          prepared.current,
          nowUtc: prepared.nowUtc,
        );
        return ActivityMutationResult(
          activity: (await activities.find(activityId))!,
          current: current,
          wasAlreadyApplied: false,
        );
      });
    });
  }

  @override
  Future<ActivityMutationResult> restore(String activityId) {
    return writeCoordinator.run(() async {
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        await _ensureWritable(prepared);
        final existing = await activities.find(activityId);
        _ensureCurrent(existing, prepared);
        if (existing!.status == ActivityRecordStatus.active) {
          return ActivityMutationResult(
            activity: existing,
            current: prepared.current,
            wasAlreadyApplied: true,
          );
        }
        await activities.update(
          StoredEstimatedActivity(
            id: existing.id,
            lifeDay: existing.lifeDay,
            completedAt: existing.completedAt,
            createdAt: existing.createdAt,
            updatedAt: nextActivityUpdatedAt(
              previous: existing.updatedAt,
              nowUtc: prepared.nowUtc,
            ),
            category: existing.category,
            subcategory: existing.subcategory,
            duration: existing.duration,
            theoreticalDelta: existing.theoreticalDelta,
            appliedDelta: existing.appliedDelta,
            ruleVersion: existing.ruleVersion,
            status: ActivityRecordStatus.active,
            deletedAt: null,
            personalizationVersionId: existing.personalizationVersionId,
            factorRegimeStartedLifeDay: existing.factorRegimeStartedLifeDay,
            defaultTheoreticalDelta: existing.defaultTheoreticalDelta,
            factor: existing.factor,
            personalizedTheoreticalDelta: existing.personalizedTheoreticalDelta,
          ),
        );
        final current = await _replayAndPersist(
          prepared.current,
          nowUtc: prepared.nowUtc,
        );
        return ActivityMutationResult(
          activity: (await activities.find(activityId))!,
          current: current,
          wasAlreadyApplied: false,
        );
      });
    });
  }

  void _validateDraft(ActivityDraft draft) {
    if (draft.operationId.trim().isEmpty) {
      throw ArgumentError.value(
        draft.operationId,
        'operationId',
        'Operation id must not be empty',
      );
    }
    _validateCategory(draft.category, draft.subcategory);
  }

  void _validateCategory(
    ActivityCategory category,
    ActivitySubcategory subcategory,
  ) {
    if (subcategory.category != category) {
      throw ArgumentError('Subcategory does not belong to category');
    }
  }

  DateTime _validateCompletion(
    DateTime completedAt,
    OperationPreparationResult prepared,
  ) {
    if (completedAt.toUtc().isAfter(prepared.nowUtc)) {
      throw ArgumentError.value(
        completedAt,
        'completedAt',
        'Completion time must not be in the future',
      );
    }
    final lifeDay = lifeDayCalculator.lifeDayFor(completedAt);
    if (lifeDay != prepared.current.lifeDay) {
      throw StateError('Completion time belongs to life day $lifeDay');
    }
    return completedAt.toUtc();
  }

  Future<void> _ensureWritable(OperationPreparationResult prepared) async {
    if (await summaries.findByLifeDay(prepared.current.lifeDay) != null) {
      throw StateError('Life day ${prepared.current.lifeDay} is settled');
    }
  }

  void _ensureActiveCurrent(
    StoredEstimatedActivity? activity,
    OperationPreparationResult prepared,
  ) {
    _ensureCurrent(activity, prepared);
    if (activity!.status != ActivityRecordStatus.active) {
      throw StateError('Activity ${activity.id} is already deleted');
    }
  }

  void _ensureCurrent(
    StoredEstimatedActivity? activity,
    OperationPreparationResult prepared,
  ) {
    if (activity == null) {
      throw StateError('Activity does not exist');
    }
    if (activity.lifeDay != prepared.current.lifeDay) {
      throw StateError('Settled history is read-only');
    }
  }

  Future<CurrentDayProjection> _replayAndPersist(
    CurrentDayProjection context, {
    required DateTime nowUtc,
  }) async {
    var replayed = await projectionService.project(
      lifeDay: context.lifeDay,
      baseEstimatedEnergy: context.baseEstimatedEnergy,
      ruleVersion: context.ruleVersion,
      personalizationVersionId: context.personalizationVersionId,
      effectiveModelFingerprint: context.effectiveModelFingerprint,
      modelRegimeEpoch: context.modelRegimeEpoch,
    );
    final byId = {
      for (final projected in replayed.projection.activities)
        projected.record.id: projected.appliedDelta,
    };
    for (final activity in await activities.listActiveForLifeDay(
      context.lifeDay,
    )) {
      final appliedDelta = byId[activity.id]!;
      if (activity.appliedDelta != appliedDelta) {
        final changed = StoredEstimatedActivity(
          id: activity.id,
          lifeDay: activity.lifeDay,
          completedAt: activity.completedAt,
          createdAt: activity.createdAt,
          updatedAt: nextActivityUpdatedAt(
            previous: activity.updatedAt,
            nowUtc: nowUtc,
          ),
          category: activity.category,
          subcategory: activity.subcategory,
          duration: activity.duration,
          theoreticalDelta: activity.theoreticalDelta,
          appliedDelta: appliedDelta,
          ruleVersion: activity.ruleVersion,
          status: activity.status,
          deletedAt: activity.deletedAt,
          personalizationVersionId: activity.personalizationVersionId,
          factorRegimeStartedLifeDay: activity.factorRegimeStartedLifeDay,
          defaultTheoreticalDelta: activity.defaultTheoreticalDelta,
          factor: activity.factor,
          personalizedTheoreticalDelta: activity.personalizedTheoreticalDelta,
        );
        await feedbackMaintenance.invalidateForSnapshotChange(
          before: activity,
          after: changed,
        );
        await activities.update(changed);
      }
    }
    replayed = await projectionService.project(
      lifeDay: context.lifeDay,
      baseEstimatedEnergy: context.baseEstimatedEnergy,
      ruleVersion: context.ruleVersion,
      personalizationVersionId: context.personalizationVersionId,
      effectiveModelFingerprint: context.effectiveModelFingerprint,
      modelRegimeEpoch: context.modelRegimeEpoch,
    );
    return replayed;
  }
}
