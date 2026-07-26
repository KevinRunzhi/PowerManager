import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/app/theme/app_colors.dart';
import 'package:power_manager/app/theme/app_spacing.dart';
import 'package:power_manager/application/activity_use_cases.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/domain/energy/estimated_activity.dart';
import 'package:power_manager/features/activity/presentation/activity_record_sheet.dart';
import 'package:power_manager/shared/widgets/debug_stage_banner.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const pageKey = Key('home-page');
  static const energyBallKey = Key('energy-ball-placeholder');
  static const recordButtonKey = Key('record-button-placeholder');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preparation = ref.watch(currentPreparationProvider);
    return Scaffold(
      key: pageKey,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            minimum: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: preparation.when(
              data: (result) => _LoadedHome(result: result),
              error: (error, _) => _LoadError(
                onRetry: () => ref.invalidate(currentPreparationProvider),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          const DebugStageBanner(),
        ],
      ),
    );
  }
}

class _LoadedHome extends ConsumerWidget {
  const _LoadedHome({required this.result});

  final OperationPreparationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projection = result.current.projection;
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.x4)),
        const SliverToBoxAdapter(child: _MorningHint()),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.x8)),
        SliverToBoxAdapter(
          child: _EnergyBall(estimate: projection.currentEstimate),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.x4)),
        SliverToBoxAdapter(
          child: Center(
            child: IconButton.filledTonal(
              key: HomePage.recordButtonKey,
              onPressed: () => _create(context, ref),
              tooltip: '记录活动',
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.x8)),
        SliverToBoxAdapter(
          child: Row(
            children: [
              Text('今天的记录', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '${projection.activities.length} 条',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.x3)),
        if (projection.activities.isEmpty)
          const SliverToBoxAdapter(child: _EmptyActivities())
        else
          SliverList.separated(
            itemCount: projection.activities.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x2),
            itemBuilder: (context, index) {
              final activity = projection.activities[index];
              return _ActivityTile(
                activity: activity,
                onEdit: () => _edit(context, ref, activity.record),
                onDelete: () => _delete(context, ref, activity.record),
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.x12)),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await ActivityRecordSheet.show(context);
    if (result == null || !context.mounted) {
      return;
    }
    _showUndo(context, ref, result);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    EstimatedActivityRecord activity,
  ) async {
    await ActivityRecordSheet.show(context, initial: activity);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    EstimatedActivityRecord activity,
  ) async {
    try {
      await ref.read(activityUseCasesProvider).delete(activity.id);
      ref.invalidate(currentPreparationProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除失败，请刷新后重试。')));
      }
    }
  }

  void _showUndo(
    BuildContext context,
    WidgetRef ref,
    ActivityMutationResult result,
  ) {
    final activity = result.activity;
    Timer? closeTimer;
    final controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(
          '${activity.subcategory.label} ${activity.duration.minutes} 分钟'
          ' · 估计 ${_signed(activity.appliedDelta)}',
        ),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () async {
            closeTimer?.cancel();
            await ref.read(activityUseCasesProvider).delete(activity.id);
            ref.invalidate(currentPreparationProvider);
          },
        ),
      ),
    );
    closeTimer = Timer(const Duration(seconds: 5), controller.close);
  }

  String _signed(int value) => value > 0 ? '+$value' : '$value';
}

class _EnergyBall extends StatelessWidget {
  const _EnergyBall({required this.estimate});

  final int estimate;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final diameter = math
        .min(viewport.width * 0.58, viewport.height * 0.34)
        .clamp(132.0, 260.0);
    return Center(
      child: Semantics(
        key: HomePage.energyBallKey,
        label: '估计精力 $estimate',
        readOnly: true,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.25, -0.3),
              radius: 0.95,
              colors: [
                Color(0x665EEAD4),
                Color(0x407DD3FC),
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
                '$estimate',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: diameter < 160 ? 42 : 64,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectedEstimatedActivity activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final record = activity.record;
    final localTime = record.completedAt.toLocal();
    return Card(
      child: ListTile(
        title: Text(record.subcategory.label),
        subtitle: Text(
          '${record.category.label} · ${record.duration.minutes} 分钟'
          ' · ${_twoDigits(localTime.hour)}:${_twoDigits(localTime.minute)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activity.appliedDelta > 0
                  ? '+${activity.appliedDelta}'
                  : '${activity.appliedDelta}',
            ),
            IconButton(
              tooltip: '编辑',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: '删除',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
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

class _EmptyActivities extends StatelessWidget {
  const _EmptyActivities();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.page),
      child: Text(
        '还没有记录。点击能量球下方的 + 开始。',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('读取当天状态失败。'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
