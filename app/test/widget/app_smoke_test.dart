import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/app/app.dart';
import 'package:power_manager/app/app_routes.dart';
import 'package:power_manager/application/activity_use_cases.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/history_review_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/application/settings_service.dart';
import 'package:power_manager/application/wellbeing_use_cases.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/estimated_activity.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/features/debug/presentation/debug_environment_page.dart';
import 'package:power_manager/features/home/presentation/home_page.dart';
import 'package:power_manager/features/settings/presentation/settings_page.dart';

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

  testWidgets('preparation failure shows retry without internal details', (
    tester,
  ) async {
    final preparer = _FailingPreparer();
    await tester.pumpWidget(_testApp(preparer: preparer));
    await tester.pumpAndSettle();

    expect(find.text('读取当天状态失败。'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.textContaining('database unavailable'), findsNothing);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(preparer.attempts, 3);
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

  testWidgets('activity makes the daily actual-state nudge discoverable', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(preparer: _ActivityPreparer()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('current-actual-state-nudge')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('今天结束前，留一次实际感受'), findsOneWidget);
    final action = find.byKey(const Key('current-actual-state-nudge-button'));
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('actual-state-selection')), findsOneWidget);
    expect(find.byKey(const Key('revealed-system-estimate')), findsNothing);
  });

  testWidgets('daily actual-state nudge stays hidden without an activity', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('current-actual-state-nudge')), findsNothing);
  });

  testWidgets('completed daily state hides the activity nudge', (tester) async {
    await tester.pumpWidget(
      _testApp(
        preparer: _ActivityPreparer(),
        currentActual: _dailyObservation(LifeDay(2026, 7, 26)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('current-actual-state-nudge')), findsNothing);
  });

  testWidgets('daily actual-state nudge survives 200 percent text scaling', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        preparer: _ActivityPreparer(),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('current-actual-state-nudge')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
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

  testWidgets(
    'history review distinguishes estimate, actual and partial window',
    (tester) async {
      final day = LifeDay(2026, 7, 25);
      final summary = _dailySummary(day);
      final review = HistoricalDayReview(
        summary: summary,
        actualState: null,
        corrections: const CorrectionCounts(lower: 1, aboutRight: 0, higher: 0),
      );
      await tester.pumpWidget(
        _testApp(
          history: HistoryReview(
            latest: review,
            rolling: RollingReview(
              days: [review],
              totalConsumption: summary.totalConsumption,
              totalRecovery: summary.totalRecovery,
              corrections: review.corrections,
              categorySummaries: summary.categorySummaries,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('history-review-card')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('昨日总结'), findsOneWidget);
      expect(find.textContaining('实际 未确认'), findsOneWidget);
      await tester.tap(find.text('昨日总结'));
      await tester.pumpAndSettle();
      expect(find.text('系统估计'), findsOneWidget);
      expect(find.text('实际状态'), findsOneWidget);
      expect(find.text('未确认'), findsOneWidget);
      expect(find.textContaining('系统估计不代表'), findsOneWidget);

      Navigator.of(tester.element(find.text('系统估计'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rolling-review-button')));
      await tester.pumpAndSettle();
      expect(find.textContaining('不足 7 个有效日'), findsOneWidget);
      expect(find.textContaining('调整建议'), findsOneWidget);
      expect(find.textContaining('自动调整'), findsNothing);
    },
  );

  testWidgets('yesterday supplement action lives inside the history card', (
    tester,
  ) async {
    final day = LifeDay(2026, 7, 25);
    final summary = _dailySummary(day);
    final review = HistoricalDayReview(
      summary: summary,
      actualState: null,
      corrections: const CorrectionCounts(lower: 0, aboutRight: 0, higher: 0),
    );
    await tester.pumpWidget(
      _testApp(
        canSupplementYesterday: true,
        history: HistoryReview(
          latest: review,
          rolling: RollingReview(
            days: [review],
            totalConsumption: summary.totalConsumption,
            totalRecovery: summary.totalRecovery,
            corrections: review.corrections,
            categorySummaries: summary.categorySummaries,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final historyCard = find.byKey(const Key('history-review-card'));
    await tester.scrollUntilVisible(
      historyCard,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final action = find.byKey(const Key('yesterday-actual-button'));
    expect(action, findsOneWidget);
    expect(find.descendant(of: historyCard, matching: action), findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('补充昨日实际状态'), findsWidgets);
    expect(find.byKey(const Key('actual-state-selection')), findsOneWidget);
  });

  testWidgets('settings validates base range and schedules valid boundary', (
    tester,
  ) async {
    final settingsMutator = _FakeSettingsMutator();
    await tester.pumpWidget(_testApp(settingsMutator: settingsMutator));
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(context).pushNamed(AppRoutes.settings);
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsPage.pageKey), findsOneWidget);
    await tester.enterText(find.byKey(const Key('base-estimate-field')), '59');
    await tester.tap(find.byKey(const Key('save-base-estimate-button')));
    await tester.pump();
    expect(find.text('请输入 60～140 的整数'), findsOneWidget);
    expect(settingsMutator.scheduled, isEmpty);

    await tester.enterText(find.byKey(const Key('base-estimate-field')), '140');
    await tester.tap(find.byKey(const Key('save-base-estimate-button')));
    await tester.pumpAndSettle();
    expect(settingsMutator.scheduled, [140]);
    expect(find.textContaining('规则编辑或迁移入口'), findsOneWidget);
  });

  testWidgets('backup controls survive 200 percent text scaling', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(textScaler: const TextScaler.linear(2)));
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(context).pushNamed(AppRoutes.settings);
    await tester.pumpAndSettle();

    final settingsList = find.descendant(
      of: find.byKey(SettingsPage.pageKey),
      matching: find.byType(ListView),
    );
    expect(settingsList, findsOneWidget);
    await tester.drag(settingsList, const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('restore-json-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first explanation completes once and settings can reopen it', (
    tester,
  ) async {
    final settingsMutator = _FakeSettingsMutator();
    await tester.pumpWidget(
      _testApp(
        settingsMutator: settingsMutator,
        appSettings: _appSettings(onboardingCompleted: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-confirm-button')));
    await tester.pumpAndSettle();
    expect(settingsMutator.onboardingCount, 1);
    expect(find.byKey(const Key('onboarding-dialog')), findsNothing);

    final context = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(context).pushNamed(AppRoutes.settings);
    await tester.pumpAndSettle();
    final review = find.byKey(const Key('review-onboarding-button'));
    await tester.ensureVisible(review);
    await tester.pumpAndSettle();
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding-dialog')), findsOneWidget);
  });

  testWidgets('complete energy gesture creates through the shared mutator', (
    tester,
  ) async {
    final mutator = _FakeActivityMutator();
    await tester.pumpWidget(_testApp(mutator: mutator));
    await tester.pumpAndSettle();

    final center = tester.getCenter(
      find.byKey(const Key('energy-gesture-surface')),
    );
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const Key('record-gesture-overlay')), findsOneWidget);

    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('gesture-node-0'))),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('gesture-node-0'))),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('gesture-node-0'))),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 600));

    expect(mutator.createCount, 1);
    expect(find.text('撤销'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets('energy gesture text does not inherit debug underlines', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    final center = tester.getCenter(
      find.byKey(const Key('energy-gesture-surface')),
    );
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 150));

    final overlay = find.byKey(const Key('record-gesture-overlay'));
    final texts = tester.widgetList<Text>(
      find.descendant(of: overlay, matching: find.byType(Text)),
    );
    expect(texts, isNotEmpty);
    for (final text in texts) {
      expect(text.style?.inherit, isFalse);
      expect(text.style?.decoration, TextDecoration.none);
    }
    await gesture.up();
  });

  testWidgets('incomplete energy gesture and timeout never write', (
    tester,
  ) async {
    final mutator = _FakeActivityMutator();
    await tester.pumpWidget(_testApp(mutator: mutator));
    await tester.pumpAndSettle();
    final center = tester.getCenter(
      find.byKey(const Key('energy-gesture-surface')),
    );

    final incomplete = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 150));
    await incomplete.moveBy(const Offset(0, -60));
    await incomplete.up();
    await tester.pump();
    expect(mutator.createCount, 0);

    final timedOut = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const Key('record-gesture-overlay')), findsOneWidget);
    await tester.pump(const Duration(seconds: 11));
    expect(find.byKey(const Key('record-gesture-overlay')), findsNothing);
    await timedOut.up();
    await tester.pump();
    expect(mutator.createCount, 0);
  });
}

Widget _testApp({
  OperationPreparer? preparer,
  ActivityMutator? mutator,
  MorningCompletionStatus morningStatus = MorningCompletionStatus.notAnswered,
  WellbeingMutator? wellbeing,
  TextScaler textScaler = TextScaler.noScaling,
  HistoryReview? history,
  AppSettings? appSettings,
  SettingsMutator? settingsMutator,
  EnergyObservation? currentActual,
  bool canSupplementYesterday = false,
}) {
  return ProviderScope(
    overrides: [
      operationPreparerProvider.overrideWithValue(preparer ?? _FakePreparer()),
      morningCompletionStatusProvider.overrideWith(
        (ref) async => morningStatus,
      ),
      currentMorningCheckInProvider.overrideWith((ref) async => null),
      currentDailyObservationProvider.overrideWith(
        (ref) async => currentActual,
      ),
      canSupplementYesterdayProvider.overrideWith(
        (ref) async => canSupplementYesterday,
      ),
      historyReviewProvider.overrideWith(
        (ref) async =>
            history ??
            HistoryReview(
              latest: null,
              rolling: RollingReview(
                days: const [],
                totalConsumption: 0,
                totalRecovery: 0,
                corrections: const CorrectionCounts(
                  lower: 0,
                  aboutRight: 0,
                  higher: 0,
                ),
                categorySummaries: const {},
              ),
            ),
      ),
      appSettingsProvider.overrideWith(
        (ref) async => appSettings ?? _appSettings(onboardingCompleted: true),
      ),
      settingsServiceProvider.overrideWithValue(
        settingsMutator ?? _FakeSettingsMutator(),
      ),
      backupSafetyPathProvider.overrideWith((ref) async => null),
      if (mutator != null) activityUseCasesProvider.overrideWithValue(mutator),
      if (wellbeing != null)
        wellbeingUseCasesProvider.overrideWithValue(wellbeing),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: const Size(800, 600),
        textScaler: textScaler,
        disableAnimations: true,
      ),
      child: const PowerManagerApp(),
    ),
  );
}

