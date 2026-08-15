import 'package:power_manager/application/activity_feedback_use_cases.dart';
import 'package:power_manager/application/business_write_coordinator.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/model_regime_key.dart';
import 'package:power_manager/domain/energy/observation_comparison_service.dart';
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
    required ObservationReferenceType referenceType,
    required AbsoluteEnergyState state,
    required ObservationCoverageState coverageState,
  });
  Future<EnergyObservation> saveRelativeCorrection({
    required String observationId,
    required RelativeCorrection correction,
  });
}

final class WellbeingUseCases implements WellbeingMutator {
  WellbeingUseCases({
    required this.writeCoordinator,
    required this.transactionRunner,
    required this.preparer,
    required this.mornings,
    required this.activities,
    required this.observations,
    required this.summaries,
    required this.receipts,
    required this.projectionService,
    required this.feedbackMaintenance,
    this.comparisonService = const ObservationComparisonService(),
    this.regimeKeyBuilder = const ModelRegimeKeyBuilder(),
  });

  final BusinessWriteCoordinator writeCoordinator;
  final TransactionRunner transactionRunner;
  final OperationPreparer preparer;
  final MorningCheckInsRepository mornings;
  final ActivityRecordsRepository activities;
  final EnergyObservationsRepository observations;
  final DailySummariesRepository summaries;
  final PromptReceiptsRepository receipts;
  final CurrentDayProjectionService projectionService;
  final ActivityFeedbackMaintenance feedbackMaintenance;
  final ObservationComparisonService comparisonService;
  final ModelRegimeKeyBuilder regimeKeyBuilder;

  @override
  Future<CurrentDayProjection> saveMorningCheckIn(MorningCheckIn checkIn) {
    return writeCoordinator.run(() {
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
          completedAt: prepared.nowUtc,
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
        return _replayAndPersist(prepared.current, nowUtc: prepared.nowUtc);
      });
    });
  }

  @override
  Future<void> skipMorning(String receiptId) {
    return writeCoordinator.run(() {
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
              occurredAt: prepared.nowUtc,
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
    required ObservationReferenceType referenceType,
    required AbsoluteEnergyState state,
    required ObservationCoverageState coverageState,
  }) {
    return writeCoordinator.run(() {
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        if (coverageState != ObservationCoverageState.confirmed &&
            coverageState != ObservationCoverageState.uncertain) {
          throw ArgumentError.value(
            coverageState,
            'coverageState',
            'A new observation requires confirmed or uncertain coverage',
          );
        }
        final isCurrent =
            referenceType == ObservationReferenceType.currentMoment;
        final expectedTarget = isCurrent
            ? prepared.current.lifeDay
            : prepared.current.lifeDay.previous;
        if (targetLifeDay != expectedTarget) {
          throw StateError('staleSheet');
        }
        final summary = isCurrent
            ? null
            : await summaries.findByLifeDay(targetLifeDay);
        if (!isCurrent && summary == null) {
          throw StateError('missingSettledSummary');
        }
        final existing = (await observations.listForLifeDay(targetLifeDay))
            .where((item) => item.type == EnergyObservationType.dailyAbsolute)
            .firstOrNull;
        if (!isCurrent && existing != null) {
          throw StateError('readOnlyObservation');
        }
        if (isCurrent &&
            existing?.referenceType ==
                ObservationReferenceType.previousLifeDayEnd) {
          throw StateError('readOnlyObservation');
        }
        final estimate = isCurrent
            ? prepared.current.projection.currentEstimate
            : summary!.finalEstimatedEnergy;
        final initialEstimate = isCurrent
            ? prepared.current.projection.initialEstimate
            : summary!.initialEstimatedEnergy;
        final baseEnergy = isCurrent
            ? prepared.current.baseEstimatedEnergy
            : summary!.baseEstimatedEnergy;
        final ruleVersion = isCurrent
            ? prepared.current.ruleVersion
            : summary!.ruleVersion;
        final comparison = comparisonService.compare(
          actualState: state,
          estimate: estimate,
          initialEstimate: initialEstimate,
        );
        if (!comparison.isValid) {
          throw StateError(comparison.failure!.code);
        }
        final activityCount = isCurrent
            ? prepared.current.projection.activities.length
            : (await activities.listActiveForLifeDay(targetLifeDay)).length;
        final modelRegimeKey = regimeKeyBuilder.build(
          referenceType: referenceType,
          baseEnergy: baseEnergy,
          ruleVersion: ruleVersion,
          comparisonBandVersion: mvpBComparisonBandV1,
          effectiveModelFingerprint: fixedMvpAEffectiveModelFingerprint,
          modelRegimeEpoch: fixedMvpAInitialModelRegimeEpoch,
        );
        final observation = EnergyObservation(
          id: existing?.id ?? observationId,
          lifeDay: targetLifeDay,
          type: EnergyObservationType.dailyAbsolute,
          absoluteState: state,
          relativeState: null,
          estimateAtObservation: estimate,
          observedAt: prepared.nowUtc,
          contractVersion: mvpBObservationContractV1,
          referenceType: referenceType,
          initialEstimateAtObservation: initialEstimate,
          estimatedOrdinalAtObservation: comparison.estimatedOrdinal,
          baseEnergyAtObservation: baseEnergy,
          ruleVersionAtObservation: ruleVersion,
          comparisonBandVersion: mvpBComparisonBandV1,
          personalizationVersionAtObservation: fixedMvpAPersonalizationVersion,
          effectiveModelFingerprintAtObservation:
              fixedMvpAEffectiveModelFingerprint,
          modelRegimeEpochAtObservation: fixedMvpAInitialModelRegimeEpoch,
          activeActivityCountAtObservation: activityCount,
          coverageState: coverageState,
          modelRegimeKey: modelRegimeKey,
        );
        if (existing == null) {
          await observations.insert(observation);
        } else {
          await observations.update(observation);
        }
        return DailyObservationResult(
          observation: observation,
          systemEstimate: estimate,
          differenceDescription: describeAlignment(comparison.direction!),
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
    return writeCoordinator.run(() {
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        final observation = EnergyObservation(
          id: observationId,
          lifeDay: prepared.current.lifeDay,
          type: EnergyObservationType.relativeCorrection,
          absoluteState: null,
          relativeState: correction,
          estimateAtObservation: prepared.current.projection.currentEstimate,
          observedAt: prepared.nowUtc,
        );
        await observations.insert(observation);
        return observation;
      });
    });
  }

  Future<CurrentDayProjection> _replayAndPersist(
    CurrentDayProjection context, {
    required DateTime nowUtc,
  }) async {
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
        );
        await feedbackMaintenance.invalidateForSnapshotChange(
          before: activity,
          after: changed,
        );
        await activities.update(changed);
      }
    }
    return replayed;
  }
}

String describeAlignment(ObservationAlignmentDirection direction) =>
    switch (direction) {
      ObservationAlignmentDirection.lower => '你选择的整体状态低于系统在同一参考时刻的对应档位。',
      ObservationAlignmentDirection.aligned => '你选择的整体状态与系统在同一参考时刻属于相同档位。',
      ObservationAlignmentDirection.higher => '你选择的整体状态高于系统在同一参考时刻的对应档位。',
    };
