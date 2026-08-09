import 'dart:collection';

import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/energy_rule_config_loader.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/estimated_activity.dart';
import 'package:power_manager/domain/repositories/repositories.dart';

final class ActivityImpactPreview {
  const ActivityImpactPreview({
    required this.subcategory,
    required this.duration,
    required this.theoreticalDelta,
    required this.projectedAppliedDelta,
    required this.estimateBefore,
    required this.estimateAfter,
  });

  final ActivitySubcategory subcategory;
  final DurationSlot duration;
  final int theoreticalDelta;
  final int projectedAppliedDelta;
  final int estimateBefore;
  final int estimateAfter;

  bool get isRecoveryLimited =>
      theoreticalDelta > 0 && projectedAppliedDelta < theoreticalDelta;
}

typedef ActivityImpactCatalog =
    Map<ActivitySubcategory, Map<DurationSlot, ActivityImpactPreview>>;

abstract interface class ActivityImpactPreviewer {
  Future<ActivityImpactCatalog> previewCatalog({
    required CurrentDayProjection current,
    required DateTime completedAt,
    String? editingActivityId,
  });
}

final class ActivityImpactPreviewService implements ActivityImpactPreviewer {
  const ActivityImpactPreviewService({
    required this.activities,
    required this.ruleLoader,
    this.projector = const CurrentDayProjector(),
  });

  final ActivityRecordsRepository activities;
  final EnergyRuleConfigLoader ruleLoader;
  final CurrentDayProjector projector;

  @override
  Future<ActivityImpactCatalog> previewCatalog({
    required CurrentDayProjection current,
    required DateTime completedAt,
    String? editingActivityId,
  }) async {
    final completedAtUtc = completedAt.toUtc();
    final config = await ruleLoader.load(current.ruleVersion);
    final stored = await activities.listActiveForLifeDay(current.lifeDay);
    final editing = editingActivityId == null
        ? null
        : stored.where((item) => item.id == editingActivityId).firstOrNull;
    if (editingActivityId != null && editing == null) {
      throw StateError('Activity $editingActivityId does not exist');
    }
    final baseRecords = [
      for (final item in stored)
        if (item.id != editingActivityId) item.toReplayRecord(),
    ];
    final candidateId = editing?.id ?? '__activity-impact-preview__';
    final createdAt = editing?.createdAt ?? completedAtUtc;
    final result =
        <ActivitySubcategory, Map<DurationSlot, ActivityImpactPreview>>{};

    for (final subcategory in ActivitySubcategory.values) {
      final durations = <DurationSlot, ActivityImpactPreview>{};
      for (final duration in DurationSlot.values) {
        final theoreticalDelta = config.theoreticalDelta(subcategory, duration);
        final candidate = EstimatedActivityRecord(
          id: candidateId,
          completedAt: completedAtUtc,
          createdAt: createdAt,
          subcategory: subcategory,
          duration: duration,
          ruleVersion: current.ruleVersion,
          theoreticalDelta: theoreticalDelta,
        );
        final projection = projector.project(
          initialEstimate: current.projection.initialEstimate,
          records: [...baseRecords, candidate],
          morningCheckInCompleted: current.morningCheckInCompleted,
        );
        final projected = projection.activities.singleWhere(
          (item) => item.record.id == candidateId,
        );
        durations[duration] = ActivityImpactPreview(
          subcategory: subcategory,
          duration: duration,
          theoreticalDelta: theoreticalDelta,
          projectedAppliedDelta: projected.appliedDelta,
          estimateBefore: projected.estimateAfter - projected.appliedDelta,
          estimateAfter: projected.estimateAfter,
        );
      }
      result[subcategory] = UnmodifiableMapView(durations);
    }
    return UnmodifiableMapView(result);
  }
}
