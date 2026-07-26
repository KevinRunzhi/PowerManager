import 'dart:async';

import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

enum MorningCompletionStatus { notAnswered, skipped, completed }

final class DailyObservationResult {
  const DailyObservationResult({
    required this.observation,
    required this.systemEstimate,
    required this.differenceDescription,
    required this.wasUpdated,
  });

  final EnergyObservation observation;
  final int systemEstimate;
  final String differenceDescription;
  final bool wasUpdated;
}

abstract interface class WellbeingMutator {
  Future<CurrentDayProjection> saveMorningCheckIn(MorningCheckIn checkIn);
  Future<void> skipMorning(String receiptId);
  Future<DailyObservationResult> saveDailyAbsolute({
    required String observationId,
    required LifeDay targetLifeDay,
    required AbsoluteEnergyState state,
  });
  Future<EnergyObservation> saveRelativeCorrection({
    required String observationId,
    required RelativeCorrection correction,
  });
}

final class WellbeingUseCases implements WellbeingMutator {
  WellbeingUseCases({
    required this.clock,
    required this.transactionRunner,
    required this.preparer,
    required this.mornings,
    required this.activities,
    required this.observations,
    required this.summaries,
    required this.receipts,
    required this.projectionService,
  });

  final Clock clock;
  final TransactionRunner transactionRunner;
  final OperationPreparer preparer;
  final MorningCheckInsRepository mornings;
  final ActivityRecordsRepository activities;
  final EnergyObservationsRepository observations;
  final DailySummariesRepository summaries;
  final PromptReceiptsRepository receipts;
  final CurrentDayProjectionService projectionService;

  Future<void> _tail = Future.value();

