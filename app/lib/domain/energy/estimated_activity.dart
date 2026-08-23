import 'package:power_manager/domain/energy/energy_enums.dart';

final class EstimatedActivityRecord {
  EstimatedActivityRecord({
    required this.id,
    required this.completedAt,
    required this.createdAt,
    required this.subcategory,
    required this.duration,
    required this.ruleVersion,
    required this.theoreticalDelta,
    this.status = ActivityRecordStatus.active,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Activity id must not be empty');
    }
    if (ruleVersion.trim().isEmpty) {
      throw ArgumentError.value(
        ruleVersion,
        'ruleVersion',
        'Activity rule version must not be empty',
      );
    }
    if (!completedAt.isUtc || !createdAt.isUtc) {
      throw ArgumentError(
        'Activity timestamps must be UTC; lifeDay is persisted separately',
      );
    }
  }

  final String id;
  final DateTime completedAt;
  final DateTime createdAt;
  final ActivitySubcategory subcategory;
  final DurationSlot duration;
  final String ruleVersion;
  final int theoreticalDelta;
  final ActivityRecordStatus status;

  ActivityCategory get category => subcategory.category;
  bool get isActive => status == ActivityRecordStatus.active;
}

final class ProjectedEstimatedActivity {
  const ProjectedEstimatedActivity({
    required this.record,
    required this.appliedDelta,
    required this.estimateAfter,
  });

  final EstimatedActivityRecord record;
  final int appliedDelta;
  final int estimateAfter;
}
