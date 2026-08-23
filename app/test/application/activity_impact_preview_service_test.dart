import 'package:power_manager/application/activity_impact_preview_service.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/energy_rule_config_loader.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/domain/repositories/repositories.dart';
import 'package:test/test.dart';

void main() {
  final day = LifeDay(2026, 8, 9);
  final now = DateTime.utc(2026, 8, 9, 10);

  test('negative and zero previews equal their rule values', () async {
    final service = _service([]);
    final result = await service.previewCatalog(
      current: _current(day, 100),
      completedAt: now,
    );

    expect(
      result[ActivitySubcategory.homework]![DurationSlot.minutes30]!
          .projectedAppliedDelta,
      -8,
    );
    expect(
      result[ActivitySubcategory.mentalReset]![DurationSlot.minutes45]!
          .projectedAppliedDelta,
      0,
    );
  });

  test('positive recovery is available below the initial estimate', () async {
    final service = _service([_activity(day, 'cost', now, -10)]);
    final preview = (await service.previewCatalog(
      current: _current(day, 90),
      completedAt: now.add(const Duration(minutes: 1)),
    ))[ActivitySubcategory.nap]![DurationSlot.minutes15]!;

    expect(preview.theoreticalDelta, 5);
    expect(preview.projectedAppliedDelta, 5);
    expect(preview.isRecoveryLimited, isFalse);
    expect(preview.estimateBefore, 90);
    expect(preview.estimateAfter, 95);
  });

  test('positive recovery can be partially limited', () async {
    final service = _service([_activity(day, 'cost', now, -3)]);
    final preview = (await service.previewCatalog(
      current: _current(day, 97),
      completedAt: now.add(const Duration(minutes: 1)),
    ))[ActivitySubcategory.nap]![DurationSlot.minutes15]!;

    expect(preview.theoreticalDelta, 5);
    expect(preview.projectedAppliedDelta, 3);
    expect(preview.isRecoveryLimited, isTrue);
    expect(preview.estimateAfter, 100);
  });

  test('positive recovery is zero at the initial estimate', () async {
    final preview = (await _service([]).previewCatalog(
      current: _current(day, 100),
      completedAt: now,
    ))[ActivitySubcategory.nap]![DurationSlot.minutes15]!;

    expect(preview.theoreticalDelta, 5);
    expect(preview.projectedAppliedDelta, 0);
    expect(preview.isRecoveryLimited, isTrue);
  });

  test(
    'editing replaces the original record instead of duplicating it',
    () async {
      final original = _activity(day, 'edit-me', now, -10);
      final preview = (await _service([original]).previewCatalog(
        current: _current(day, 90),
        completedAt: now,
        editingActivityId: original.id,
      ))[ActivitySubcategory.homework]![DurationSlot.minutes30]!;

      expect(preview.estimateBefore, 100);
      expect(preview.projectedAppliedDelta, -8);
      expect(preview.estimateAfter, 92);
    },
  );

  test('missing editing record fails without writing the repository', () async {
    final activities = _Activities([]);
    final service = ActivityImpactPreviewService(
      activities: activities,
      ruleLoader: EnergyRuleConfigLoader(_Rules()),
    );

    await expectLater(
      service.previewCatalog(
        current: _current(day, 100),
        completedAt: now,
        editingActivityId: 'missing',
      ),
      throwsStateError,
    );
    expect(activities.writeCount, 0);
  });
}

ActivityImpactPreviewService _service(List<StoredEstimatedActivity> records) {
  return ActivityImpactPreviewService(
    activities: _Activities(records),
    ruleLoader: EnergyRuleConfigLoader(_Rules()),
  );
}

CurrentDayProjection _current(LifeDay day, int currentEstimate) {
  return CurrentDayProjection(
    lifeDay: day,
    baseEstimatedEnergy: 100,
    ruleVersion: 'test-rules',
    morningAdjustment: 0,
    shortTermAdjustment: 0,
    previousFinalEstimate: null,
    morningCheckInCompleted: true,
    projection: EstimatedDayProjection(
      initialEstimate: 100,
      currentEstimate: currentEstimate,
      band: EstimatedEnergyBand.estimatedNormal,
      activities: const [],
      totalConsumption: 0,
      totalRecovery: 0,
      categorySummaries: const {},
      effectiveDayKind: EffectiveDayKind.standard,
    ),
  );
}

StoredEstimatedActivity _activity(
  LifeDay day,
  String id,
  DateTime completedAt,
  int delta,
) {
  return StoredEstimatedActivity(
    id: id,
    lifeDay: day,
    completedAt: completedAt,
    createdAt: completedAt,
    updatedAt: completedAt,
    category: ActivityCategory.study,
    subcategory: ActivitySubcategory.homework,
    duration: DurationSlot.minutes30,
    theoreticalDelta: delta,
    appliedDelta: delta,
    ruleVersion: 'test-rules',
    status: ActivityRecordStatus.active,
    deletedAt: null,
  );
}

final class _Rules implements RuleConfigVersionsRepository {
  @override
  Future<RuleConfigVersion?> find(String version) async => RuleConfigVersion(
    version: version,
    values: {
      'activityRules': {
        for (final subcategory in ActivitySubcategory.values)
          subcategory.code: {
            for (final duration in DurationSlot.values)
              '${duration.minutes}': _delta(subcategory, duration),
          },
      },
    },
    createdAt: DateTime.utc(2026, 8, 1),
  );

  static int _delta(ActivitySubcategory subcategory, DurationSlot duration) {
    if (subcategory == ActivitySubcategory.homework &&
        duration == DurationSlot.minutes30) {
      return -8;
    }
    if (subcategory == ActivitySubcategory.nap &&
        duration == DurationSlot.minutes15) {
      return 5;
    }
    return 0;
  }

  @override
  Future<void> insert(RuleConfigVersion version) => throw UnimplementedError();

  @override
  Future<List<RuleConfigVersion>> list() => throw UnimplementedError();
}

final class _Activities implements ActivityRecordsRepository {
  _Activities(this.records);

  final List<StoredEstimatedActivity> records;
  var writeCount = 0;

  @override
  Future<List<StoredEstimatedActivity>> listActiveForLifeDay(
    LifeDay lifeDay,
  ) async => records;

  @override
  Future<StoredEstimatedActivity?> find(String id) async =>
      records.where((item) => item.id == id).firstOrNull;

  @override
  Future<void> insert(StoredEstimatedActivity activity) async => writeCount++;

  @override
  Future<void> update(StoredEstimatedActivity activity) async => writeCount++;

  @override
  Future<void> logicallyDelete(String id, DateTime deletedAt) async =>
      writeCount++;

  @override
  Future<List<StoredEstimatedActivity>> listAllForExport() async => records;

  @override
  Future<List<StoredEstimatedActivity>> listAllForLifeDay(
    LifeDay lifeDay,
  ) async => records;
}
