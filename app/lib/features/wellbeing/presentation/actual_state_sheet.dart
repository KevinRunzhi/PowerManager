import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/app/theme/app_colors.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/application/wellbeing_use_cases.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/life_day/life_day.dart';

class ActualStateSheet extends ConsumerStatefulWidget {
  const ActualStateSheet({
    super.key,
    required this.lifeDay,
    required this.isYesterday,
  });

  final LifeDay lifeDay;
  final bool isYesterday;

  static Future<void> show(
    BuildContext context, {
    required LifeDay lifeDay,
    bool isYesterday = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          ActualStateSheet(lifeDay: lifeDay, isYesterday: isYesterday),
    );
  }

  @override
  ConsumerState<ActualStateSheet> createState() => _ActualStateSheetState();
}

class _ActualStateSheetState extends ConsumerState<ActualStateSheet> {
  DailyObservationResult? _revealed;
  AbsoluteEnergyState? _selectedState;
  var _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SingleChildScrollView(
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          child: _revealed == null ? _selection() : _reveal(),
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
          widget.isYesterday ? '补充昨日实际状态' : '今天的实际状态',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '先按自己的感受选择；系统估计会在保存后揭示。',
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
            onTap: _saving ? null : () => _save(state),
            child: OutlinedButton(
              key: Key('actual-${state.code}'),
              onPressed: _saving ? null : () => _save(state),
              style: _stateButtonStyle(state),
              child: Text(_stateLabel(state)),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_saving)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
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
        const Text('系统当时的估计'),
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
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('完成'),
        ),
      ],
    );
  }

  Future<void> _save(AbsoluteEnergyState state) async {
    setState(() {
      _selectedState = state;
      _saving = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(wellbeingUseCasesProvider)
          .saveDailyAbsolute(
            observationId:
                'daily-${DateTime.now().toUtc().microsecondsSinceEpoch}',
            targetLifeDay: widget.lifeDay,
            state: state,
          );
      ref.invalidate(currentDailyObservationProvider);
      ref.invalidate(canSupplementYesterdayProvider);
      ref.invalidate(historyReviewProvider);
      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() {
          _saving = false;
          _revealed = result;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = widget.isYesterday ? '昨日状态已保存或暂不可补充。' : '保存失败，请重试。';
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
        ],
      ),
    );
  }

  Widget _button(String label, RelativeCorrection correction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.tonal(
        onPressed: _saving ? null : () => _save(correction),
        child: Text(label),
      ),
    );
  }

  Future<void> _save(RelativeCorrection correction) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(wellbeingUseCasesProvider)
          .saveRelativeCorrection(
            observationId:
                'relative-${DateTime.now().toUtc().microsecondsSinceEpoch}',
            correction: correction,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存感受与当时估计；MVP-A 规则保持不变。')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }
}
