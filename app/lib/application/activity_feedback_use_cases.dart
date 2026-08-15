import 'package:power_manager/application/business_write_coordinator.dart';
import 'package:power_manager/application/energy_rule_config_loader.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/domain/energy/energy_calculator.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

final class ActivityFeedbackMutationResult {
  const ActivityFeedbackMutationResult({
    required this.feedback,
    required this.wasUpdated,
  });

  final ActivityFeedback feedback;
  final bool wasUpdated;
}

abstract interface class ActivityFeedbackMutator {
  Future<ActivityFeedbackMutationResult> save({
    required String feedbackId,
    required String activityId,
    required DateTime expectedActivityUpdatedAt,
    required ActivityFeedbackDirection direction,
  });
}

final class ActivityFeedbackUseCases implements ActivityFeedbackMutator {
  ActivityFeedbackUseCases({
    required this.writeCoordinator,
    required this.transactionRunner,
    required this.preparer,
    required this.activities,
    required this.feedback,
    required RuleConfigVersionsRepository rules,
    required this.summaries,
    this.calculator = const EnergyCalculator(),
  }) : ruleLoader = EnergyRuleConfigLoader(rules);

  final BusinessWriteCoordinator writeCoordinator;
  final TransactionRunner transactionRunner;
  final OperationPreparer preparer;
  final ActivityRecordsRepository activities;
  final ActivityFeedbackRepository feedback;
  final DailySummariesRepository summaries;
  final EnergyCalculator calculator;
  final EnergyRuleConfigLoader ruleLoader;

  @override
  Future<ActivityFeedbackMutationResult> save({
    required String feedbackId,
    required String activityId,
    required DateTime expectedActivityUpdatedAt,
    required ActivityFeedbackDirection direction,
  }) {
    return writeCoordinator.run(() {
      return transactionRunner.run(() async {
        final prepared = await preparer.prepare(PreparationTrigger.beforeWrite);
        final activity = await activities.find(activityId);
        if (activity == null) {
          throw StateError('activityMissing');
        }
        if (activity.lifeDay != prepared.current.lifeDay ||
            await summaries.findByLifeDay(activity.lifeDay) != null) {
          throw StateError('lifeDaySettled');
        }
        if (activity.status != ActivityRecordStatus.active) {
          throw StateError('activityDeleted');
        }
        if (!activity.updatedAt.toUtc().isAtSameMomentAs(
          expectedActivityUpdatedAt.toUtc(),
        )) {
          throw StateError('staleActivity');
        }
        final config = await ruleLoader.load(activity.ruleVersion);
        final expectedTheoretical = calculator.calculateTheoreticalDelta(
          config: config,
          subcategory: activity.subcategory,
          duration: activity.duration,
        );
        if (expectedTheoretical != activity.theoreticalDelta) {
          throw StateError('activityRuleIntegrityFailure');
        }
        final existing = await feedback.findActiveForActivity(activity.id);
        if (existing == null && feedbackId.trim().isEmpty) {
          throw ArgumentError.value(
            feedbackId,
            'feedbackId',
            'feedbackId must not be empty',
          );
        }
        final nowUtc = prepared.nowUtc.isBefore(activity.updatedAt.toUtc())
            ? activity.updatedAt.toUtc()
            : prepared.nowUtc;
        final saved = ActivityFeedback(
          id: existing?.id ?? feedbackId,
          activityRecordId: activity.id,
          lifeDay: activity.lifeDay,
          subcategorySnapshot: activity.subcategory,
          durationSnapshot: activity.duration,
          theoreticalDeltaSnapshot: activity.theoreticalDelta,
          appliedDeltaSnapshot: activity.appliedDelta,
          impactSignSnapshot: activityImpactSign(activity.theoreticalDelta),
          ruleVersionSnapshot: activity.ruleVersion,
          activityUpdatedAtSnapshot: activity.updatedAt.toUtc(),
          direction: direction,
          status: ActivityFeedbackStatus.active,
          invalidationReason: null,
          observedAt: nowUtc,
        );
        if (existing == null) {
          await feedback.insert(saved);
        } else {
          await feedback.update(saved);
        }
        return ActivityFeedbackMutationResult(
          feedback: saved,
          wasUpdated: existing != null,
        );
      });
    });
  }
}

final class ActivityFeedbackMaintenance {
  const ActivityFeedbackMaintenance(this.feedback);

  final ActivityFeedbackRepository feedback;

  Future<bool> invalidateActive(
    String activityId,
    ActivityFeedbackInvalidationReason reason,
  ) async {
    final existing = await feedback.findActiveForActivity(activityId);
    if (existing == null) {
      return false;
    }
    await feedback.update(
      ActivityFeedback(
        id: existing.id,
        activityRecordId: existing.activityRecordId,
        lifeDay: existing.lifeDay,
        subcategorySnapshot: existing.subcategorySnapshot,
        durationSnapshot: existing.durationSnapshot,
        theoreticalDeltaSnapshot: existing.theoreticalDeltaSnapshot,
        appliedDeltaSnapshot: existing.appliedDeltaSnapshot,
        impactSignSnapshot: existing.impactSignSnapshot,
        ruleVersionSnapshot: existing.ruleVersionSnapshot,
        activityUpdatedAtSnapshot: existing.activityUpdatedAtSnapshot,
        direction: existing.direction,
        status: ActivityFeedbackStatus.invalidated,
        invalidationReason: reason,
        observedAt: existing.observedAt,
      ),
    );
    return true;
  }

  Future<bool> invalidateForSnapshotChange({
    required StoredEstimatedActivity before,
    required StoredEstimatedActivity after,
    ActivityFeedbackInvalidationReason reason =
        ActivityFeedbackInvalidationReason.activityEdited,
  }) {
    if (!activityFeedbackSnapshotChanged(before, after)) {
      return Future.value(false);
    }
    return invalidateActive(before.id, reason);
  }
}

ActivityImpactSign activityImpactSign(int theoreticalDelta) {
  if (theoreticalDelta < 0) return ActivityImpactSign.consumption;
  if (theoreticalDelta > 0) return ActivityImpactSign.recovery;
  return ActivityImpactSign.zero;
}

bool activityFeedbackSnapshotChanged(
  StoredEstimatedActivity before,
  StoredEstimatedActivity after,
) {
  return before.lifeDay != after.lifeDay ||
      before.subcategory != after.subcategory ||
      before.duration != after.duration ||
      before.theoreticalDelta != after.theoreticalDelta ||
      before.appliedDelta != after.appliedDelta ||
      before.ruleVersion != after.ruleVersion ||
      !before.updatedAt.toUtc().isAtSameMomentAs(after.updatedAt.toUtc());
}

DateTime nextActivityUpdatedAt({
  required DateTime previous,
  required DateTime nowUtc,
}) {
  final normalizedPrevious = previous.toUtc();
  final normalizedNow = nowUtc.toUtc();
  if (normalizedNow.isAfter(normalizedPrevious)) {
    return normalizedNow;
  }
  return normalizedPrevious.add(const Duration(microseconds: 1));
}
