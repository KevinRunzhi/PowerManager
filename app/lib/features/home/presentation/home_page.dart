import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:power_manager/app/theme/app_colors.dart';
import 'package:power_manager/app/theme/app_spacing.dart';
import 'package:power_manager/shared/widgets/debug_stage_banner.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const pageKey = Key('home-page');
  static const energyBallKey = Key('energy-ball-placeholder');
  static const recordButtonKey = Key('record-button-placeholder');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: pageKey,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            minimum: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.x3),
                const _MorningHint(),
                const Spacer(flex: 3),
                const _EnergyBallPlaceholder(),
                const SizedBox(height: AppSpacing.x6),
                Semantics(
                  button: true,
                  enabled: false,
                  label: '记录活动，功能将在后续阶段开放',
                  child: IconButton(
                    key: recordButtonKey,
                    onPressed: null,
                    tooltip: '记录活动',
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
                const Spacer(flex: 4),
                const _BottomToolsPlaceholder(),
                const SizedBox(height: AppSpacing.x8),
              ],
            ),
          ),
          const DebugStageBanner(),
        ],
      ),
    );
  }
}

class _MorningHint extends StatelessWidget {
  const _MorningHint();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '晨间确认尚未处理',
      child: Column(
        children: [
          Container(
            width: 34,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text('晨间确认', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _EnergyBallPlaceholder extends StatelessWidget {
  const _EnergyBallPlaceholder();

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final diameter = math
        .min(viewport.width * 0.58, viewport.height * 0.38)
        .clamp(132.0, 280.0);

    return Semantics(
      key: HomePage.energyBallKey,
      label: '估计精力，等待初始化',
      readOnly: true,
      child: ExcludeSemantics(
        child: Container(
          width: diameter,
          height: diameter,
          constraints: const BoxConstraints(
            minWidth: 132,
            minHeight: 132,
            maxWidth: 280,
            maxHeight: 280,
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.25, -0.3),
              radius: 0.95,
              colors: [
                Color(0x335EEAD4),
                Color(0x267DD3FC),
                AppColors.backgroundOverlay,
              ],
              stops: [0, 0.48, 1],
            ),
            border: Border.all(color: AppColors.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x245EEAD4),
                blurRadius: 64,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '估计精力',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(letterSpacing: 2.2),
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                '···',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomToolsPlaceholder extends StatelessWidget {
  const _BottomToolsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;

    return Semantics(
      label: '后续功能入口占位',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('上滑查看今日概览', style: style),
            const SizedBox(width: AppSpacing.x6),
            Text('实际状态', style: style),
            const SizedBox(width: AppSpacing.x6),
            Text('设置', style: style),
          ],
        ),
      ),
    );
  }
}
