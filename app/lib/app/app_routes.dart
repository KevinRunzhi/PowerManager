import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:power_manager/features/debug/presentation/debug_environment_page.dart';
import 'package:power_manager/features/debug/presentation/energy_orb_gallery_page.dart';
import 'package:power_manager/features/home/presentation/home_page.dart';
import 'package:power_manager/features/settings/presentation/settings_page.dart';
import 'package:power_manager/features/settings/presentation/data_health_page.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const debugEnvironment = '/debug/environment';
  static const energyOrbGallery = '/debug/energy-orb';
  static const settings = '/settings';
  static const dataHealth = '/settings/data-health';

  static Route<void> onGenerateRoute(RouteSettings routeSettings) {
    final builder = switch (routeSettings.name) {
      home => (_) => const HomePage(),
      debugEnvironment => (_) => const DebugEnvironmentPage(),
      energyOrbGallery when kDebugMode => (_) => const EnergyOrbGalleryPage(),
      settings => (_) => const SettingsPage(),
      dataHealth => (_) => const DataHealthPage(),
      _ => (_) => const _UnknownRoutePage(),
    };
    return MaterialPageRoute<void>(builder: builder, settings: routeSettings);
  }
}

class _UnknownRoutePage extends StatelessWidget {
  const _UnknownRoutePage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: Text('页面不存在'))),
    );
  }
}
