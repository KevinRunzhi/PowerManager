import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:power_manager/app/theme/app_spacing.dart';

class DebugEnvironmentPage extends StatelessWidget {
  const DebugEnvironmentPage({super.key});

  static const pageKey = Key('debug-environment-page');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: pageKey,
      appBar: AppBar(title: const Text('开发环境')),
      body: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.page),
        child: ListView(
          children: const [
            _InfoRow(label: '阶段', value: 'MVP-A / Stage 1'),
            _InfoRow(label: '平台', value: 'Android'),
            _InfoRow(label: '构建模式', value: kDebugMode ? 'debug' : 'release'),
            _InfoRow(label: '数据库', value: 'Drift schema 待阶段 3 建立'),
            _InfoRow(label: '业务状态', value: '工程骨架，不含业务逻辑'),
          ],
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
            width: 88,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
