import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/app/theme/app_spacing.dart';
import 'package:power_manager/application/operation_preparation_service.dart';
import 'package:power_manager/application/providers.dart';

class DebugEnvironmentPage extends ConsumerStatefulWidget {
  const DebugEnvironmentPage({super.key});

  static const pageKey = Key('debug-environment-page');

  @override
  ConsumerState<DebugEnvironmentPage> createState() =>
      _DebugEnvironmentPageState();
}

class _DebugEnvironmentPageState extends ConsumerState<DebugEnvironmentPage> {
  late Future<OperationPreparationResult> _preparation;

  @override
  void initState() {
    super.initState();
    _preparation = ref
        .read(operationPreparerProvider)
        .prepare(PreparationTrigger.resumed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: DebugEnvironmentPage.pageKey,
      appBar: AppBar(title: const Text('派生状态调试')),
      body: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.page),
        child: FutureBuilder<OperationPreparationResult>(
          future: _preparation,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SelectableText('准备失败：${snapshot.error}');
            }
            final result = snapshot.data;
            if (result == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final current = result.current;
            final activityOrder = current.projection.activities.isEmpty
                ? '无'
                : current.projection.activities
                      .map((activity) => activity.record.id)
                      .join(' → ');
            return ListView(
              children: [
                const _InfoRow(label: '阶段', value: 'MVP-A / Stage 4'),
                const _InfoRow(label: '平台', value: 'Android'),
                _InfoRow(
                  label: '构建模式',
                  value: kDebugMode ? 'debug' : 'release',
                ),
                _InfoRow(
                  label: '本地时间',
                  value: result.nowLocal.toIso8601String(),
                ),
                _InfoRow(
                  label: 'UTC 时间',
                  value: result.nowUtc.toIso8601String(),
                ),
                _InfoRow(label: '生活日', value: current.lifeDay.toString()),
                _InfoRow(
                  label: '初始估计',
                  value:
                      '${current.projection.initialEstimate} '
                      '(基础 ${current.baseEstimatedEnergy}'
                      ' + 晨间 ${current.morningAdjustment}'
                      ' + 短期 ${current.shortTermAdjustment})',
                ),
                _InfoRow(
                  label: '当前估计',
                  value: current.projection.currentEstimate.toString(),
                ),
                _InfoRow(label: '规则版本', value: current.ruleVersion),
                _InfoRow(label: '记录顺序', value: activityOrder),
                _InfoRow(
                  label: '昨日短期修正',
                  value: current.previousFinalEstimate == null
                      ? '无昨日结算：0'
                      : '昨日结算 ${current.previousFinalEstimate}'
                            ' → ${current.shortTermAdjustment}',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
