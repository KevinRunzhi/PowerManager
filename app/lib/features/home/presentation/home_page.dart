import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/app/theme/app_colors.dart';
import 'package:power_manager/app/theme/app_spacing.dart';
import 'package:power_manager/application/activity_use_cases.dart';
import 'package:power_manager/application/home_view_model.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/application/wellbeing_use_cases.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/estimated_activity.dart';
import 'package:power_manager/features/activity/presentation/activity_record_sheet.dart';
import 'package:power_manager/features/wellbeing/presentation/actual_state_sheet.dart';
import 'package:power_manager/features/wellbeing/presentation/morning_check_in_sheet.dart';
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
    final viewModel = HomeViewModel.fromProjection(result.current);
    final morningStatus = switch (ref.watch(morningCompletionStatusProvider)) {
      AsyncData(:final value) => value,
      _ =>
        result.current.morningCheckInCompleted
            ? MorningCompletionStatus.completed
            : MorningCompletionStatus.notAnswered,
    };
    final canSupplementYesterday =
        ref.watch(canSupplementYesterdayProvider).value ?? false;
    final reminderMessage = ref.watch(energyReminderMessageProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(undoWindowActiveProvider)) {
        _maybeShowReminder(ref, viewModel);
      }
    });
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.x4)),
        SliverToBoxAdapter(
          child: _MorningHint(
            status: morningStatus,
            onTap: () =>
                MorningCheckInSheet.show(context, result.current.lifeDay),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.x8)),
        SliverToBoxAdapter(
          child: _EnergyBall(
            estimate: projection.currentEstimate,
            morningCompleted:
                morningStatus == MorningCompletionStatus.completed,
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: Text(
              '初始 ${viewModel.initialEstimate} · ${viewModel.bandLabel}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _ReminderBar(
            message: reminderMessage,
            onDismiss: () =>
                ref.read(energyReminderMessageProvider.notifier).dismiss(),
          ),
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
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.x6)),
        SliverToBoxAdapter(
          child: _WellbeingTools(
            onOverview: () => _showOverview(context, viewModel),
            hasCurrentActual:
                ref.watch(currentDailyObservationProvider).value != null,
            canSupplementYesterday: canSupplementYesterday,
            onActual: () =>
                ActualStateSheet.show(context, lifeDay: result.current.lifeDay),
            onCorrection: () => RelativeCorrectionSheet.show(context),
            onYesterday: () => ActualStateSheet.show(
              context,
              lifeDay: result.current.lifeDay.previous,
              isYesterday: true,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.x12)),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    ref.read(undoWindowActiveProvider.notifier).setActive(true);
    final result = await ActivityRecordSheet.show(context);
    if (result == null || !context.mounted) {
      ref.read(undoWindowActiveProvider.notifier).setActive(false);
      return;
    }
    _showUndo(context, ref, result);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    EstimatedActivityRecord activity,
  ) async {
    final result = await ActivityRecordSheet.show(context, initial: activity);
    if (result != null) {
      await _maybeShowReminder(
        ref,
        HomeViewModel.fromProjection(result.current),
      );
    }
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
    ref.read(undoWindowActiveProvider.notifier).setActive(true);
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
            ref.read(undoWindowActiveProvider.notifier).setActive(false);
            await ref.read(activityUseCasesProvider).delete(activity.id);
            ref.invalidate(currentPreparationProvider);
          },
        ),
      ),
    );
    closeTimer = Timer(const Duration(seconds: 5), () async {
      controller.close();
      ref.read(undoWindowActiveProvider.notifier).setActive(false);
      final current = await ref.read(currentPreparationProvider.future);
      await _maybeShowReminder(
        ref,
        HomeViewModel.fromProjection(current.current),
      );
    });
  }

  Future<void> _maybeShowReminder(
    WidgetRef ref,
    HomeViewModel viewModel,
  ) async {
    if (viewModel.band == EstimatedEnergyBand.estimatedNormal) {
      return;
    }
    final message = await ref
        .read(energyReminderServiceProvider)
        .createOnce(lifeDay: result.current.lifeDay, band: viewModel.band);
    if (message != null) {
      ref.read(energyReminderMessageProvider.notifier).show(message);
    }
  }

  Future<void> _showOverview(BuildContext context, HomeViewModel viewModel) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => _TodayOverviewSheet(viewModel: viewModel),
    );
  }

  String _signed(int value) => value > 0 ? '+$value' : '$value';
}

class _EnergyBall extends StatelessWidget {
  const _EnergyBall({required this.estimate, required this.morningCompleted});

  final int estimate;
  final bool morningCompleted;

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
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF5EEAD4,
                ).withValues(alpha: morningCompleted ? 0.14 : 0.06),
                blurRadius: 64,
                spreadRadius: 8,
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: diameter * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    morningCompleted ? '估计精力' : '估计精力 · 未晨间确认',
                    textAlign: TextAlign.center,
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
  const _MorningHint({required this.status, required this.onTap});

  final MorningCompletionStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      MorningCompletionStatus.notAnswered => '晨间确认（可跳过）',
      MorningCompletionStatus.skipped => '今天已跳过晨间确认 · 可补做',
      MorningCompletionStatus.completed => '晨间已确认 · 可修改',
    };
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
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
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _WellbeingTools extends StatelessWidget {
  const _WellbeingTools({
    required this.onOverview,
    required this.hasCurrentActual,
    required this.canSupplementYesterday,
    required this.onActual,
    required this.onCorrection,
    required this.onYesterday,
  });

  final bool hasCurrentActual;
  final bool canSupplementYesterday;
  final VoidCallback onActual;
  final VoidCallback onCorrection;
  final VoidCallback onYesterday;
  final VoidCallback onOverview;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.x2,
          runSpacing: AppSpacing.x2,
          children: [
            OutlinedButton(
              key: const Key('today-overview-button'),
              onPressed: onOverview,
              child: const Text('今日概览'),
            ),
            OutlinedButton(
              key: const Key('actual-state-button'),
              onPressed: onActual,
              child: Text(hasCurrentActual ? '修改今日实际状态' : '记录今日实际状态'),
            ),
            OutlinedButton(
              key: const Key('relative-correction-button'),
              onPressed: onCorrection,
              child: const Text('此刻校正'),
            ),
            if (canSupplementYesterday)
              OutlinedButton(
                key: const Key('yesterday-actual-button'),
                onPressed: onYesterday,
                child: const Text('补充昨日实际状态'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReminderBar extends StatelessWidget {
  const _ReminderBar({required this.message, required this.onDismiss});

  final String? message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      child: message == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.x3),
              child: Material(
                color: AppColors.energyMediumLow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  key: const Key('energy-reminder-bar'),
                  title: Text(message!),
                  trailing: IconButton(
                    tooltip: '关闭提醒',
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            ),
    );
  }
}

class _TodayOverviewSheet extends StatelessWidget {
  const _TodayOverviewSheet({required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '今日概览',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.x4),
          if (viewModel.categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.page),
              child: Text('今天还没有活动记录。', textAlign: TextAlign.center),
            )
          else
            for (final item in viewModel.categories)
              Card(
                key: Key('overview-${item.category.code}'),
                child: ListTile(
                  title: Text(item.category.label),
                  subtitle: Text(
                    '${item.durationMinutes} 分钟 · 变化总量 ${item.grossDelta}',
                  ),
                  trailing: Text(
                    item.netDelta > 0
                        ? '+${item.netDelta}'
                        : '${item.netDelta}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            '按变化总量排序，右侧展示估计精力净变化。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
