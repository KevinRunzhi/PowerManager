import 'dart:async';

import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/domain/energy/energy_calculator.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
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
}

final class ActivityUseCases implements ActivityMutator {
  ActivityUseCases({
    required this.clock,
    required this.lifeDayCalculator,
    required this.transactionRunner,
    required this.preparer,
    required this.activities,
    required this.rules,
    required this.summaries,
    required this.projectionService,
    this.calculator = const EnergyCalculator(),
  });

  final Clock clock;
  final LifeDayCalculator lifeDayCalculator;
  final TransactionRunner transactionRunner;
  final OperationPreparer preparer;
  final ActivityRecordsRepository activities;
  final RuleConfigVersionsRepository rules;
  final DailySummariesRepository summaries;
  final CurrentDayProjectionService projectionService;
  final EnergyCalculator calculator;

  Future<void> _tail = Future.value();

  @override
  Future<ActivityMutationResult> create(ActivityDraft draft) {
    return _serialized(() async {
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
        final config = await _loadRule(prepared.current.ruleVersion);
        final theoreticalDelta = calculator.calculateTheoreticalDelta(
          config: config,
          subcategory: draft.subcategory,
          duration: draft.duration,
        );
        final nowUtc = clock.now().toUtc();
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
        final current = await _replayAndPersist(prepared.current);
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
    return _serialized(() async {
      _validateCategory(category, subcategory);
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        await _ensureWritable(prepared);
        final existing = await activities.find(activityId);
        _ensureActiveCurrent(existing, prepared);
        final validatedCompletion = _validateCompletion(completedAt, prepared);
        final config = await _loadRule(prepared.current.ruleVersion);
        final theoreticalDelta = calculator.calculateTheoreticalDelta(
          config: config,
          subcategory: subcategory,
          duration: duration,
        );
        final changed = StoredEstimatedActivity(
          id: existing!.id,
          lifeDay: existing.lifeDay,
          completedAt: validatedCompletion,
          createdAt: existing.createdAt,
          updatedAt: clock.now().toUtc(),
          category: category,
          subcategory: subcategory,
          duration: duration,
          theoreticalDelta: theoreticalDelta,
          appliedDelta: existing.appliedDelta,
          ruleVersion: prepared.current.ruleVersion,
          status: ActivityRecordStatus.active,
          deletedAt: null,
        );
        await activities.update(changed);
        final current = await _replayAndPersist(prepared.current);
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
    return _serialized(() async {
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
        await activities.logicallyDelete(activityId, clock.now().toUtc());
        final current = await _replayAndPersist(prepared.current);
        return ActivityMutationResult(
          activity: (await activities.find(activityId))!,
          current: current,
          wasAlreadyApplied: false,
        );
      });
    });
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
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
    final now = clock.now();
    if (completedAt.toUtc().isAfter(now.toUtc())) {
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
    if (activity == null) {
      throw StateError('Activity does not exist');
    }
    if (activity.status != ActivityRecordStatus.active) {
      throw StateError('Activity ${activity.id} is already deleted');
    }
    if (activity.lifeDay != prepared.current.lifeDay) {
      throw StateError('Settled history is read-only');
    }
  }

  Future<EnergyRuleConfig> _loadRule(String version) async {
    final stored = await rules.find(version);
    if (stored == null) {
      throw StateError('Rule version $version does not exist');
    }
    final rawRules = stored.values['activityRules'];
    if (rawRules is! Map<String, Object?>) {
      throw FormatException('Rule version $version has no activityRules');
    }
    return EnergyRuleConfig(
      ruleVersion: version,
      rules: [
        for (final subcategory in ActivitySubcategory.values)
          SubcategoryEnergyRule(
            subcategory: subcategory,
            deltas: {
              for (final duration in DurationSlot.values)
                duration: _readDelta(rawRules, subcategory, duration),
            },
          ),
      ],
    )..validateOrThrow();
  }

  int _readDelta(
    Map<String, Object?> rawRules,
    ActivitySubcategory subcategory,
    DurationSlot duration,
  ) {
    final rawRow = rawRules[subcategory.code];
    if (rawRow is! Map<String, Object?>) {
      throw FormatException('Missing rule row ${subcategory.code}');
    }
    final value = rawRow[duration.minutes.toString()];
    if (value is! int) {
      throw FormatException(
        'Missing ${subcategory.code}/${duration.minutes} rule value',
      );
    }
    return value;
  }

  Future<CurrentDayProjection> _replayAndPersist(
    CurrentDayProjection context,
  ) async {
    var replayed = await projectionService.project(
      lifeDay: context.lifeDay,
      baseEstimatedEnergy: context.baseEstimatedEnergy,
      ruleVersion: context.ruleVersion,
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
        await activities.update(
          StoredEstimatedActivity(
            id: activity.id,
            lifeDay: activity.lifeDay,
            completedAt: activity.completedAt,
            createdAt: activity.createdAt,
            updatedAt: activity.updatedAt,
            category: activity.category,
            subcategory: activity.subcategory,
            duration: activity.duration,
            theoreticalDelta: activity.theoreticalDelta,
            appliedDelta: appliedDelta,
            ruleVersion: activity.ruleVersion,
            status: activity.status,
            deletedAt: activity.deletedAt,
          ),
        );
      }
    }
    replayed = await projectionService.project(
      lifeDay: context.lifeDay,
      baseEstimatedEnergy: context.baseEstimatedEnergy,
      ruleVersion: context.ruleVersion,
    );
    return replayed;
  }
}
