import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/app/app_routes.dart';
import 'package:power_manager/app/theme/app_theme.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/domain/life_day/life_day_calculator.dart';

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
  final _lifeDayCalculator = LifeDayCalculator();
  Timer? _lifeDayBoundaryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scheduleLifeDayBoundary();
      }
    });
  }

  @override
  void dispose() {
    _lifeDayBoundaryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _requestPreparation(PreparationTrigger.resumed);
      _scheduleLifeDayBoundary();
    } else {
      _lifeDayBoundaryTimer?.cancel();
      _lifeDayBoundaryTimer = null;
    }
  }

  void _requestPreparation(PreparationTrigger trigger) {
    ref.read(currentPreparationRefreshProvider.notifier).refresh(trigger);
  }

  void _scheduleLifeDayBoundary() {
    _lifeDayBoundaryTimer?.cancel();
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      _lifeDayBoundaryTimer = null;
      return;
    }
    final now = ref.read(clockProvider).now();
    final nextBoundary = _lifeDayCalculator.nextBoundaryAfter(now);
    final delay = nextBoundary.difference(now);
    _lifeDayBoundaryTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!mounted) return;
      ref.read(energyReminderMessageProvider.notifier).dismiss();
      _requestPreparation(PreparationTrigger.lifeDayBoundary);
      _scheduleLifeDayBoundary();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currentPreparationProvider);
    return MaterialApp(
      title: '精力值',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: _initialRoute,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
