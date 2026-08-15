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
    ActivityFeedbackCollectionSource collectionSource =
        ActivityFeedbackCollectionSource.userInitiated,
    String? samplingPolicyVersion,
    DateTime? sampledAt,
    String? sampleId,
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
        final expectedDefaultTheoretical = calculator.calculateTheoreticalDelta(
          config: config,
          subcategory: activity.subcategory,
          duration: activity.duration,
        );
        if (expectedDefaultTheoretical != activity.defaultTheoreticalDelta) {
          throw StateError('activityRuleIntegrityFailure');
        }
        if (collectionSource ==
                ActivityFeedbackCollectionSource.sampledPrompt &&
            (sampleId == null ||
                sampleId.trim().isEmpty ||
                samplingPolicyVersion == null ||
                samplingPolicyVersion.trim().isEmpty ||
                activity.personalizationVersionId == null ||
                activity.factorRegimeStartedLifeDay == null)) {
          throw StateError('sampledFeedbackSnapshotIncomplete');
        }
        if (collectionSource ==
                ActivityFeedbackCollectionSource.userInitiated &&
            (sampleId != null ||
                samplingPolicyVersion != null ||
                sampledAt != null)) {
          throw StateError('userInitiatedFeedbackCannotHaveSample');
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
          defaultTheoreticalDeltaSnapshot: activity.defaultTheoreticalDelta,
          factorSnapshot: activity.factor,
          personalizedTheoreticalDeltaSnapshot:
              activity.personalizedTheoreticalDelta,
          personalizationVersionId: activity.personalizationVersionId,
          factorRegimeStartedLifeDay: activity.factorRegimeStartedLifeDay,
          collectionSource: collectionSource,
          samplingPolicyVersion: samplingPolicyVersion,
          sampledAt:
              collectionSource == ActivityFeedbackCollectionSource.sampledPrompt
              ? (sampledAt?.toUtc() ?? nowUtc)
              : null,
          sampleId: sampleId,
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
  const ActivityFeedbackMaintenance(this.feedback, {this.samples});

  final ActivityFeedbackRepository feedback;
  final ActivityFeedbackSamplesRepository? samples;

  Future<bool> invalidateActive(
    String activityId,
    ActivityFeedbackInvalidationReason reason,
  ) async {
    final existing = await feedback.findActiveForActivity(activityId);
    var changed = false;
    if (existing != null) {
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
          defaultTheoreticalDeltaSnapshot:
              existing.defaultTheoreticalDeltaSnapshot,
          factorSnapshot: existing.factorSnapshot,
          personalizedTheoreticalDeltaSnapshot:
              existing.personalizedTheoreticalDeltaSnapshot,
          personalizationVersionId: existing.personalizationVersionId,
          factorRegimeStartedLifeDay: existing.factorRegimeStartedLifeDay,
          collectionSource: existing.collectionSource,
          samplingPolicyVersion: existing.samplingPolicyVersion,
          sampledAt: existing.sampledAt,
          sampleId: existing.sampleId,
        ),
      );
      changed = true;
    }
    if (samples != null) {
      for (final sample in await samples!.list()) {
        if (sample.activityRecordId != activityId || sample.isInvalidated) {
          continue;
        }
        await samples!.update(
          ActivityFeedbackSample(
            id: sample.id,
            activityRecordId: sample.activityRecordId,
            lifeDay: sample.lifeDay,
            samplingPolicyVersion: sample.samplingPolicyVersion,
            status: ActivityFeedbackSampleStatus.invalidated,
            selectedAt: sample.selectedAt,
            promptedAt: sample.promptedAt,
            respondedAt: sample.respondedAt,
            feedbackId: sample.feedbackId,
            invalidatedAt: sample.invalidatedAt ?? sample.selectedAt,
            invalidationReason: reason,
          ),
        );
        changed = true;
      }
    }
    return changed;
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
