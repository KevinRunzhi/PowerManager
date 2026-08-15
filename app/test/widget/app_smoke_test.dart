import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/app/app.dart';
import 'package:power_manager/app/app_routes.dart';
import 'package:power_manager/app/theme/app_colors.dart';
import 'package:power_manager/application/activity_impact_preview_service.dart';
import 'package:power_manager/application/activity_use_cases.dart';
import 'package:power_manager/application/automatic_learning_coordinator.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/data_health_service.dart';
import 'package:power_manager/application/history_review_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/application/settings_service.dart';
import 'package:power_manager/application/local_backup_service.dart';
import 'package:power_manager/application/mvp_b_upgrade_readiness_service.dart';
import 'package:power_manager/application/model_activation_service.dart';
import 'package:power_manager/data/backup/local_backup_store.dart';
import 'package:power_manager/application/wellbeing_use_cases.dart';
import 'package:power_manager/core/time/clock.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/estimated_activity.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/learning/personalization_identity.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:power_manager/domain/life_day/life_day.dart';
import 'package:power_manager/features/debug/presentation/debug_environment_page.dart';
import 'package:power_manager/features/debug/presentation/energy_orb_gallery_page.dart';
import 'package:power_manager/features/home/presentation/energy_orb/energy_orb.dart';
import 'package:power_manager/features/home/presentation/home_page.dart';
import 'package:power_manager/features/settings/presentation/settings_page.dart';
import 'package:power_manager/features/settings/presentation/data_health_page.dart';

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

  testWidgets('energy orb gallery exposes six fixed visual states', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    final context = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(context).pushNamed(AppRoutes.energyOrbGallery);
    await tester.pumpAndSettle();

    expect(find.byKey(EnergyOrbGalleryPage.pageKey), findsOneWidget);
    expect(find.text('Stage18 · 能量球状态基准'), findsOneWidget);
    expect(find.byKey(const Key('gallery-orb-0')), findsOneWidget);
    expect(find.byKey(const Key('gallery-orb-3')), findsOneWidget);
    await tester.drag(find.byType(GridView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gallery-orb-4')), findsOneWidget);
    expect(find.byKey(const Key('gallery-orb-5')), findsOneWidget);
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
    expect(preparer.attempts, 2);
  });

  testWidgets('cold start prepares once and resumed refreshes cached state', (
    tester,
  ) async {
    final preparer = _RecordingPreparer();
    final learning = _FakeAutomaticLearningRequester();
    await tester.pumpWidget(
      _testApp(preparer: preparer, learningRequester: learning),
    );
    await tester.pumpAndSettle();

    expect(preparer.triggers, [PreparationTrigger.coldStart]);
    expect(
      tester.widget<EnergyOrb>(find.byKey(HomePage.energyBallKey)).estimate,
      100,
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(preparer.triggers, [
      PreparationTrigger.coldStart,
      PreparationTrigger.resumed,
    ]);
    expect(learning.triggers, [
      AutomaticLearningTrigger.coldStart,
      AutomaticLearningTrigger.resumed,
    ]);
    expect(
      tester.widget<EnergyOrb>(find.byKey(HomePage.energyBallKey)).estimate,
      72,
    );
  });

  testWidgets('foreground 04:00 boundary refreshes current preparation', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final clock = _MutableClock(DateTime(2026, 8, 14, 3, 59, 59));
    final preparer = _RecordingPreparer();
    final learning = _FakeAutomaticLearningRequester();
    await tester.pumpWidget(
      _testApp(preparer: preparer, clock: clock, learningRequester: learning),
    );
    await tester.pumpAndSettle();

    clock.value = DateTime(2026, 8, 14, 4);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(preparer.triggers, [
      PreparationTrigger.coldStart,
      PreparationTrigger.lifeDayBoundary,
    ]);
    expect(learning.triggers, [
      AutomaticLearningTrigger.coldStart,
      AutomaticLearningTrigger.settlement,
    ]);
  });

  testWidgets(
    'plain preparation invalidation does not request learning again',
    (tester) async {
      final learning = _FakeAutomaticLearningRequester();
      await tester.pumpWidget(_testApp(learningRequester: learning));
      await tester.pumpAndSettle();
      final context = tester.element(find.byKey(HomePage.pageKey));
      final container = ProviderScope.containerOf(context);

      container.invalidate(currentPreparationProvider);
      await tester.pumpAndSettle();

      expect(learning.triggers, [AutomaticLearningTrigger.coldStart]);
    },
  );

  testWidgets('safe restore prepares before requesting one learning pass', (
    tester,
  ) async {
    final preparer = _RecordingPreparer();
    final learning = _FakeAutomaticLearningRequester();
    await tester.pumpWidget(
      _testApp(preparer: preparer, learningRequester: learning),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(HomePage.pageKey));
    final container = ProviderScope.containerOf(context);

    container
        .read(currentPreparationRefreshProvider.notifier)
        .refresh(PreparationTrigger.safeRestore);
    await tester.pumpAndSettle();

    expect(preparer.triggers, [
      PreparationTrigger.coldStart,
      PreparationTrigger.safeRestore,
    ]);
    expect(learning.triggers, [
      AutomaticLearningTrigger.coldStart,
      AutomaticLearningTrigger.safeRestore,
    ]);
  });

  testWidgets('shadow learning failure never blocks the home preparation', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(learningRequester: _FakeAutomaticLearningRequester(fail: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(HomePage.pageKey), findsOneWidget);
    expect(find.text('读取当天状态失败。'), findsNothing);
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

  testWidgets('duration choices show estimated signed impact', (tester) async {
    await tester.pumpWidget(_testApp(mutator: _FakeActivityMutator()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomePage.recordButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-recovery')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('subcategory-nap')));
    await tester.pumpAndSettle();

    expect(find.text('估计 0\n规则 +5 · 已到恢复上限'), findsOneWidget);
    expect(find.text('估计 -5'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('activity delete offers undo through restore', (tester) async {
    final mutator = _FakeActivityMutator();
    await tester.pumpWidget(
      _testApp(preparer: _ActivityPreparer(), mutator: mutator),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('删除'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(mutator.deleteCount, 1);
    expect(find.textContaining('已删除'), findsOneWidget);
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();

    expect(mutator.restoreCount, 1);
  });

  test('undo window remains active until every queued owner ends', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(undoWindowActiveProvider.notifier);

    notifier.begin();
    notifier.begin();
    notifier.end();
    expect(container.read(undoWindowActiveProvider), isTrue);

    notifier.end();
    expect(container.read(undoWindowActiveProvider), isFalse);
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
    expect(find.text('系统在保存时的估计'), findsNothing);

    await tester.tap(find.byKey(const Key('actual-low')));
    await tester.pumpAndSettle();
    expect(wellbeing.savedActual, isNull);
    expect(find.byKey(const Key('actual-state-reveal')), findsNothing);
    final coverage = find.byKey(const Key('coverage-confirmed'));
    await tester.ensureVisible(coverage);
    await tester.tap(coverage);
    await tester.pump();
    final save = find.byKey(const Key('save-actual-state-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(wellbeing.savedActual, AbsoluteEnergyState.low);
    expect(wellbeing.savedCoverage, ObservationCoverageState.confirmed);
    expect(
      wellbeing.savedReferenceType,
      ObservationReferenceType.currentMoment,
    );
    expect(find.byKey(const Key('actual-state-reveal')), findsOneWidget);
    expect(find.byKey(const Key('revealed-system-estimate')), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    expect(find.textContaining('不会覆盖估计'), findsOneWidget);
  });

  testWidgets('actual-state choices use neutral and semantic energy colors', (
    tester,
  ) async {
    final wellbeing = _FakeWellbeingMutator()..actualGate = Completer<void>();
    await tester.pumpWidget(_testApp(wellbeing: wellbeing));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('actual-state-button')));
    await tester.pumpAndSettle();

    final lowFinder = find.byKey(const Key('actual-low'));
    final fullFinder = find.byKey(const Key('actual-full'));
    final initialLow = tester.widget<OutlinedButton>(lowFinder);
    expect(
      initialLow.style?.backgroundColor?.resolve({}),
      AppColors.backgroundOverlay,
    );

    final semantics = tester.ensureSemantics();
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('偏低，实际状态'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    await tester.tap(lowFinder);
    await tester.pump();

    final selectedLow = tester.widget<OutlinedButton>(lowFinder);
    final unselectedFull = tester.widget<OutlinedButton>(fullFinder);
    expect(
      selectedLow.style?.backgroundColor?.resolve({}),
      AppColors.energyLow.withValues(alpha: 0.16),
    );
    expect(
      unselectedFull.style?.backgroundColor?.resolve({}),
      AppColors.backgroundOverlay,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('偏低，实际状态'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    wellbeing.actualGate!.complete();
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('actual-state choices remain reachable at 200 percent text', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(textScaler: const TextScaler.linear(2)));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('actual-state-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('actual-state-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('actual-exhausted')), findsOneWidget);
    expect(find.byKey(const Key('actual-full')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('save-actual-state-button')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('actual-state failure preserves state and coverage for retry', (
    tester,
  ) async {
    final wellbeing = _FakeWellbeingMutator()..failActual = true;
    await tester.pumpWidget(_testApp(wellbeing: wellbeing));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('actual-state-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('actual-full')));
    final uncertain = find.byKey(const Key('coverage-uncertain'));
    await tester.ensureVisible(uncertain);
    await tester.tap(uncertain);
    await tester.pump();
    final save = find.byKey(const Key('save-actual-state-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('actual-state-error')), findsOneWidget);
    expect(find.byKey(const Key('actual-state-selection')), findsOneWidget);
    expect(wellbeing.savedActual, AbsoluteEnergyState.full);
    expect(wellbeing.savedCoverage, ObservationCoverageState.uncertain);

    wellbeing.failActual = false;
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('actual-state-reveal')), findsOneWidget);
  });

  testWidgets(
    'relative correction failure stays visible and preserves choice',
    (tester) async {
      final wellbeing = _FakeWellbeingMutator()..failRelative = true;
      await tester.pumpWidget(_testApp(wellbeing: wellbeing));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('relative-correction-button')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('relative-correction-button')));
      await tester.pumpAndSettle();

      final lower = find.byKey(const Key('relative-lower'));
      await tester.tap(lower);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('relative-correction-error')),
        findsOneWidget,
      );
      expect(find.text('保存失败，请重试。'), findsOneWidget);
      expect(find.text('此刻感觉与估计相比'), findsOneWidget);
      final selected = tester.widget<FilledButton>(lower);
      expect(selected.style?.backgroundColor?.resolve({}), isNotNull);

      wellbeing.failRelative = false;
      await tester.tap(lower);
      await tester.pumpAndSettle();
      expect(find.textContaining('已记录：比估计低'), findsOneWidget);
    },
  );

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
    expect(find.text('留一次现在的整体状态'), findsOneWidget);
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

  testWidgets('activity feedback action survives 200 percent text scaling', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        preparer: _ActivityPreparer(),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    final action = find.byKey(
      const Key('activity-feedback-button-existing-activity'),
    );
    await tester.scrollUntilVisible(
      action,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(action, findsOneWidget);
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
    final wellbeing = _FakeWellbeingMutator();
    final day = LifeDay(2026, 7, 25);
    final summary = _dailySummary(day);
    final review = HistoricalDayReview(
      summary: summary,
      actualState: null,
      corrections: const CorrectionCounts(lower: 0, aboutRight: 0, higher: 0),
    );
    await tester.pumpWidget(
      _testApp(
        wellbeing: wellbeing,
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
    expect(find.text('昨天结束时的整体状态'), findsOneWidget);
    expect(find.byKey(const Key('actual-state-selection')), findsOneWidget);
    await tester.tap(find.byKey(const Key('actual-okay')));
    final coverage = find.byKey(const Key('coverage-confirmed'));
    await tester.ensureVisible(coverage);
    await tester.tap(coverage);
    await tester.pump();
    final save = find.byKey(const Key('save-actual-state-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      wellbeing.savedReferenceType,
      ObservationReferenceType.previousLifeDayEnd,
    );
    expect(wellbeing.savedTargetLifeDay, day);
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
    expect(find.text('已保存，将从下一生活日起生效。'), findsOneWidget);
  });

  testWidgets('formal settings gate keeps both learning families off', (
    tester,
  ) async {
    final settingsMutator = _FakeSettingsMutator();
    await tester.pumpWidget(_testApp(settingsMutator: settingsMutator));
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(context).pushNamed(AppRoutes.settings);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('learning-preproduction-watermark')),
      findsNothing,
    );
    final settingsScroll = find
        .descendant(
          of: find.byKey(SettingsPage.pageKey),
          matching: find.byType(Scrollable),
        )
        .first;
    for (final key in const [
      'learning-mode-baseline-review',
      'learning-mode-baseline-automatic',
      'learning-mode-activityImpact-review',
      'learning-mode-activityImpact-automatic',
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(Key(key)),
        200,
        scrollable: settingsScroll,
      );
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      final row = tester.widget<ListTile>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(ListTile),
        ),
      );
      expect(row.enabled, isFalse, reason: key);
      expect(row.onTap, isNull, reason: key);
    }
    expect(settingsMutator.learningModeChanges, isEmpty);
  });

  testWidgets('preproduction watermark and family mode controls are explicit', (
    tester,
  ) async {
    const gate = LearningProductionGate(
      baselineProductionLearningEnabled: true,
      activityImpactProductionLearningEnabled: true,
      isPreproductionValidationOverride: true,
    );
    final settingsMutator = _FakeSettingsMutator();
    await tester.pumpWidget(
      _testApp(settingsMutator: settingsMutator, learningGate: gate),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(context).pushNamed(AppRoutes.settings);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('learning-preproduction-watermark')),
      findsOneWidget,
    );
    expect(find.text('工程预生产验证 · 不会进入正式版本'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('预生产')), findsOneWidget);

    await tester.tap(find.byKey(const Key('learning-mode-baseline-review')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('learning-disclosure-dialog')), findsOneWidget);
    expect(find.textContaining('至少提前 24 小时'), findsOneWidget);
    expect(find.textContaining('相对锚点累计不超过 ±8'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('accept-learning-disclosure-button')),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('learning-mode-activityImpact-automatic')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(SettingsPage.pageKey),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(
      find.byKey(const Key('learning-mode-activityImpact-automatic')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('learning-mode-activityImpact-automatic')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('accept-learning-disclosure-button')),
    );
    await tester.pumpAndSettle();

    expect(settingsMutator.learningModeChanges, [
      'baseline:review',
      'activityImpact:automatic',
    ]);
    semantics.dispose();
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
    await tester.scrollUntilVisible(
      find.byKey(const Key('restore-json-button')),
      400,
      scrollable: find
          .descendant(
            of: find.byKey(SettingsPage.pageKey),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('restore-json-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings separates local save, share, health and restore', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(context).pushNamed(AppRoutes.settings);
    await tester.pumpAndSettle();

    final list = find.descendant(
      of: find.byKey(SettingsPage.pageKey),
      matching: find.byType(ListView),
    );
    await tester.drag(list, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('save-local-backup-button')), findsOneWidget);
    expect(find.text('分享 JSON'), findsOneWidget);
    expect(find.byKey(const Key('data-health-button')), findsOneWidget);
    expect(find.byKey(const Key('restore-json-button')), findsOneWidget);
  });

  testWidgets('settings content survives a preparation dependency reload', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(reloadSettingsWithPreparation: true));
    await tester.pumpAndSettle();
    final homeContext = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(homeContext).pushNamed(AppRoutes.settings);
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('base-estimate-field'));
    await tester.enterText(field, '123');
    final settingsContext = tester.element(find.byKey(SettingsPage.pageKey));
    final container = ProviderScope.containerOf(settingsContext, listen: false);

    container
        .read(currentPreparationRefreshProvider.notifier)
        .refresh(PreparationTrigger.resumed);
    await tester.pump();

    expect(find.byKey(SettingsPage.pageKey), findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, '123');

    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, '123');
    expect(tester.takeException(), isNull);
  });

  testWidgets('MVP-B upgrade readiness prepares and reveals verified state', (
    tester,
  ) async {
    final readiness = _FakeMvpBUpgradeReadiness();
    await tester.pumpWidget(_testApp(mvpBUpgradeReadiness: readiness));
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(context).pushNamed(AppRoutes.settings);
    await tester.pumpAndSettle();

    final button = find.byKey(const Key('prepare-mvp-b-upgrade-button'));
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const Key('mvp-b-upgrade-not-ready-label')),
      findsOneWidget,
    );

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(readiness.prepareCalls, 1);
    expect(
      find.byKey(const Key('mvp-b-upgrade-ready-details')),
      findsOneWidget,
    );
    expect(find.textContaining('schema v3'), findsOneWidget);
  });

  testWidgets('data health shows aggregate coverage without private details', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(context).pushNamed(AppRoutes.dataHealth);
    await tester.pumpAndSettle();

    expect(find.byKey(DataHealthPage.pageKey), findsOneWidget);
    expect(find.text('完整性检查通过'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('validation-progress-card')),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('0 / 6'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.textContaining('旧版自用讨论计数还差 14'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('mvp-b-upgrade-readiness-health-card')),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mvp-b-upgrade-readiness-health-card')),
      findsOneWidget,
    );
    expect(find.textContaining('activity-'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'data health shows read-only automatic learning and safe failure',
    (tester) async {
      final progress = AutomaticLearningProgress(
        referenceType: ObservationReferenceType.currentMoment,
        sourceModelIdentity: 'private-model-hash',
        eligibleTotal: 13,
        selectedEligible: 13,
        excludedTotal: 2,
        missingToMinimum: 1,
        spanCalendarDays: 20,
        earliestLifeDay: LifeDay(2026, 7, 1),
        latestLifeDay: LifeDay(2026, 7, 21),
        directionCounts: const DirectionCounts(lower: 4, aligned: 5, higher: 4),
        windowDirectionCounts: const [
          DirectionCounts(lower: 2, aligned: 3, higher: 2),
          DirectionCounts(lower: 2, aligned: 2, higher: 2),
        ],
        windowSizes: const [7, 6],
        exclusionCounts: const {},
        ready: false,
        latestRunStatus: LearningRunStatus.retryableFailure,
        latestRunResult: null,
        latestRunAt: DateTime.utc(2026, 8, 9, 12),
        latestRunMatchesCurrentEvidence: true,
      );
      await tester.pumpWidget(
        _testApp(
          dataHealthReport: _dataHealthReport(
            learningRuns: 1,
            retryableLearningRuns: 1,
            automaticLearningProgress: [progress],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byKey(HomePage.pageKey));
      Navigator.of(context).pushNamed(AppRoutes.dataHealth);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('automatic-learning-mode-label')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('automatic-learning-currentMoment')),
        findsOneWidget,
      );
      expect(find.text('13 / 14'), findsOneWidget);
      expect(find.text('20 / 21 天'), findsOneWidget);
      expect(find.textContaining('等待安全重试'), findsOneWidget);
      expect(find.textContaining('private-model-hash'), findsNothing);
      expect(find.textContaining('sha256'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('data health survives 200 percent text scaling', (tester) async {
    await tester.pumpWidget(_testApp(textScaler: const TextScaler.linear(2)));
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(context).pushNamed(AppRoutes.dataHealth);
    await tester.pumpAndSettle();

    expect(find.byKey(DataHealthPage.pageKey), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('local-backup-health-card')),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('local-backup-health-card')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('data health failure hides internal details and can retry', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(dataHealthFails: true));
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(context).pushNamed(AppRoutes.dataHealth);
    await tester.pumpAndSettle();

    expect(find.textContaining('当前数据没有改变'), findsOneWidget);
    expect(find.textContaining('private-record-id'), findsNothing);
    expect(find.byKey(const Key('retry-data-health-button')), findsOneWidget);
  });

  testWidgets('existing local backup metadata is visible in settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        localBackupMetadata: LocalBackupMetadata(
          path: 'backup.json',
          modifiedAt: DateTime.utc(2026, 8, 9, 12),
          byteLength: 4096,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(context).pushNamed(AppRoutes.settings);
    await tester.pumpAndSettle();
    final list = find.descendant(
      of: find.byKey(SettingsPage.pageKey),
      matching: find.byType(ListView),
    );
    await tester.drag(list, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('local-backup-metadata-label')),
      findsOneWidget,
    );
    expect(find.textContaining('4.0 KiB'), findsOneWidget);
    expect(find.byKey(const Key('share-local-backup-button')), findsOneWidget);
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
    final settingsList = find.descendant(
      of: find.byKey(SettingsPage.pageKey),
      matching: find.byType(ListView),
    );
    await tester.drag(settingsList, const Offset(0, -1600));
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
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.byKey(const Key('record-gesture-overlay')), findsOneWidget);

    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('gesture-node-0'))),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('gesture-node-0'))),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('15 分\n-5'), findsOneWidget);
    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('gesture-node-0'))),
    );
    await tester.pump(const Duration(milliseconds: 550));
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
    await tester.pump(const Duration(milliseconds: 220));

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

  testWidgets('energy gesture waits 200ms before activation', (tester) async {
    await tester.pumpWidget(_testApp(disableAnimations: false));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(HomePage.pageKey), findsOneWidget);

    final center = tester.getCenter(
      find.byKey(const Key('energy-gesture-surface')),
    );
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 180));
    expect(find.byKey(const Key('record-gesture-overlay')), findsNothing);

    await tester.pump(const Duration(milliseconds: 30));
    expect(find.byKey(const Key('record-gesture-overlay')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 360));
    expect(tester.takeException(), isNull);
    await gesture.up();
    await tester.pump();
  });

  testWidgets('20 quick radial passes never confirm a node', (tester) async {
    final mutator = _FakeActivityMutator();
    await tester.pumpWidget(_testApp(mutator: mutator));
    await tester.pumpAndSettle();

    final surface = find.byKey(const Key('energy-gesture-surface'));
    final center = tester.getCenter(surface);
    for (var index = 0; index < 20; index += 1) {
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 220));
      final node = tester.getCenter(
        find.byKey(Key('gesture-node-${index % 4}')),
      );
      await gesture.moveTo(node);
      await tester.pump(const Duration(milliseconds: 80));
      await gesture.moveTo(center + const Offset(0, -90));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('滑向大类，停留确认'), findsOneWidget);
      expect(mutator.createCount, 0);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 260));
    }

    expect(mutator.createCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('radial node keeps sticky selection and uses energy semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(morningStatus: MorningCompletionStatus.completed),
    );
    await tester.pumpAndSettle();

    final center = tester.getCenter(
      find.byKey(const Key('energy-gesture-surface')),
    );
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 220));
    final nodeFinder = find.byKey(const Key('gesture-node-0'));
    final nodeCenter = tester.getCenter(nodeFinder);
    await gesture.moveTo(nodeCenter);
    await tester.pump(const Duration(milliseconds: 100));

    final semantics = tester.ensureSemantics();
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('学习'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    final container = tester.widget<AnimatedContainer>(
      find.descendant(of: nodeFinder, matching: find.byType(AnimatedContainer)),
    );
    final decoration = container.decoration! as BoxDecoration;
    final border = decoration.border! as Border;
    expect(border.top.color, AppColors.energyHigh);

    await gesture.moveTo(nodeCenter + const Offset(50, 0));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('滑向大类，停留确认'), findsOneWidget);
    expect(find.text('上课'), findsNothing);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('上课'), findsOneWidget);

    await gesture.up();
    await tester.pump();
    semantics.dispose();
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
    await tester.pump(const Duration(milliseconds: 220));
    await incomplete.moveBy(const Offset(0, -60));
    await incomplete.up();
    await tester.pump();
    expect(mutator.createCount, 0);

    final timedOut = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 220));
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
  AutomaticLearningRequester? learningRequester,
  Clock? clock,
  ActivityMutator? mutator,
  MorningCompletionStatus morningStatus = MorningCompletionStatus.notAnswered,
  WellbeingMutator? wellbeing,
  TextScaler textScaler = TextScaler.noScaling,
  HistoryReview? history,
  AppSettings? appSettings,
  SettingsMutator? settingsMutator,
  LearningProductionGate? learningGate,
  EnergyObservation? currentActual,
  Map<String, ActivityFeedback> currentActivityFeedback = const {},
  bool canSupplementYesterday = false,
  LocalBackupSaver? localBackupSaver,
  LocalBackupMetadata? localBackupMetadata,
  MvpBUpgradeReadinessPreparer? mvpBUpgradeReadiness,
  DataHealthReport? dataHealthReport,
  bool dataHealthFails = false,
  bool reloadSettingsWithPreparation = false,
  bool disableAnimations = true,
}) {
  final readinessService = mvpBUpgradeReadiness ?? _FakeMvpBUpgradeReadiness();
  return ProviderScope(
    overrides: [
      if (clock != null) clockProvider.overrideWithValue(clock),
      operationPreparerProvider.overrideWithValue(preparer ?? _FakePreparer()),
      automaticLearningRequesterProvider.overrideWithValue(
        learningRequester ?? _FakeAutomaticLearningRequester(),
      ),
      morningCompletionStatusProvider.overrideWith(
        (ref) async => morningStatus,
      ),
      currentMorningCheckInProvider.overrideWith((ref) async => null),
      currentDailyObservationProvider.overrideWith(
        (ref) async => currentActual,
      ),
      currentActivityFeedbackProvider.overrideWith(
        (ref) async => currentActivityFeedback,
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
      appSettingsProvider.overrideWith((ref) async {
        if (reloadSettingsWithPreparation) {
          ref.watch(currentPreparationRefreshProvider);
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        return appSettings ?? _appSettings(onboardingCompleted: true);
      }),
      activePersonalizationVersionProvider.overrideWith(
        (ref) async => initialPersonalizationVersion(
          baseEnergy: 100,
          createdAt: DateTime.utc(2026, 7, 26),
        ),
      ),
      pendingPersonalizationVersionProvider.overrideWith((ref) async => null),
      settingsServiceProvider.overrideWithValue(
        settingsMutator ?? _FakeSettingsMutator(),
      ),
      if (learningGate != null)
        learningProductionGateProvider.overrideWithValue(learningGate),
      backupSafetyPathProvider.overrideWith((ref) async => null),
      localBackupServiceProvider.overrideWithValue(
        localBackupSaver ?? _FakeLocalBackupSaver(),
      ),
      localBackupMetadataProvider.overrideWith(
        (ref) async => localBackupMetadata,
      ),
      mvpBUpgradeReadinessServiceProvider.overrideWithValue(readinessService),
      dataHealthReportProvider.overrideWith((ref) async {
        if (dataHealthFails) {
          throw StateError('private-record-id must not be shown');
        }
        return dataHealthReport ?? _dataHealthReport();
      }),
      activityImpactPreviewServiceProvider.overrideWithValue(
        _FakeActivityImpactPreviewer(),
      ),
      currentActivityImpactCatalogProvider.overrideWith(
        (ref) async => _impactCatalog(),
      ),
      if (mutator != null) activityUseCasesProvider.overrideWithValue(mutator),
      if (wellbeing != null)
        wellbeingUseCasesProvider.overrideWithValue(wellbeing),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: const Size(800, 600),
        textScaler: textScaler,
        disableAnimations: disableAnimations,
      ),
      child: const PowerManagerApp(),
    ),
  );
}

final class _FakeLocalBackupSaver implements LocalBackupSaver {
  @override
  Future<LocalBackupMetadata> saveLatest() async => LocalBackupMetadata(
    path: 'backup.json',
    modifiedAt: DateTime.utc(2026, 8, 9, 12),
    byteLength: 4096,
  );
}

final class _FakeMvpBUpgradeReadiness implements MvpBUpgradeReadinessPreparer {
  _FakeMvpBUpgradeReadiness({
    MvpBUpgradeReadinessReport? initial,
    MvpBUpgradeReadinessReport? afterPrepare,
  }) : current = initial ?? _notReadyReadiness(),
       _afterPrepare = afterPrepare ?? _readyReadiness();

  MvpBUpgradeReadinessReport current;
  final MvpBUpgradeReadinessReport _afterPrepare;
  var prepareCalls = 0;

  @override
  Future<MvpBUpgradeReadinessReport> check() async => current;

  @override
  Future<MvpBUpgradeReadinessReport> prepare() async {
    prepareCalls++;
    current = _afterPrepare;
    return current;
  }
}

MvpBUpgradeReadinessReport _notReadyReadiness() => MvpBUpgradeReadinessReport(
  status: MvpBUpgradeReadinessStatus.notChecked,
  checkedAt: DateTime.utc(2026, 8, 9, 12),
);

MvpBUpgradeReadinessReport _readyReadiness() => MvpBUpgradeReadinessReport(
  status: MvpBUpgradeReadinessStatus.ready,
  checkedAt: DateTime.utc(2026, 8, 9, 12),
  verifiedAt: DateTime.utc(2026, 8, 9, 12),
  localBackup: LocalBackupMetadata(
    path: 'backup.json',
    modifiedAt: DateTime.utc(2026, 8, 9, 12),
    byteLength: 4096,
  ),
  backupSchemaVersion: 3,
);

DataHealthReport _dataHealthReport({
  int learningRuns = 0,
  int retryableLearningRuns = 0,
  int terminalLearningRuns = 0,
  List<AutomaticLearningProgress> automaticLearningProgress = const [],
}) => DataHealthReport(
  checkedAt: DateTime.utc(2026, 8, 9, 12),
  schemaVersion: 3,
  integrityPassed: true,
  settledDays: 8,
  standardEffectiveDays: 5,
  weakEffectiveDays: 1,
  effectiveDaysWithActualState: 0,
  morningCheckIns: 7,
  activityRecords: 27,
  deletedActivityRecords: 0,
  dailyActualStates: 0,
  relativeCorrections: 1,
  learningRuns: learningRuns,
  retryableLearningRuns: retryableLearningRuns,
  terminalLearningRuns: terminalLearningRuns,
  automaticLearningProgress: automaticLearningProgress,
  localBackup: null,
  mvpBUpgradeReadiness: _notReadyReadiness(),
);

final class _FakeActivityImpactPreviewer implements ActivityImpactPreviewer {
  @override
  Future<ActivityImpactCatalog> previewCatalog({
    required CurrentDayProjection current,
    required DateTime completedAt,
    String? editingActivityId,
  }) async => _impactCatalog();
}

ActivityImpactCatalog _impactCatalog() => {
  for (final subcategory in ActivitySubcategory.values)
    subcategory: {
      for (final duration in DurationSlot.values)
        duration: ActivityImpactPreview(
          subcategory: subcategory,
          duration: duration,
          theoreticalDelta:
              subcategory == ActivitySubcategory.nap &&
                  duration == DurationSlot.minutes15
              ? 5
              : -5,
          projectedAppliedDelta:
              subcategory == ActivitySubcategory.nap &&
                  duration == DurationSlot.minutes15
              ? 0
              : -5,
          estimateBefore: 100,
          estimateAfter:
              subcategory == ActivitySubcategory.nap &&
                  duration == DurationSlot.minutes15
              ? 100
              : 95,
        ),
    },
};

final class _FakeSettingsMutator implements SettingsMutator {
  final scheduled = <int>[];
  final learningModeChanges = <String>[];
  var onboardingCount = 0;

  @override
  Future<AppSettings> completeOnboarding() async {
    onboardingCount++;
    return _appSettings(onboardingCompleted: true);
  }

  @override
  Future<AppSettings> scheduleBaseEstimate(int value) async {
    scheduled.add(value);
    return _appSettings(onboardingCompleted: true);
  }

  @override
  Future<AppSettings> setLearningMode({
    required LearningParameterFamily parameterFamily,
    required LearningMode mode,
    required bool acceptCurrentDisclosure,
  }) async {
    learningModeChanges.add('${parameterFamily.code}:${mode.code}');
    return _appSettings(
      onboardingCompleted: true,
      baselineLearningMode: parameterFamily == LearningParameterFamily.baseline
          ? mode
          : LearningMode.off,
      activityImpactLearningMode:
          parameterFamily == LearningParameterFamily.activityImpact
          ? mode
          : LearningMode.off,
    );
  }
}

final class _FakeActivityMutator implements ActivityMutator {
  var createCount = 0;
  var deleteCount = 0;
  var restoreCount = 0;

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

  @override
  Future<ActivityMutationResult> restore(String activityId) async {
    restoreCount++;
    return ActivityMutationResult(
      activity: _storedActivity(
        id: activityId,
        category: ActivityCategory.study,
        subcategory: ActivitySubcategory.homework,
        duration: DurationSlot.minutes30,
        completedAt: DateTime(2026, 7, 26, 10),
      ),
      current: _currentProjectionWithActivity(),
      wasAlreadyApplied: false,
    );
  }
}

final class _FakeWellbeingMutator implements WellbeingMutator {
  MorningCheckIn? savedMorning;
  AbsoluteEnergyState? savedActual;
  ObservationCoverageState? savedCoverage;
  ObservationReferenceType? savedReferenceType;
  LifeDay? savedTargetLifeDay;
  RelativeCorrection? savedCorrection;
  Completer<void>? actualGate;
  var failRelative = false;
  var failActual = false;

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
    required ObservationReferenceType referenceType,
    required AbsoluteEnergyState state,
    required ObservationCoverageState coverageState,
  }) async {
    savedActual = state;
    savedCoverage = coverageState;
    savedReferenceType = referenceType;
    savedTargetLifeDay = targetLifeDay;
    await actualGate?.future;
    if (failActual) {
      throw StateError('simulated actual failure');
    }
    final observation = EnergyObservation(
      id: observationId,
      lifeDay: targetLifeDay,
      type: EnergyObservationType.dailyAbsolute,
      absoluteState: state,
      relativeState: null,
      estimateAtObservation: null,
      observedAt: DateTime.utc(2026, 7, 26, 12),
      contractVersion: mvpBObservationContractV1,
      referenceType: referenceType,
      coverageState: coverageState,
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
    if (failRelative) {
      throw StateError('simulated relative correction failure');
    }
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
    return _preparationResult(trigger, _currentProjection());
  }
}

