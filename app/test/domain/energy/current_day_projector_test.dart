import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/energy_rule_config.dart';
import 'package:power_manager/domain/energy/estimated_activity.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:test/test.dart';

void main() {
  const projector = CurrentDayProjector();

  group('stable replay', () {
    test('activity records require UTC timestamps and a rule version', () {
      expect(
        () => EstimatedActivityRecord(
          id: 'local-time',
          completedAt: DateTime(2026, 7, 26, 10),
          createdAt: DateTime.utc(2026, 7, 26, 10),
          subcategory: ActivitySubcategory.classAttendance,
          duration: DurationSlot.minutes15,
          ruleVersion: energyRulesV2MvpAVersion,
          theoreticalDelta: -5,
        ),
        throwsArgumentError,
      );
      expect(
        () => EstimatedActivityRecord(
          id: 'empty-version',
          completedAt: DateTime.utc(2026, 7, 26, 10),
          createdAt: DateTime.utc(2026, 7, 26, 10),
          subcategory: ActivitySubcategory.classAttendance,
          duration: DurationSlot.minutes15,
          ruleVersion: ' ',
          theoreticalDelta: -5,
        ),
        throwsArgumentError,
      );
    });

    test('orders by completedAt, then createdAt, then id', () {
      final commonCompletedAt = DateTime.utc(2026, 7, 26, 10);
      final earlierCreatedAt = DateTime.utc(2026, 7, 26, 10, 1);
      final laterCreatedAt = DateTime.utc(2026, 7, 26, 10, 2);
      final records = [
        _record(
          id: 'c-recovery',
          completedAt: commonCompletedAt,
          createdAt: laterCreatedAt,
          delta: 15,
        ),
        _record(
          id: 'b-consumption',
          completedAt: commonCompletedAt,
          createdAt: laterCreatedAt,
          delta: -20,
        ),
        _record(
          id: 'z-early-recovery',
          completedAt: commonCompletedAt,
          createdAt: earlierCreatedAt,
          delta: 10,
        ),
      ];

      final result = projector.project(
        initialEstimate: 100,
        records: records,
        morningCheckInCompleted: true,
      );

      expect(result.activities.map((activity) => activity.record.id), [
        'z-early-recovery',
        'b-consumption',
        'c-recovery',
      ]);
      expect(result.activities.map((activity) => activity.appliedDelta), [
        0,
        -20,
        15,
      ]);
      expect(result.currentEstimate, 95);
    });

    test('produces the same result for every input iteration order', () {
      final records = [
        _record(
          id: '3',
          completedAt: DateTime.utc(2026, 7, 26, 12),
          createdAt: DateTime.utc(2026, 7, 26, 12, 1),
          delta: 10,
        ),
        _record(
          id: '1',
          completedAt: DateTime.utc(2026, 7, 26, 9),
          createdAt: DateTime.utc(2026, 7, 26, 9, 1),
          delta: -20,
        ),
        _record(
          id: '2',
          completedAt: DateTime.utc(2026, 7, 26, 10),
          createdAt: DateTime.utc(2026, 7, 26, 10, 1),
          delta: 5,
        ),
      ];

      final forward = projector.project(
        initialEstimate: 100,
        records: records,
        morningCheckInCompleted: false,
      );
      final reversed = projector.project(
        initialEstimate: 100,
        records: records.reversed,
        morningCheckInCompleted: false,
      );

      expect(
        reversed.activities.map((activity) => activity.record.id),
        forward.activities.map((activity) => activity.record.id),
      );
      expect(
        reversed.activities.map((activity) => activity.appliedDelta),
        forward.activities.map((activity) => activity.appliedDelta),
      );
      expect(reversed.currentEstimate, forward.currentEstimate);
      expect(reversed.totalConsumption, forward.totalConsumption);
      expect(reversed.totalRecovery, forward.totalRecovery);
    });

    test('ignores logically deleted records completely', () {
      final result = projector.project(
        initialEstimate: 100,
        records: [
          _record(
            id: 'active',
            completedAt: DateTime.utc(2026, 7, 26, 10),
            createdAt: DateTime.utc(2026, 7, 26, 10),
            delta: -20,
          ),
          _record(
            id: 'deleted',
            completedAt: DateTime.utc(2026, 7, 26, 11),
            createdAt: DateTime.utc(2026, 7, 26, 11),
            delta: -80,
            status: ActivityRecordStatus.deleted,
          ),
        ],
        morningCheckInCompleted: true,
      );

      expect(result.activities.map((activity) => activity.record.id), [
        'active',
      ]);
      expect(result.currentEstimate, 80);
      expect(result.totalConsumption, 20);
    });

    test('consumption can carry the projection below zero', () {
      final result = projector.project(
        initialEstimate: 20,
        records: [
          _record(
            id: 'large-consumption',
            completedAt: DateTime.utc(2026, 7, 26, 10),
            createdAt: DateTime.utc(2026, 7, 26, 10),
            delta: -30,
          ),
        ],
        morningCheckInCompleted: true,
      );

      expect(result.currentEstimate, -10);
      expect(result.band, EstimatedEnergyBand.estimatedOverdraft);
    });

    test('recovery cap makes replay intentionally order-dependent', () {
      final consumptionFirst = projector.project(
        initialEstimate: 100,
        records: [
          _record(
            id: 'consumption',
            completedAt: DateTime.utc(2026, 7, 26, 10),
            createdAt: DateTime.utc(2026, 7, 26, 10),
            delta: -20,
          ),
          _record(
            id: 'recovery',
            completedAt: DateTime.utc(2026, 7, 26, 11),
            createdAt: DateTime.utc(2026, 7, 26, 11),
            delta: 10,
          ),
        ],
        morningCheckInCompleted: false,
      );
      final recoveryFirst = projector.project(
        initialEstimate: 100,
        records: [
          _record(
            id: 'recovery',
            completedAt: DateTime.utc(2026, 7, 26, 10),
            createdAt: DateTime.utc(2026, 7, 26, 10),
            delta: 10,
          ),
          _record(
            id: 'consumption',
            completedAt: DateTime.utc(2026, 7, 26, 11),
            createdAt: DateTime.utc(2026, 7, 26, 11),
            delta: -20,
          ),
        ],
        morningCheckInCompleted: false,
      );

      expect(consumptionFirst.currentEstimate, 90);
      expect(recoveryFirst.currentEstimate, 80);
    });
  });

  group('summaries', () {
    test('keeps net, gross, duration, consumption, and recovery separate', () {
      final result = projector.project(
        initialEstimate: 100,
        records: [
          _record(
            id: 'recovery-consumption',
            completedAt: DateTime.utc(2026, 7, 26, 10),
            createdAt: DateTime.utc(2026, 7, 26, 10),
            delta: -10,
            subcategory: ActivitySubcategory.lightActivity,
            duration: DurationSlot.minutes15,
          ),
          _record(
            id: 'recovery-restoration',
            completedAt: DateTime.utc(2026, 7, 26, 11),
            createdAt: DateTime.utc(2026, 7, 26, 11),
            delta: 6,
            subcategory: ActivitySubcategory.nap,
            duration: DurationSlot.minutes30,
          ),
        ],
        morningCheckInCompleted: false,
      );

      final recovery = result.categorySummaries[ActivityCategory.recovery]!;
      expect(recovery.durationMinutes, 45);
      expect(recovery.netDelta, -4);
      expect(recovery.grossDelta, 16);
      expect(result.totalConsumption, 10);
      expect(result.totalRecovery, 6);
      expect(result.currentEstimate, 96);
    });

    test('returns explicit zero summaries for categories without records', () {
      final result = projector.project(
        initialEstimate: 100,
        records: const [],
        morningCheckInCompleted: false,
      );

      expect(result.categorySummaries, hasLength(4));
      for (final summary in result.categorySummaries.values) {
        expect(summary.durationMinutes, 0);
        expect(summary.netDelta, 0);
        expect(summary.grossDelta, 0);
      }
    });
  });

  group('effective day classification', () {
    final first = _record(
      id: 'first',
      completedAt: DateTime.utc(2026, 7, 26, 10),
      createdAt: DateTime.utc(2026, 7, 26, 10),
      delta: -5,
    );
    final second = _record(
      id: 'second',
      completedAt: DateTime.utc(2026, 7, 26, 11),
      createdAt: DateTime.utc(2026, 7, 26, 11),
      delta: -5,
    );

    test('standard requires a morning check-in and one active activity', () {
      final result = projector.project(
        initialEstimate: 100,
        records: [first],
        morningCheckInCompleted: true,
      );

      expect(result.effectiveDayKind, EffectiveDayKind.standard);
      expect(result.isStandardEffectiveDay, isTrue);
      expect(result.isWeakEffectiveDay, isFalse);
    });

    test('weak requires no morning check-in and two active activities', () {
      final result = projector.project(
        initialEstimate: 100,
        records: [first, second],
        morningCheckInCompleted: false,
      );

      expect(result.effectiveDayKind, EffectiveDayKind.weak);
      expect(result.isWeakEffectiveDay, isTrue);
      expect(result.isStandardEffectiveDay, isFalse);
    });

    test('one activity without a morning check-in is not effective', () {
      final result = projector.project(
        initialEstimate: 100,
        records: [first],
        morningCheckInCompleted: false,
      );

      expect(result.effectiveDayKind, EffectiveDayKind.none);
    });

    test('deleted activities do not make a day effective', () {
      final deleted = _record(
        id: 'deleted',
        completedAt: DateTime.utc(2026, 7, 26, 12),
        createdAt: DateTime.utc(2026, 7, 26, 12),
        delta: -5,
        status: ActivityRecordStatus.deleted,
      );
      final result = projector.project(
        initialEstimate: 100,
        records: [first, deleted],
        morningCheckInCompleted: false,
      );

      expect(result.effectiveDayKind, EffectiveDayKind.none);
    });
  });
}

EstimatedActivityRecord _record({
  required String id,
  required DateTime completedAt,
  required DateTime createdAt,
  required int delta,
  ActivitySubcategory subcategory = ActivitySubcategory.classAttendance,
  DurationSlot duration = DurationSlot.minutes15,
  ActivityRecordStatus status = ActivityRecordStatus.active,
}) {
  return EstimatedActivityRecord(
    id: id,
    completedAt: completedAt,
    createdAt: createdAt,
    subcategory: subcategory,
    duration: duration,
    ruleVersion: energyRulesV2MvpAVersion,
    theoreticalDelta: delta,
    status: status,
  );
}
