import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/app/theme/app_colors.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/application/wellbeing_use_cases.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

class ActualStateSheet extends ConsumerStatefulWidget {
  const ActualStateSheet({
    super.key,
    required this.lifeDay,
    required this.referenceType,
    this.initialObservation,
  });

  final LifeDay lifeDay;
  final ObservationReferenceType referenceType;
  final EnergyObservation? initialObservation;

  bool get isYesterday =>
      referenceType == ObservationReferenceType.previousLifeDayEnd;

  static Future<void> show(
    BuildContext context, {
    required LifeDay lifeDay,
    bool isYesterday = false,
    EnergyObservation? initialObservation,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ActualStateSheet(
        lifeDay: lifeDay,
        referenceType: isYesterday
            ? ObservationReferenceType.previousLifeDayEnd
            : ObservationReferenceType.currentMoment,
        initialObservation: initialObservation,
      ),
    );
  }

  @override
  ConsumerState<ActualStateSheet> createState() => _ActualStateSheetState();
}

class _ActualStateSheetState extends ConsumerState<ActualStateSheet> {
  DailyObservationResult? _revealed;
  AbsoluteEnergyState? _selectedState;
  ObservationCoverageState? _coverageState;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialObservation;
    if (initial?.type == EnergyObservationType.dailyAbsolute &&
        initial?.referenceType == widget.referenceType) {
      _selectedState = initial?.absoluteState;
      final coverage = initial?.coverageState;
      if (coverage == ObservationCoverageState.confirmed ||
          coverage == ObservationCoverageState.uncertain) {
        _coverageState = coverage;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SingleChildScrollView(
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
            child: _revealed == null ? _selection() : _reveal(),
          ),
        ),
      ),
    );
  }

  Widget _selection() {
    return Column(
      key: const Key('actual-state-selection'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.isYesterday ? '昨天结束时的整体状态' : '现在的整体状态',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          widget.isYesterday
              ? '请回想昨天结束时的感受；系统当时的估计会在保存后揭示。'
              : '先按此刻自己的感受选择；系统估计会在保存后揭示。',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        for (final state in AbsoluteEnergyState.values) ...[
          Semantics(
            button: true,
            excludeSemantics: true,
            selected: _selectedState == state,
            label: '${_stateLabel(state)}，实际状态',
            onTap: _saving ? null : () => _selectState(state),
            child: OutlinedButton(
              key: Key('actual-${state.code}'),
              onPressed: _saving ? null : () => _selectState(state),
              style: _stateButtonStyle(state),
              child: Text(_stateLabel(state)),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const Key('actual-state-anchor-expansion'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: const Text('查看五档的行为说明'),
            children: [
              for (final state in AbsoluteEnergyState.values)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_stateLabel(state)),
                  subtitle: Text(_stateAnchor(state)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isYesterday ? '截至昨天结束时，主要活动是否基本记录完整？' : '截至现在，主要活动是否基本记录完整？',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _coverageButton(
          label: '基本记录完整',
          detail: '我认为主要活动没有明显遗漏',
          value: ObservationCoverageState.confirmed,
        ),
        const SizedBox(height: 8),
        _coverageButton(
          label: '不确定',
          detail: '可能有主要活动遗漏，仍可保存',
          value: ObservationCoverageState.uncertain,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('save-actual-state-button'),
          onPressed: _saving || _selectedState == null || _coverageState == null
              ? null
              : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(
            _saving
                ? '正在保存…'
                : widget.initialObservation == null
                ? '保存并查看对照'
                : '更新并查看对照',
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              key: const Key('actual-state-error'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _coverageButton({
    required String label,
    required String detail,
    required ObservationCoverageState value,
  }) {
    final selected = _coverageState == value;
    return Semantics(
      selected: selected,
      button: true,
      child: OutlinedButton(
        key: Key('coverage-${value.code}'),
        onPressed: _saving
            ? null
            : () => setState(() {
                _coverageState = value;
                _error = null;
              }),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : AppColors.line,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reveal() {
    final result = _revealed!;
    return Column(
      key: const Key('actual-state-reveal'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _stateLabel(result.observation.absoluteState!),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: _stateColor(result.observation.absoluteState!),
          ),
        ),
        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 18),
        Text(widget.isYesterday ? '系统在昨天结束时的估计' : '系统在保存时的估计'),
        const SizedBox(height: 6),
        Text(
          '${result.systemEstimate}',
          key: const Key('revealed-system-estimate'),
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 12),
        Text(
          result.differenceDescription,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '实际感受独立保存，不会覆盖估计或自动修改规则。',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text(
          result.observation.coverageState == ObservationCoverageState.confirmed
              ? '活动记录完整性：已确认基本完整'
              : '活动记录完整性：不确定，本条不会作为可学习证据',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('完成'),
        ),
      ],
    );
  }

  void _selectState(AbsoluteEnergyState state) {
    setState(() {
      _selectedState = state;
      _error = null;
    });
  }

  Future<void> _save() async {
    final state = _selectedState;
    final coverageState = _coverageState;
    if (state == null || coverageState == null || _saving) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(wellbeingUseCasesProvider)
          .saveDailyAbsolute(
            observationId: ref
                .read(recordIdGeneratorProvider)
                .next(prefix: 'daily', now: ref.read(clockProvider).now()),
            targetLifeDay: widget.lifeDay,
            referenceType: widget.referenceType,
            state: state,
            coverageState: coverageState,
          );
      ref.invalidate(currentDailyObservationProvider);
      ref.invalidate(canSupplementYesterdayProvider);
      ref.invalidate(historyReviewProvider);
      ref.invalidate(dataHealthReportProvider);
      ref.invalidate(mvpBUpgradeReadinessProvider);
      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() {
          _saving = false;
          _revealed = result;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = switch (error) {
            StateError(message: 'staleSheet') => '日期已经切换，请关闭后重新打开。',
            StateError(message: 'readOnlyObservation') =>
              '昨天结束时的状态已经保存，不能再次修改。',
            StateError(message: 'missingSettledSummary') => '昨天尚未完成结算，暂时不能补充。',
            _ => '保存失败，当前选择已保留，请重试。',
          };
        });
      }
    }
  }

  String _stateLabel(AbsoluteEnergyState state) => switch (state) {
    AbsoluteEnergyState.exhausted => '耗尽',
    AbsoluteEnergyState.low => '偏低',
    AbsoluteEnergyState.okay => '尚可',
    AbsoluteEnergyState.good => '良好',
    AbsoluteEnergyState.full => '充足',
  };

  String _stateAnchor(AbsoluteEnergyState state) => switch (state) {
    AbsoluteEnergyState.exhausted => '维持基本活动都很费力，需要尽快停下来休息。',
    AbsoluteEnergyState.low => '能处理必要事情，但继续投入会明显吃力。',
    AbsoluteEnergyState.okay => '能完成一般任务，同时需要留意间歇。',
    AbsoluteEnergyState.good => '能稳定投入，多数日常任务不太吃力。',
    AbsoluteEnergyState.full => '精神和精力充足，可以从容处理高强度任务。',
  };

  ButtonStyle _stateButtonStyle(AbsoluteEnergyState state) {
    final selected = _selectedState == state;
    final color = _stateColor(state);
    return OutlinedButton.styleFrom(
      foregroundColor: selected ? color : AppColors.textPrimary,
      backgroundColor: selected
          ? color.withValues(alpha: 0.16)
          : AppColors.backgroundOverlay,
      side: BorderSide(color: selected ? color : AppColors.line),
      minimumSize: const Size.fromHeight(48),
    );
  }

  Color _stateColor(AbsoluteEnergyState state) => switch (state) {
    AbsoluteEnergyState.exhausted => AppColors.energyOverdraft,
    AbsoluteEnergyState.low => AppColors.energyLow,
    AbsoluteEnergyState.okay => AppColors.energyMediumLow,
    AbsoluteEnergyState.good => AppColors.energyCalm,
    AbsoluteEnergyState.full => AppColors.energyHigh,
  };
}

class RelativeCorrectionSheet extends ConsumerStatefulWidget {
  const RelativeCorrectionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const RelativeCorrectionSheet(),
    );
  }

  @override
  ConsumerState<RelativeCorrectionSheet> createState() =>
      _RelativeCorrectionSheetState();
}

class _RelativeCorrectionSheetState
    extends ConsumerState<RelativeCorrectionSheet> {
  var _saving = false;
  RelativeCorrection? _selectedCorrection;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '此刻感觉与估计相比',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '会保存此刻估计快照，不会直接改变估计。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              _button('比估计低', RelativeCorrection.lowerThanEstimate),
              _button('差不多', RelativeCorrection.aboutRight),
              _button('比估计高', RelativeCorrection.higherThanEstimate),
              if (_saving)
                const Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    key: const Key('relative-correction-error'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _button(String label, RelativeCorrection correction) {
    final selected = _selectedCorrection == correction;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: selected,
        button: true,
        child: FilledButton.tonalIcon(
          key: Key('relative-${correction.code}'),
          onPressed: _saving ? null : () => _save(correction),
          style: selected
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                )
              : null,
          icon: Icon(selected ? Icons.check_rounded : Icons.circle_outlined),
          label: Text(label),
        ),
      ),
    );
  }

  Future<void> _save(RelativeCorrection correction) async {
    setState(() {
      _selectedCorrection = correction;
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(wellbeingUseCasesProvider)
          .saveRelativeCorrection(
            observationId: ref
                .read(recordIdGeneratorProvider)
                .next(prefix: 'relative', now: ref.read(clockProvider).now()),
            correction: correction,
          );
      ref.invalidate(historyReviewProvider);
      ref.invalidate(dataHealthReportProvider);
      ref.invalidate(mvpBUpgradeReadinessProvider);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: Text('已记录：${_correctionLabel(correction)}；MVP-A 规则保持不变。'),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存失败，请重试。';
        });
      }
    }
  }

  String _correctionLabel(RelativeCorrection correction) =>
      switch (correction) {
        RelativeCorrection.lowerThanEstimate => '比估计低',
        RelativeCorrection.aboutRight => '差不多',
        RelativeCorrection.higherThanEstimate => '比估计高',
      };
}
