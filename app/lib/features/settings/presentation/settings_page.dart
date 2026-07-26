import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:power_manager/app/theme/app_spacing.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/domain/entities/persisted_entities.dart';
import 'package:power_manager/features/settings/presentation/onboarding_dialog.dart';
import 'package:share_plus/share_plus.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const pageKey = Key('settings-page');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return Scaffold(
      key: pageKey,
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: settings.when(
          data: (value) => _SettingsContent(settings: value),
          error: (_, _) => Center(
            child: OutlinedButton(
              onPressed: () => ref.invalidate(appSettingsProvider),
              child: const Text('读取失败，重试'),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _SettingsContent extends ConsumerStatefulWidget {
  const _SettingsContent({required this.settings});

  final AppSettings settings;

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  late final TextEditingController _controller;
  bool _saving = false;
  bool _exporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text:
          '${widget.settings.pendingBaseEstimatedEnergy ?? widget.settings.baseEstimatedEnergy}',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        Text('个人基准线', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.x3),
        Text('当前：${settings.baseEstimatedEnergy}'),
        if (settings.pendingBaseEstimatedEnergy case final pending?)
          Text(
            '待生效：$pending · ${settings.baseEnergyEffectiveLifeDay}',
            key: const Key('pending-base-label'),
          ),
        const SizedBox(height: AppSpacing.x3),
        TextField(
          key: const Key('base-estimate-field'),
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '新基准线（60～140）',
            errorText: _error,
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
        FilledButton(
          key: const Key('save-base-estimate-button'),
          onPressed: _saving ? null : _saveBase,
          child: Text(_saving ? '保存中…' : '下一生活日起生效'),
        ),
        const SizedBox(height: AppSpacing.x6),
        Text('规则版本', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.x2),
        Text(settings.activeRuleVersion),
        const Text('MVP-A 使用内置只读规则，不提供规则编辑或迁移入口。'),
        const SizedBox(height: AppSpacing.x6),
        Text('数据', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.x2),
        FilledButton.tonalIcon(
          key: const Key('export-json-button'),
          onPressed: _exporting ? null : _export,
          icon: const Icon(Icons.ios_share_rounded),
          label: Text(_exporting ? '正在准备…' : '导出并分享 JSON'),
        ),
        const Text('导出包含七类 MVP-A 数据、规则版本和逻辑删除记录。'),
        const SizedBox(height: AppSpacing.x6),
        OutlinedButton(
          key: const Key('review-onboarding-button'),
          onPressed: () => showOnboardingDialog(context),
          child: const Text('重新查看首次说明'),
        ),
      ],
    );
  }

  Future<void> _saveBase() async {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 60 || value > 140) {
      setState(() => _error = '请输入 60～140 的整数');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(settingsServiceProvider).scheduleBaseEstimate(value);
      ref.invalidate(appSettingsProvider);
      ref.invalidate(currentPreparationProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已保存，将从下一生活日起生效。')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '保存失败，请重试');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final result = await ref
          .read(jsonExportServiceProvider)
          .create(exportedAt: DateTime.now());
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${result.fileName}');
      await file.writeAsString(result.contents, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          title: 'PowerManager 数据备份',
          text: 'PowerManager MVP-A JSON 数据备份',
          files: [XFile(file.path, mimeType: 'application/json')],
          fileNameOverrides: [result.fileName],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('导出失败，请重试。')));
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }
}
