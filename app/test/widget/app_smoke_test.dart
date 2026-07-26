import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/app/app.dart';
import 'package:power_manager/app/app_routes.dart';
import 'package:power_manager/features/debug/presentation/debug_environment_page.dart';
import 'package:power_manager/features/home/presentation/home_page.dart';

void main() {
  testWidgets('app starts inside ProviderScope and renders the home shell', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PowerManagerApp()));
    await tester.pumpAndSettle();

    expect(find.byType(ProviderScope), findsOneWidget);
    expect(find.byKey(HomePage.pageKey), findsOneWidget);
    expect(find.byKey(HomePage.energyBallKey), findsOneWidget);
    expect(find.text('估计精力'), findsOneWidget);
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
    await tester.pumpWidget(const ProviderScope(child: PowerManagerApp()));

    final context = tester.element(find.byKey(HomePage.pageKey));
    Navigator.of(context).pushNamed(AppRoutes.debugEnvironment);
    await tester.pumpAndSettle();

    expect(find.byKey(DebugEnvironmentPage.pageKey), findsOneWidget);
    expect(find.text('开发环境'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shell does not overflow on a compact landscape viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(640, 360);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ProviderScope(child: PowerManagerApp()));
    await tester.pumpAndSettle();

    expect(find.byKey(HomePage.pageKey), findsOneWidget);
    expect(find.byKey(HomePage.energyBallKey), findsOneWidget);
    expect(find.byKey(HomePage.recordButtonKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
