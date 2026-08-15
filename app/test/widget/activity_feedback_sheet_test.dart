import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/application/activity_feedback_use_cases.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/features/activity/presentation/activity_feedback_sheet.dart';

void main() {
  testWidgets('offers four directions and can be skipped', (tester) async {
    final mutator = _FakeFeedbackMutator();
    await tester.pumpWidget(_app(mutator));
    await tester.tap(find.byKey(const Key('open-feedback-sheet')));
    await tester.pumpAndSettle();

    for (final direction in ActivityFeedbackDirection.values) {
      expect(
        find.byKey(Key('activity-feedback-${direction.code}')),
        findsOneWidget,
      );
    }
    expect(find.textContaining('不只是强弱问题'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancel-activity-feedback-button')));
    await tester.pumpAndSettle();
    expect(find.text('这次活动的影响符合吗？'), findsNothing);
    expect(mutator.calls, 0);
  });

  testWidgets('failure preserves choice and retry succeeds', (tester) async {
    final mutator = _FakeFeedbackMutator()..fail = true;
    await tester.pumpWidget(_app(mutator));
    await tester.tap(find.byKey(const Key('open-feedback-sheet')));
    await tester.pumpAndSettle();

    final choice = find.byKey(const Key('activity-feedback-directionMismatch'));
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pump();
    final save = find.byKey(const Key('save-activity-feedback-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('activity-feedback-error')), findsOneWidget);
    expect(find.textContaining('当前选择已保留'), findsOneWidget);
    expect(mutator.lastDirection, ActivityFeedbackDirection.directionMismatch);

    mutator.fail = false;
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(mutator.calls, 2);
    expect(find.text('这次活动的影响符合吗？'), findsNothing);
  });

  testWidgets('remains usable on a small screen at 200 percent text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _FakeFeedbackMutator(),
        size: const Size(320, 480),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.tap(find.byKey(const Key('open-feedback-sheet')));
    await tester.pumpAndSettle();

    final save = find.byKey(const Key('save-activity-feedback-button'));
    await tester.scrollUntilVisible(
      save,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(save, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
  ActivityFeedbackMutator mutator, {
  Size size = const Size(800, 600),
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return ProviderScope(
    overrides: [
      activityFeedbackUseCasesProvider.overrideWithValue(mutator),
      clockProvider.overrideWithValue(
        _FixedClock(DateTime.utc(2026, 8, 15, 12)),
      ),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size, textScaler: textScaler),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                key: const Key('open-feedback-sheet'),
                onPressed: () =>
                    ActivityFeedbackSheet.show(context, activity: _activity),
                child: const Text('打开反馈'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

final _activity = StoredEstimatedActivity(
  id: 'activity-feedback-target',
  lifeDay: LifeDay(2026, 8, 15),
  completedAt: DateTime.utc(2026, 8, 15, 10),
  createdAt: DateTime.utc(2026, 8, 15, 10),
  updatedAt: DateTime.utc(2026, 8, 15, 10),
  category: ActivityCategory.leisure,
  subcategory: ActivitySubcategory.otherLeisure,
  duration: DurationSlot.minutes30,
  theoreticalDelta: 0,
  appliedDelta: 0,
  ruleVersion: 'energy-rules-v2-mvp-a',
  status: ActivityRecordStatus.active,
  deletedAt: null,
);

final class _FakeFeedbackMutator implements ActivityFeedbackMutator {
  var fail = false;
  var calls = 0;
  ActivityFeedbackDirection? lastDirection;

  @override
  Future<ActivityFeedbackMutationResult> save({
    required String feedbackId,
    required String activityId,
    required DateTime expectedActivityUpdatedAt,
    required ActivityFeedbackDirection direction,
  }) async {
    calls++;
    lastDirection = direction;
    if (fail) throw StateError('simulated failure');
    return ActivityFeedbackMutationResult(
      feedback: ActivityFeedback(
        id: feedbackId,
        activityRecordId: activityId,
        lifeDay: _activity.lifeDay,
        subcategorySnapshot: _activity.subcategory,
        durationSnapshot: _activity.duration,
        theoreticalDeltaSnapshot: _activity.theoreticalDelta,
        appliedDeltaSnapshot: _activity.appliedDelta,
        impactSignSnapshot: ActivityImpactSign.zero,
        ruleVersionSnapshot: _activity.ruleVersion,
        activityUpdatedAtSnapshot: expectedActivityUpdatedAt,
        direction: direction,
        status: ActivityFeedbackStatus.active,
        invalidationReason: null,
        observedAt: DateTime.utc(2026, 8, 15, 12),
      ),
      wasUpdated: false,
    );
  }
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