final class _FakeAutomaticLearningRequester
    implements AutomaticLearningRequester {
  _FakeAutomaticLearningRequester({this.fail = false});

  final bool fail;
  final triggers = <AutomaticLearningTrigger>[];

  @override
  Future<LearningCoordinationReport> request(
    AutomaticLearningTrigger trigger,
  ) async {
    triggers.add(trigger);
    if (fail) throw StateError('simulated shadow learning failure');
    return LearningCoordinationReport(
      trigger: trigger,
      createdRuns: 0,
      resumedRuns: 0,
      completedRuns: 0,
      retryableFailures: 0,
      terminalFailures: 0,
      skipReason: LearningCoordinationSkipReason.unchangedEvidence,
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
    if (attempts == 1) {
      throw StateError('database unavailable: internal test detail');
    }
    return _FakePreparer().prepare(trigger);
  }
}

final class _RecordingPreparer implements OperationPreparer {
  final triggers = <PreparationTrigger>[];

  @override
  Future<OperationPreparationResult> prepare(PreparationTrigger trigger) {
    triggers.add(trigger);
    final estimate = triggers.length == 1 ? 100 : 72;
    return Future.value(
      _preparationResult(
        trigger,
        _currentProjection(currentEstimate: estimate),
      ),
    );
  }
}

final class _MutableClock implements Clock {
  _MutableClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

OperationPreparationResult _preparationResult(
  PreparationTrigger trigger,
  CurrentDayProjection current,
) {
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

CurrentDayProjection _currentProjection({int currentEstimate = 100}) {
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
      currentEstimate: currentEstimate,
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
  LearningMode baselineLearningMode = LearningMode.off,
  LearningMode activityImpactLearningMode = LearningMode.off,
}) {
  return AppSettings(
    activeRuleVersion: 'energy-rules-v2-mvp-a',
    pendingRuleVersion: null,
    pendingRuleEffectiveLifeDay: null,
    onboardingCompleted: onboardingCompleted,
    baselineLearningMode: baselineLearningMode,
    activityImpactLearningMode: activityImpactLearningMode,
    createdAt: DateTime.utc(2026, 7, 26),
    updatedAt: DateTime.utc(2026, 7, 26),
  );
}
