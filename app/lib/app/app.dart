import 'package:flutter/material.dart';
import 'package:power_manager/app/app_routes.dart';
import 'package:power_manager/app/theme/app_theme.dart';

class PowerManagerApp extends StatelessWidget {
  const PowerManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '精力值',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
