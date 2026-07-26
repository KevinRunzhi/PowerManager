import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

class MorningCheckInSheet extends ConsumerStatefulWidget {
  const MorningCheckInSheet({super.key, required this.lifeDay});

  final LifeDay lifeDay;

  static Future<void> show(BuildContext context, LifeDay lifeDay) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MorningCheckInSheet(lifeDay: lifeDay),
    );
  }

  @override
  ConsumerState<MorningCheckInSheet> createState() =>
      _MorningCheckInSheetState();
}

class _MorningCheckInSheetState extends ConsumerState<MorningCheckInSheet> {
  MorningOverallState? _overall;
  FreeTimeLevel? _freeTime;
  PressureSource? _pressure;
  SleepRecovery? _sleep;
  var _step = 0;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final existing = await ref.read(currentMorningCheckInProvider.future);
    if (existing != null && mounted) {
      setState(() {
        _overall = existing.overallState;
        _freeTime = existing.freeTimeLevel;
        _pressure = existing.pressureSource;
        _sleep = existing.sleepRecovery;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _step == 0 || _saving
                      ? null
                      : () => setState(() => _step--),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Text(
                    '晨间确认',
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
            Text(
              '${_step + 1} / 4 · ${_title()}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 18),
            Wrap(spacing: 10, runSpacing: 10, children: _choices()),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            if (_step == 0 && _overall == null)
              TextButton(
                onPressed: _saving ? null : _skip,
                child: const Text('今天先跳过，不影响记录'),
              ),
            if (_step == 3 && _sleep != null)
              FilledButton(
                key: const Key('morning-submit-button'),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('完成晨间确认'),
              ),
          ],
        ),
      ),
    );
  }

  String _title() => switch (_step) {
    0 => '综合状态（影响估计）',
    1 => '可自由安排时间',
    2 => '主要压力来源',
    _ => '睡眠恢复感（只作上下文）',
  };

  List<Widget> _choices() {
    return switch (_step) {
      0 => [
        _choice('差', MorningOverallState.bad, _overall, (value) {
          _overall = value;
        }),
        _choice('一般', MorningOverallState.normal, _overall, (value) {
          _overall = value;
        }),
        _choice('好', MorningOverallState.good, _overall, (value) {
          _overall = value;
        }),
      ],
      1 => [
        _choice('少', FreeTimeLevel.low, _freeTime, (value) {
          _freeTime = value;
        }),
        _choice('中', FreeTimeLevel.medium, _freeTime, (value) {
          _freeTime = value;
        }),
        _choice('多', FreeTimeLevel.high, _freeTime, (value) {
          _freeTime = value;
        }),
      ],
      2 => [
        _choice('学习', PressureSource.study, _pressure, (value) {
          _pressure = value;
        }),
        _choice('实践事务', PressureSource.practice, _pressure, (value) {
          _pressure = value;
        }),
        _choice('都有', PressureSource.both, _pressure, (value) {
          _pressure = value;
        }),
        _choice('压力不大', PressureSource.low, _pressure, (value) {
          _pressure = value;
        }),
      ],
      _ => [
        _choice('差', SleepRecovery.bad, _sleep, (value) {
          _sleep = value;
        }),
        _choice('一般', SleepRecovery.normal, _sleep, (value) {
          _sleep = value;
        }),
        _choice('好', SleepRecovery.good, _sleep, (value) {
          _sleep = value;
        }),
      ],
    };
  }

  Widget _choice<T>(
    String label,
    T value,
    T? selected,
    void Function(T) assign,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: _saving
          ? null
          : (_) {
              setState(() {
                assign(value);
                if (_step < 3) {
                  _step++;
                }
              });
            },
    );
  }

  Future<void> _skip() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(wellbeingUseCasesProvider)
          .skipMorning(_id('morning-skip'));
      _refresh();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '暂时无法跳过，请重试。';
        });
      }
    }
  }

  Future<void> _save() async {
    if (_overall == null ||
        _freeTime == null ||
        _pressure == null ||
        _sleep == null) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(wellbeingUseCasesProvider)
          .saveMorningCheckIn(
            MorningCheckIn(
              id: _id('morning'),
              lifeDay: widget.lifeDay,
              overallState: _overall!,
              freeTimeLevel: _freeTime!,
              pressureSource: _pressure!,
              sleepRecovery: _sleep!,
              morningAdjustment: _overall!.adjustment,
              completedAt: DateTime.now().toUtc(),
            ),
          );
      _refresh();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存失败，请保留当前选择并重试。';
        });
      }
    }
  }

  void _refresh() {
    ref.invalidate(currentPreparationProvider);
    ref.invalidate(morningCompletionStatusProvider);
    ref.invalidate(currentMorningCheckInProvider);
  }

  String _id(String prefix) =>
      '$prefix-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
