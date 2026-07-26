import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                  duration: const Duration(milliseconds: 180),
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
                    : (_) => setState(() => _completedAt = preset.$2),
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
  }

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
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Text(label, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
