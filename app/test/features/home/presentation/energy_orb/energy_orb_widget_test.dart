import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:power_manager/features/home/presentation/energy_orb/energy_orb.dart';

void main() {
  testWidgets('fallback preserves value, semantics, and overdraft label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(412, 915), disableAnimations: true),
          child: Scaffold(
            body: EnergyOrb(
              key: Key('orb'),
              estimate: -12,
              initialEstimate: 100,
              energyActivated: true,
              morningCompleted: false,
              shaderEnabled: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('orb')), findsOneWidget);
    expect(find.byKey(const Key('energy-orb-renderer')), findsOneWidget);
    expect(find.text('-12'), findsOneWidget);
    expect(find.text('估计精力 · 未晨间确认'), findsOneWidget);
    expect(find.text('估计透支'), findsOneWidget);

    expect(find.bySemanticsLabel(RegExp('估计精力 -12')), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('large text keeps the information layer renderable', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: EnergyOrb(
              estimate: 120,
              initialEstimate: 100,
              energyActivated: true,
              morningCompleted: true,
              shaderEnabled: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('估计精力'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
