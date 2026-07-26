import 'package:flutter/material.dart';
import 'package:power_manager/features/debug/presentation/debug_environment_page.dart';
import 'package:power_manager/features/home/presentation/home_page.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const debugEnvironment = '/debug/environment';

  static Route<void> onGenerateRoute(RouteSettings settings) {
    final builder = switch (settings.name) {
      home => (_) => const HomePage(),
      debugEnvironment => (_) => const DebugEnvironmentPage(),
      _ => (_) => const _UnknownRoutePage(),
    };
    return MaterialPageRoute<void>(builder: builder, settings: settings);
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