  @override
  Future<CurrentDayProjection> saveMorningCheckIn(MorningCheckIn checkIn) {
    return _serialized(() {
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        if (checkIn.lifeDay != prepared.current.lifeDay) {
          throw StateError('Morning check-in must target the current life day');
        }
        if (checkIn.overallState == MorningOverallState.skipped) {
          throw ArgumentError('Skipped morning does not create a check-in');
        }
        final normalized = MorningCheckIn(
          id: checkIn.id,
          lifeDay: checkIn.lifeDay,
          overallState: checkIn.overallState,
          freeTimeLevel: checkIn.freeTimeLevel,
          pressureSource: checkIn.pressureSource,
          sleepRecovery: checkIn.sleepRecovery,
          morningAdjustment: checkIn.overallState.adjustment,
          completedAt: clock.now().toUtc(),
        );
        final existing = await mornings.findByLifeDay(checkIn.lifeDay);
        if (existing == null) {
          await mornings.insert(normalized);
        } else {
          await mornings.update(
            MorningCheckIn(
              id: existing.id,
              lifeDay: existing.lifeDay,
              overallState: normalized.overallState,
              freeTimeLevel: normalized.freeTimeLevel,
              pressureSource: normalized.pressureSource,
              sleepRecovery: normalized.sleepRecovery,
              morningAdjustment: normalized.morningAdjustment,
              completedAt: normalized.completedAt,
            ),
          );
        }
        return _replayAndPersist(prepared.current);
      });
    });
  }

  @override
  Future<void> skipMorning(String receiptId) {
    return _serialized(() {
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        if (await mornings.findByLifeDay(prepared.current.lifeDay) != null) {
          throw StateError('Morning check-in is already completed');
        }
        final exists = await receipts.exists(
          type: PromptReceiptType.morning,
          scopeKey: prepared.current.lifeDay.toString(),
          action: PromptReceiptAction.skipped,
        );
        if (!exists) {
          await receipts.insert(
            PromptReceipt(
              id: receiptId,
              type: PromptReceiptType.morning,
              scopeKey: prepared.current.lifeDay.toString(),
              action: PromptReceiptAction.skipped,
              occurredAt: clock.now().toUtc(),
            ),
          );
        }
      });
    });
  }

  @override
  Future<DailyObservationResult> saveDailyAbsolute({
    required String observationId,
    required LifeDay targetLifeDay,
    required AbsoluteEnergyState state,
  }) {
    return _serialized(() {
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        final isCurrent = targetLifeDay == prepared.current.lifeDay;
        final isPrevious = targetLifeDay == prepared.current.lifeDay.previous;
        if (!isCurrent && !isPrevious) {
          throw StateError('Daily state can target only today or yesterday');
        }
        final summary = isPrevious
            ? await summaries.findByLifeDay(targetLifeDay)
            : null;
        if (isPrevious && summary == null) {
          throw StateError('Yesterday has no settled estimate');
        }
        final existing = (await observations.listForLifeDay(targetLifeDay))
            .where((item) => item.type == EnergyObservationType.dailyAbsolute)
            .firstOrNull;
        if (isPrevious && existing != null) {
          throw StateError('Yesterday actual state is already read-only');
        }
        final observation = EnergyObservation(
          id: existing?.id ?? observationId,
          lifeDay: targetLifeDay,
          type: EnergyObservationType.dailyAbsolute,
          absoluteState: state,
          relativeState: null,
          estimateAtObservation: null,
          observedAt: clock.now().toUtc(),
        );
        if (existing == null) {
          await observations.insert(observation);
        } else {
          await observations.update(observation);
        }
        final estimate = isCurrent
            ? prepared.current.projection.currentEstimate
            : summary!.finalEstimatedEnergy;
        return DailyObservationResult(
          observation: observation,
          systemEstimate: estimate,
          differenceDescription: describeDifference(
            actual: state,
            estimate: estimate,
            initialEstimate: isCurrent
                ? prepared.current.projection.initialEstimate
                : summary!.initialEstimatedEnergy,
          ),
          wasUpdated: existing != null,
        );
      });
    });
  }

  @override
  Future<EnergyObservation> saveRelativeCorrection({
    required String observationId,
    required RelativeCorrection correction,
  }) {
    return _serialized(() {
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        final observation = EnergyObservation(
          id: observationId,
          lifeDay: prepared.current.lifeDay,
          type: EnergyObservationType.relativeCorrection,
          absoluteState: null,
          relativeState: correction,
          estimateAtObservation: prepared.current.projection.currentEstimate,
          observedAt: clock.now().toUtc(),
        );
        await observations.insert(observation);
        return observation;
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

  Future<CurrentDayProjection> _replayAndPersist(
    CurrentDayProjection context,
  ) async {
    final replayed = await projectionService.project(
      lifeDay: context.lifeDay,
      baseEstimatedEnergy: context.baseEstimatedEnergy,
      ruleVersion: context.ruleVersion,
    );
    final appliedById = {
      for (final item in replayed.projection.activities)
        item.record.id: item.appliedDelta,
    };
    for (final activity in await activities.listActiveForLifeDay(
      context.lifeDay,
    )) {
      final appliedDelta = appliedById[activity.id]!;
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
    return replayed;
  }
}

String describeDifference({
  required AbsoluteEnergyState actual,
  required int estimate,
  required int initialEstimate,
}) {
  final estimatedLevel = switch (estimate) {
    < 0 => 0,
    _ when estimate * 4 < initialEstimate => 1,
    _ when estimate * 2 < initialEstimate => 2,
    _ when estimate * 5 < initialEstimate * 4 => 3,
    _ => 4,
  };
  final actualLevel = AbsoluteEnergyState.values.indexOf(actual);
  final difference = actualLevel - estimatedLevel;
  if (difference <= -2) {
    return '你的感受比系统估计疲惫不少。';
  }
  if (difference == -1) {
    return '你的感受比系统估计更疲惫一些。';
  }
  if (difference == 0) {
    return '你的感受与系统估计大致一致。';
  }
  if (difference == 1) {
    return '你的感受比系统估计更有余力一些。';
  }
  return '你的感受比系统估计更有余力不少。';
}
