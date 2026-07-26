import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/app/app.dart';
import 'package:power_manager/app/app_routes.dart';
import 'package:power_manager/application/activity_use_cases.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/features/debug/presentation/debug_environment_page.dart';
import 'package:power_manager/features/home/presentation/home_page.dart';

void main() {
  testWidgets('app starts inside ProviderScope and renders the home shell', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.byType(ProviderScope), findsOneWidget);
    expect(find.byKey(HomePage.pageKey), findsOneWidget);
    expect(find.byKey(HomePage.energyBallKey), findsOneWidget);
    expect(find.byKey(HomePage.recordButtonKey), findsOneWidget);

    final recordButton = tester.widget<IconButton>(
      find.byKey(HomePage.recordButtonKey),
    );
    expect(recordButton.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('native named route constructs the debug environment page', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    final context = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(context).pushNamed(AppRoutes.debugEnvironment);
    await tester.pumpAndSettle();

    expect(find.byKey(DebugEnvironmentPage.pageKey), findsOneWidget);
    expect(find.text('派生状态调试'), findsOneWidget);
    expect(find.text('2026-07-26'), findsOneWidget);
    expect(find.text('test-rules'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shell does not overflow on a compact landscape viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(640, 360);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.byKey(HomePage.pageKey), findsOneWidget);
    expect(find.byKey(HomePage.energyBallKey), findsOneWidget);
    expect(find.byKey(HomePage.recordButtonKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'click flow creates a record and undo remains available for 5 seconds',
    (tester) async {
      final mutator = _FakeActivityMutator();
      await tester.pumpWidget(_testApp(mutator: mutator));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(HomePage.recordButtonKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('category-study')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('subcategory-homework')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('duration-30')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('activity-submit-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(mutator.createCount, 1);
      expect(find.text('撤销'), findsOneWidget);
      await tester.tap(find.text('撤销'));
      await tester.pumpAndSettle();
      expect(mutator.deleteCount, 1);
    },
  );

  testWidgets('undo action disappears after its five-second window', (
    tester,
  ) async {
    final mutator = _FakeActivityMutator();
    await tester.pumpWidget(_testApp(mutator: mutator));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomePage.recordButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-recovery')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('subcategory-nap')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('duration-15')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('activity-submit-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('撤销'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('撤销'), findsNothing);
    expect(mutator.deleteCount, 0);
  });
}

Widget _testApp({ActivityMutator? mutator}) {
  return ProviderScope(
    overrides: [
      operationPreparerProvider.overrideWithValue(_FakePreparer()),
      if (mutator != null) activityUseCasesProvider.overrideWithValue(mutator),
    ],
    child: const PowerManagerApp(),
  );
}

final class _FakeActivityMutator implements ActivityMutator {
  var createCount = 0;
  var deleteCount = 0;

  @override
  Future<ActivityMutationResult> create(ActivityDraft draft) async {
    createCount++;
    return ActivityMutationResult(
      activity: _storedActivity(
        id: draft.operationId,
        category: draft.category,
        subcategory: draft.subcategory,
        duration: draft.duration,
        completedAt: draft.completedAt,
      ),
      current: _currentProjection(),
      wasAlreadyApplied: false,
    );
  }

  @override
  Future<ActivityMutationResult> delete(String activityId) async {
    deleteCount++;
    return ActivityMutationResult(
      activity: _storedActivity(
        id: activityId,
        category: ActivityCategory.study,
        subcategory: ActivitySubcategory.homework,
        duration: DurationSlot.minutes30,
        completedAt: DateTime(2026, 7, 26, 10),
        status: ActivityRecordStatus.deleted,
      ),
      current: _currentProjection(),
      wasAlreadyApplied: false,
    );
  }

  @override
  Future<ActivityMutationResult> edit({
    required String activityId,
    required ActivityCategory category,
    required ActivitySubcategory subcategory,
    required DurationSlot duration,
    required DateTime completedAt,
  }) {
    throw UnimplementedError();
  }
}

final class _FakePreparer implements OperationPreparer {
  @override
  Future<OperationPreparationResult> prepare(PreparationTrigger trigger) async {
    return OperationPreparationResult(
      trigger: trigger,
      nowLocal: DateTime(2026, 7, 26, 12),
      nowUtc: DateTime.utc(2026, 7, 26, 4),
      current: CurrentDayProjection(
        lifeDay: _currentProjection().lifeDay,
        baseEstimatedEnergy: _currentProjection().baseEstimatedEnergy,
        ruleVersion: _currentProjection().ruleVersion,
        morningAdjustment: _currentProjection().morningAdjustment,
        shortTermAdjustment: _currentProjection().shortTermAdjustment,
        previousFinalEstimate: _currentProjection().previousFinalEstimate,
        morningCheckInCompleted: _currentProjection().morningCheckInCompleted,
        projection: _currentProjection().projection,
      ),
      settledSummaries: const [],
      appliedPendingBaseEnergy: false,
      appliedPendingRuleVersion: false,
    );
  }
}

CurrentDayProjection _currentProjection() {
  return CurrentDayProjection(
    lifeDay: LifeDay(2026, 7, 26),
    baseEstimatedEnergy: 100,
    ruleVersion: 'test-rules',
    morningAdjustment: 0,
    shortTermAdjustment: 0,
    previousFinalEstimate: null,
    morningCheckInCompleted: false,
    projection: EstimatedDayProjection(
      initialEstimate: 100,
      currentEstimate: 100,
      band: EstimatedEnergyBand.estimatedNormal,
      activities: const [],
      totalConsumption: 0,
      totalRecovery: 0,
      categorySummaries: const {},
      effectiveDayKind: EffectiveDayKind.none,
    ),
  );
}

StoredEstimatedActivity _storedActivity({
  required String id,
  required ActivityCategory category,
  required ActivitySubcategory subcategory,
  required DurationSlot duration,
  required DateTime completedAt,
  ActivityRecordStatus status = ActivityRecordStatus.active,
}) {
  final utc = completedAt.toUtc();
  return StoredEstimatedActivity(
    id: id,
    lifeDay: LifeDay(2026, 7, 26),
    completedAt: utc,
    createdAt: utc,
    updatedAt: utc,
    category: category,
    subcategory: subcategory,
    duration: duration,
    theoreticalDelta: -8,
    appliedDelta: -8,
    ruleVersion: 'test-rules',
    status: status,
    deletedAt: status == ActivityRecordStatus.deleted ? utc : null,
  );
}
