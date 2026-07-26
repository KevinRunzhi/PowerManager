import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/app/app.dart';
import 'package:power_manager/app/app_routes.dart';
import 'package:power_manager/application/activity_use_cases.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/application/wellbeing_use_cases.dart';
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

  testWidgets('skipped morning still shows estimate and a distinct state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(morningStatus: MorningCompletionStatus.skipped),
    );
    await tester.pumpAndSettle();

    expect(find.text('今天已跳过晨间确认 · 可补做'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('···'), findsNothing);
  });

  testWidgets('four-step morning check-in saves all raw choices', (
    tester,
  ) async {
    final wellbeing = _FakeWellbeingMutator();
    await tester.pumpWidget(_testApp(wellbeing: wellbeing));
    await tester.pumpAndSettle();

    await tester.tap(find.text('晨间确认（可跳过）'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('好'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('压力不大'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('差'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('morning-submit-button')));
    await tester.pumpAndSettle();

    expect(wellbeing.savedMorning!.overallState, MorningOverallState.good);
    expect(wellbeing.savedMorning!.freeTimeLevel, FreeTimeLevel.medium);
    expect(wellbeing.savedMorning!.pressureSource, PressureSource.low);
    expect(wellbeing.savedMorning!.sleepRecovery, SleepRecovery.bad);
  });

  testWidgets('actual estimate remains hidden until selection is saved', (
    tester,
  ) async {
    final wellbeing = _FakeWellbeingMutator();
    await tester.pumpWidget(_testApp(wellbeing: wellbeing));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('actual-state-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('actual-state-selection')), findsOneWidget);
    expect(find.byKey(const Key('revealed-system-estimate')), findsNothing);
    expect(find.text('系统当时的估计'), findsNothing);

    await tester.tap(find.byKey(const Key('actual-low')));
    await tester.pumpAndSettle();
    expect(wellbeing.savedActual, AbsoluteEnergyState.low);
    expect(find.byKey(const Key('actual-state-reveal')), findsOneWidget);
    expect(find.byKey(const Key('revealed-system-estimate')), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    expect(find.textContaining('不会覆盖估计'), findsOneWidget);
  });

  testWidgets('today overview is hidden by default and opens as a sheet', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    expect(find.text('今天还没有活动记录。'), findsNothing);

    await tester.tap(find.byKey(const Key('today-overview-button')));
    await tester.pumpAndSettle();
    expect(find.text('今日概览'), findsWidgets);
    expect(find.text('今天还没有活动记录。'), findsOneWidget);
    expect(find.textContaining('按变化总量排序'), findsOneWidget);
  });

  testWidgets('core home content survives 200 percent text scaling', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(textScaler: const TextScaler.linear(2)));
    await tester.pumpAndSettle();

    expect(find.byKey(HomePage.energyBallKey), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.byKey(HomePage.recordButtonKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp({
  ActivityMutator? mutator,
  MorningCompletionStatus morningStatus = MorningCompletionStatus.notAnswered,
  WellbeingMutator? wellbeing,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return ProviderScope(
    overrides: [
      operationPreparerProvider.overrideWithValue(_FakePreparer()),
      morningCompletionStatusProvider.overrideWith(
        (ref) async => morningStatus,
      ),
      currentMorningCheckInProvider.overrideWith((ref) async => null),
      currentDailyObservationProvider.overrideWith((ref) async => null),
      canSupplementYesterdayProvider.overrideWith((ref) async => false),
      if (mutator != null) activityUseCasesProvider.overrideWithValue(mutator),
      if (wellbeing != null)
        wellbeingUseCasesProvider.overrideWithValue(wellbeing),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: const Size(800, 600), textScaler: textScaler),
      child: const PowerManagerApp(),
    ),
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

final class _FakeWellbeingMutator implements WellbeingMutator {
  MorningCheckIn? savedMorning;
  AbsoluteEnergyState? savedActual;
  RelativeCorrection? savedCorrection;

  @override
  Future<CurrentDayProjection> saveMorningCheckIn(
    MorningCheckIn checkIn,
  ) async {
    savedMorning = checkIn;
    return _currentProjection();
  }

  @override
  Future<void> skipMorning(String receiptId) async {}

  @override
  Future<DailyObservationResult> saveDailyAbsolute({
    required String observationId,
    required LifeDay targetLifeDay,
    required AbsoluteEnergyState state,
  }) async {
    savedActual = state;
    final observation = EnergyObservation(
      id: observationId,
      lifeDay: targetLifeDay,
      type: EnergyObservationType.dailyAbsolute,
      absoluteState: state,
      relativeState: null,
      estimateAtObservation: null,
      observedAt: DateTime.utc(2026, 7, 26, 12),
    );
    return DailyObservationResult(
      observation: observation,
      systemEstimate: 88,
      differenceDescription: '你的感受比系统估计更疲惫一些。',
      wasUpdated: false,
    );
  }

  @override
  Future<EnergyObservation> saveRelativeCorrection({
    required String observationId,
    required RelativeCorrection correction,
  }) async {
    savedCorrection = correction;
    return EnergyObservation(
      id: observationId,
      lifeDay: LifeDay(2026, 7, 26),
      type: EnergyObservationType.relativeCorrection,
      absoluteState: null,
      relativeState: correction,
      estimateAtObservation: 100,
      observedAt: DateTime.utc(2026, 7, 26, 12),
    );
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
