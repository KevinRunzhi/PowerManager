import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/application/activity_feedback_use_cases.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';

class ActivityFeedbackSheet extends ConsumerStatefulWidget {
  const ActivityFeedbackSheet({
    super.key,
    required this.activity,
    this.initialFeedback,
  });

  final StoredEstimatedActivity activity;
  final ActivityFeedback? initialFeedback;

  static Future<ActivityFeedbackMutationResult?> show(
    BuildContext context, {
    required StoredEstimatedActivity activity,
    ActivityFeedback? initialFeedback,
  }) {
    return showModalBottomSheet<ActivityFeedbackMutationResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ActivityFeedbackSheet(
        activity: activity,
        initialFeedback: initialFeedback,
      ),
    );
  }

  @override
  ConsumerState<ActivityFeedbackSheet> createState() =>
      _ActivityFeedbackSheetState();
}

class _ActivityFeedbackSheetState extends ConsumerState<ActivityFeedbackSheet> {
  ActivityFeedbackDirection? _direction;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _direction = widget.initialFeedback?.direction;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '这次活动的影响符合吗？',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  key: const Key('cancel-activity-feedback-button'),
                  tooltip: '暂不评价',
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.activity.subcategory.label} · '
              '${widget.activity.duration.minutes} 分钟 · '
              '系统记录 ${_signed(widget.activity.appliedDelta)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '这条反馈只绑定当前活动快照，不会立即修改精力值或规则。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            for (final direction in ActivityFeedbackDirection.values) ...[
              _directionButton(direction),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('save-activity-feedback-button'),
              onPressed: _saving || _direction == null ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_saving ? '正在保存…' : '保存反馈'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  key: const Key('activity-feedback-error'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _directionButton(ActivityFeedbackDirection direction) {
    final selected = direction == _direction;
    return Semantics(
      selected: selected,
      button: true,
      child: OutlinedButton(
        key: Key('activity-feedback-${direction.code}'),
        onPressed: _saving
            ? null
            : () => setState(() {
                _direction = direction;
                _error = null;
              }),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          side: selected
              ? BorderSide(color: Theme.of(context).colorScheme.primary)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(_directionLabel(direction))),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final direction = _direction;
    if (direction == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final now = ref.read(clockProvider).now().toUtc();
      final result = await ref
          .read(activityFeedbackUseCasesProvider)
          .save(
            feedbackId: ref
                .read(recordIdGeneratorProvider)
                .next(prefix: 'feedback', now: now),
            activityId: widget.activity.id,
            expectedActivityUpdatedAt: widget.activity.updatedAt,
            direction: direction,
          );
      ref.invalidate(currentActivityFeedbackProvider);
      ref.invalidate(dataHealthReportProvider);
      ref.invalidate(mvpBUpgradeReadinessProvider);
      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.pop(context, result);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = switch (error) {
          StateError(message: 'staleActivity') => '活动已经变化，请关闭后重新查看。',
          StateError(message: 'activityDeleted') => '这条活动已经删除，不能继续评价。',
          StateError(message: 'lifeDaySettled') => '这个生活日已经结算，不能再评价。',
          _ => '保存失败，当前选择已保留，请重试。',
        };
      });
    }
  }

  String _directionLabel(ActivityFeedbackDirection direction) =>
      switch (direction) {
        ActivityFeedbackDirection.strongerImpact => '实际影响比系统记录更强',
        ActivityFeedbackDirection.aboutRight => '系统记录大致合适',
        ActivityFeedbackDirection.weakerImpact => '实际影响比系统记录更弱',
        ActivityFeedbackDirection.directionMismatch =>
          switch (activityImpactSign(widget.activity.theoreticalDelta)) {
            ActivityImpactSign.consumption => '影响方向不合适：实际更像恢复',
            ActivityImpactSign.recovery => '影响方向不合适：实际更像消耗',
            ActivityImpactSign.zero => '影响方向不合适：不只是强弱问题',
          },
      };

  String _signed(int value) => value > 0 ? '+$value' : '$value';
}
