import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/app/app.dart';
import 'package:power_manager/app/app_routes.dart';
import 'package:power_manager/application/current_day_projection_service.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/domain/energy/current_day_projector.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
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
    expect(recordButton.onPressed, isNull);
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
}

Widget _testApp() {
  return ProviderScope(
    overrides: [operationPreparerProvider.overrideWithValue(_FakePreparer())],
    child: const PowerManagerApp(),
  );
}

final class _FakePreparer implements OperationPreparer {
  @override
  Future<OperationPreparationResult> prepare(PreparationTrigger trigger) async {
    return OperationPreparationResult(
      trigger: trigger,
      nowLocal: DateTime(2026, 7, 26, 12),
      nowUtc: DateTime.utc(2026, 7, 26, 4),
      current: CurrentDayProjection(
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
      ),
      settledSummaries: const [],
      appliedPendingBaseEnergy: false,
      appliedPendingRuleVersion: false,
    );
  }
}