final class _FakeSettingsMutator implements SettingsMutator {
  final scheduled = <int>[];
  var onboardingCount = 0;

  @override
  Future<AppSettings> completeOnboarding() async {
    onboardingCount++;
    return _appSettings(onboardingCompleted: true);
  }

  @override
  Future<AppSettings> scheduleBaseEstimate(int value) async {
    scheduled.add(value);
    return _appSettings(
      onboardingCompleted: true,
      pendingBaseEstimatedEnergy: value,
    );
  }
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

final class _ActivityPreparer implements OperationPreparer {
  @override
  Future<OperationPreparationResult> prepare(PreparationTrigger trigger) async {
    final current = _currentProjectionWithActivity();
    return OperationPreparationResult(
      trigger: trigger,
      nowLocal: DateTime(2026, 7, 26, 12),
      nowUtc: DateTime.utc(2026, 7, 26, 4),
      current: current,
      settledSummaries: const [],
      appliedPendingBaseEnergy: false,
      appliedPendingRuleVersion: false,
    );
  }
}

final class _FailingPreparer implements OperationPreparer {
  var attempts = 0;

  @override
  Future<OperationPreparationResult> prepare(PreparationTrigger trigger) async {
    attempts++;
    if (trigger == PreparationTrigger.coldStart) {
      return _FakePreparer().prepare(trigger);
    }
    throw StateError('database unavailable: internal test detail');
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

CurrentDayProjection _currentProjectionWithActivity() {
  final stored = _storedActivity(
    id: 'existing-activity',
    category: ActivityCategory.study,
    subcategory: ActivitySubcategory.homework,
    duration: DurationSlot.minutes30,
    completedAt: DateTime.utc(2026, 7, 26, 4),
  );
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
      currentEstimate: 92,
      band: EstimatedEnergyBand.estimatedNormal,
      activities: [
        ProjectedEstimatedActivity(
          record: stored.toReplayRecord(),
          appliedDelta: -8,
          estimateAfter: 92,
        ),
      ],
      totalConsumption: 8,
      totalRecovery: 0,
      categorySummaries: const {},
      effectiveDayKind: EffectiveDayKind.weak,
    ),
  );
}

EnergyObservation _dailyObservation(LifeDay day) {
  return EnergyObservation(
    id: 'daily-observation',
    lifeDay: day,
    type: EnergyObservationType.dailyAbsolute,
    absoluteState: AbsoluteEnergyState.okay,
    relativeState: null,
    estimateAtObservation: null,
    observedAt: DateTime.utc(2026, 7, 26, 12),
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

DailySummary _dailySummary(LifeDay day) {
  return DailySummary(
    lifeDay: day,
    baseEstimatedEnergy: 100,
    ruleVersion: 'test-rules',
    morningAdjustment: 0,
    shortTermAdjustment: 0,
    initialEstimatedEnergy: 100,
    finalEstimatedEnergy: 92,
    totalConsumption: 10,
    totalRecovery: 2,
    categorySummaries: const {
      ActivityCategory.study: CategoryEstimatedSummary(
        category: ActivityCategory.study,
        durationMinutes: 30,
        netDelta: -8,
        grossDelta: 8,
      ),
    },
    isStandardEffectiveDay: true,
    isWeakEffectiveDay: false,
    settledAt: DateTime.utc(2026, 7, 26, 4),
  );
}

AppSettings _appSettings({
  required bool onboardingCompleted,
  int? pendingBaseEstimatedEnergy,
}) {
  return AppSettings(
    baseEstimatedEnergy: 100,
    pendingBaseEstimatedEnergy: pendingBaseEstimatedEnergy,
    baseEnergyEffectiveLifeDay: pendingBaseEstimatedEnergy == null
        ? null
        : LifeDay(2026, 7, 27),
    activeRuleVersion: 'energy-rules-v2-mvp-a',
    pendingRuleVersion: null,
    pendingRuleEffectiveLifeDay: null,
    onboardingCompleted: onboardingCompleted,
    createdAt: DateTime.utc(2026, 7, 26),
    updatedAt: DateTime.utc(2026, 7, 26),
  );
}
