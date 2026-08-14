import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/app/app_routes.dart';
import 'package:power_manager/app/theme/app_theme.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/providers.dart';

class PowerManagerApp extends ConsumerStatefulWidget {
  const PowerManagerApp({super.key});

  @override
  ConsumerState<PowerManagerApp> createState() => _PowerManagerAppState();
}

class _PowerManagerAppState extends ConsumerState<PowerManagerApp>
    with WidgetsBindingObserver {
  static const _initialRoute = String.fromEnvironment(
    'POWER_MANAGER_INITIAL_ROUTE',
    defaultValue: AppRoutes.home,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepare(PreparationTrigger.coldStart);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _prepare(PreparationTrigger.resumed);
    }
  }

  void _prepare(PreparationTrigger trigger) {
    unawaited(
      ref
          .read(operationPreparerProvider)
          .prepare(trigger)
          .then<void>(
            (_) {},
            onError: (Object error, StackTrace stackTrace) {
              FlutterError.reportError(
                FlutterErrorDetails(
                  exception: error,
                  stack: stackTrace,
                  library: 'PowerManager preparation',
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '精力值',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: _initialRoute,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
