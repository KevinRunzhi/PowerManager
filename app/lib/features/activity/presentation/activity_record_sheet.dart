import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/app/theme/app_colors.dart';
import 'package:power_manager/application/activity_impact_preview_service.dart';
import 'package:power_manager/application/activity_use_cases.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/estimated_activity.dart';
import 'package:power_manager/domain/life_day/life_day_calculator.dart';

class ActivityRecordSheet extends ConsumerStatefulWidget {
  const ActivityRecordSheet({super.key, this.initial});

  final EstimatedActivityRecord? initial;

  static Future<ActivityMutationResult?> show(
    BuildContext context, {
    EstimatedActivityRecord? initial,
  }) {
    return showModalBottomSheet<ActivityMutationResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ActivityRecordSheet(initial: initial),
    );
  }

  @override
  ConsumerState<ActivityRecordSheet> createState() =>
      _ActivityRecordSheetState();
}

class _ActivityRecordSheetState extends ConsumerState<ActivityRecordSheet> {
  static var _idSequence = 0;

  late final String _operationId;
  ActivityCategory? _category;
  ActivitySubcategory? _subcategory;
  DurationSlot? _duration;
  late DateTime _completedAt;
  var _step = 0;
  var _saving = false;
  var _previewLoading = false;
  var _previewRequest = 0;
  ActivityImpactCatalog? _previews;
  String? _error;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _operationId =
        initial?.id ??
        'activity-${DateTime.now().toUtc().microsecondsSinceEpoch}-${_idSequence++}';
    _category = initial?.category;
    _subcategory = initial?.subcategory;
    _duration = initial?.duration;
    _completedAt = initial?.completedAt.toLocal() ?? DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPreviews());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (_step > 0)
                  IconButton(
                    tooltip: '返回上一步',
                    onPressed: _saving ? null : () => setState(() => _step--),
                    icon: const Icon(Icons.arrow_back_rounded),
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    _isEditing ? '编辑活动' : '记录活动',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: '关闭记录活动',
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_step + 1} / 4 · ${_stepTitle()}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  child: KeyedSubtree(key: ValueKey(_step), child: _stepBody()),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_step == 3) ...[
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('activity-submit-button'),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? '保存修改' : '完成记录'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _stepTitle() {
    return switch (_step) {
      0 => '选择大类',
      1 => '选择具体活动',
      2 => '选择时长',
      _ => '选择大致完成时间',
    };
  }

  Widget _stepBody() {
    return switch (_step) {
      0 => _categoryGrid(),
      1 => _subcategoryGrid(),
      2 => _durationGrid(),
      _ => _completionChoices(),
    };
  }

  Widget _categoryGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final category in ActivityCategory.values)
          _ChoiceTile(
            key: Key('category-${category.code}'),
            label: category.label,
            selected: _category == category,
            onTap: () {
              setState(() {
                _category = category;
                if (_subcategory?.category != category) {
                  _subcategory = null;
                }
                _step = 1;
              });
            },
          ),
      ],
    );
  }

  Widget _subcategoryGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final subcategory in ActivitySubcategory.values)
          if (subcategory.category == _category)
            _ChoiceTile(
              key: Key('subcategory-${subcategory.code}'),
              label: subcategory.label,
              selected: _subcategory == subcategory,
              onTap: () {
                setState(() {
                  _subcategory = subcategory;
                  _step = 2;
                });
                _refreshPreviews();
              },
            ),
      ],
    );
  }

  Widget _durationGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final duration in DurationSlot.values)
          _ChoiceTile(
            key: Key('duration-${duration.minutes}'),
            label: '${duration.minutes} 分钟',
            detail: _durationDetail(duration),
            semanticLabel: _durationSemanticLabel(duration),
            selected: _duration == duration,
            onTap: () {
              setState(() {
                _duration = duration;
                _step = 3;
              });
            },
          ),
      ],
    );
  }

  Widget _completionChoices() {
    final now = DateTime.now();
    final currentLifeDay = LifeDayCalculator().lifeDayFor(now);
    final presets =
        <(String, DateTime)>[
          ('刚刚', now),
          ('15 分钟前', now.subtract(const Duration(minutes: 15))),
          ('30 分钟前', now.subtract(const Duration(minutes: 30))),
          ('1 小时前', now.subtract(const Duration(hours: 1))),
          ('2 小时前', now.subtract(const Duration(hours: 2))),
        ].where(
          (item) => LifeDayCalculator().lifeDayFor(item.$2) == currentLifeDay,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_subcategory != null && _duration != null) ...[
          _ImpactSummary(
            preview: _previews?[_subcategory]?[_duration],
            loading: _previewLoading,
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final preset in presets)
              ChoiceChip(
                label: Text(preset.$1),
                selected: _sameMinute(_completedAt, preset.$2),
                onSelected: _saving
                    ? null
                    : (_) {
                        setState(() => _completedAt = preset.$2);
                        _refreshPreviews();
                      },
              ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _saving ? null : _pickTime,
          icon: const Icon(Icons.schedule_rounded),
          label: Text(
            '自定义：${_twoDigits(_completedAt.hour)}:'
            '${_twoDigits(_completedAt.minute)}',
          ),
        ),
      ],
    );
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_completedAt),
      helpText: '选择今天的大致完成时间',
    );
    if (selected == null || !mounted) {
      return;
    }
    final now = DateTime.now();
    setState(() {
      _completedAt = DateTime(
        now.year,
        now.month,
        now.day,
        selected.hour,
        selected.minute,
      );
    });
    await _refreshPreviews();
  }

  Future<void> _refreshPreviews() async {
    final request = ++_previewRequest;
    if (mounted) {
      setState(() => _previewLoading = true);
    }
    try {
      final prepared = await ref.read(currentPreparationProvider.future);
      final previews = await ref
          .read(activityImpactPreviewServiceProvider)
          .previewCatalog(
            current: prepared.current,
            completedAt: _completedAt,
            editingActivityId: widget.initial?.id,
          );
      if (mounted && request == _previewRequest) {
        setState(() {
          _previews = previews;
          _previewLoading = false;
        });
      }
    } catch (_) {
      if (mounted && request == _previewRequest) {
        setState(() {
          _previews = null;
          _previewLoading = false;
        });
      }
    }
  }

  String _durationDetail(DurationSlot duration) {
    if (_previewLoading && _previews == null) return '估计 …';
    final preview = _subcategory == null
        ? null
        : _previews?[_subcategory]?[duration];
    if (preview == null) return '暂时无法预估';
    final value = _signed(preview.projectedAppliedDelta);
    if (!preview.isRecoveryLimited) return '估计 $value';
    final reason = preview.projectedAppliedDelta == 0 ? '已到恢复上限' : '受恢复上限影响';
    return '估计 $value\n规则 ${_signed(preview.theoreticalDelta)} · $reason';
  }

  String _durationSemanticLabel(DurationSlot duration) {
    final preview = _subcategory == null
        ? null
        : _previews?[_subcategory]?[duration];
    if (preview == null) return '${duration.minutes} 分钟，暂时无法预估';
    final delta = preview.projectedAppliedDelta;
    final direction = delta > 0
        ? '增加 $delta'
        : delta < 0
        ? '减少 ${delta.abs()}'
        : '无变化';
    final limited = preview.isRecoveryLimited ? '，受今日恢复上限影响' : '';
    return '${duration.minutes} 分钟，估计$direction$limited';
  }

  String _signed(int value) => value > 0 ? '+$value' : '$value';

  Future<void> _submit() async {
    if (_category == null || _subcategory == null || _duration == null) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final useCases = ref.read(activityUseCasesProvider);
      final result = _isEditing
          ? await useCases.edit(
              activityId: widget.initial!.id,
              category: _category!,
              subcategory: _subcategory!,
              duration: _duration!,
              completedAt: _completedAt,
            )
          : await useCases.create(
              ActivityDraft(
                operationId: _operationId,
                category: _category!,
                subcategory: _subcategory!,
                duration: _duration!,
                completedAt: _completedAt,
              ),
            );
      ref.invalidate(currentPreparationProvider);
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, result);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = _friendlyError(error);
        });
      }
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('future')) {
      return '完成时间不能晚于现在，请重新选择。';
    }
    if (message.contains('life day') || message.contains('read-only')) {
      return '该时间已经属于已结算的生活日，请选择当前生活日。';
    }
    return '保存失败，请检查后重试。';
  }

  bool _sameMinute(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day &&
        left.hour == right.hour &&
        left.minute == right.minute;
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    super.key,
    required this.label,
    this.detail,
    this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? detail;
  final String? semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      child: Semantics(
        button: true,
        selected: selected,
        label: semanticLabel,
        onTap: onTap,
        excludeSemantics: semanticLabel != null,
        child: Material(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: detail == null ? 52 : 88),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, textAlign: TextAlign.center),
                    if (detail case final detail?) ...[
                      const SizedBox(height: 4),
                      Text(
                        detail,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.25,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImpactSummary extends StatelessWidget {
  const _ImpactSummary({required this.preview, required this.loading});

  final ActivityImpactPreview? preview;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final value = preview == null
        ? loading
              ? '正在计算估计变化…'
              : '暂时无法预估，仍可继续记录'
        : '${preview!.subcategory.label} ${preview!.duration.minutes} 分钟'
              ' · 估计 ${_signed(preview!.projectedAppliedDelta)}';
    final detail = preview?.isRecoveryLimited == true
        ? preview!.projectedAppliedDelta == 0
              ? '规则估计 ${_signed(preview!.theoreticalDelta)}，但已到今日恢复上限。'
              : '规则估计 ${_signed(preview!.theoreticalDelta)}，预计受今日恢复上限影响。'
        : null;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.backgroundOverlay,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, key: const Key('activity-impact-summary')),
              if (detail != null) ...[
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _signed(int value) => value > 0 ? '+$value' : '$value';
}
