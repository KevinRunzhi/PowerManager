import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/app/app_routes.dart';
import 'package:power_manager/app/theme/app_spacing.dart';
import 'package:power_manager/application/json_backup_codec.dart';
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
  bool _savingLocalBackup = false;
  bool _exporting = false;
  bool _restoring = false;
  bool _writingRestore = false;
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
    final localBackup = ref.watch(localBackupMetadataProvider).value;
    final dataBusy = _saving || _savingLocalBackup || _exporting || _restoring;
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
          onPressed: dataBusy ? null : _saveBase,
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
          key: const Key('save-local-backup-button'),
          onPressed: dataBusy ? null : _saveLocalBackup,
          icon: const Icon(Icons.save_outlined),
          label: Text(_savingLocalBackup ? '正在保存…' : '保存本机备份'),
        ),
        if (localBackup != null) ...[
          const SizedBox(height: AppSpacing.x2),
          Text(
            '最近保存：${_formatLocalTime(localBackup.modifiedAt)}'
            ' · ${_formatFileSize(localBackup.byteLength)}',
            key: const Key('local-backup-metadata-label'),
          ),
          TextButton.icon(
            key: const Key('share-local-backup-button'),
            onPressed: dataBusy
                ? null
                : () => _shareLocalBackup(localBackup.path),
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('分享最近本机备份'),
          ),
        ],
        const SizedBox(height: AppSpacing.x3),
        OutlinedButton.icon(
          key: const Key('export-json-button'),
          onPressed: dataBusy ? null : _export,
          icon: const Icon(Icons.ios_share_rounded),
          label: Text(_exporting ? '正在准备…' : '分享 JSON'),
        ),
        const Text('导出包含七类 MVP-A 数据、规则版本和逻辑删除记录。'),
        const SizedBox(height: AppSpacing.x3),
        OutlinedButton.icon(
          key: const Key('data-health-button'),
          onPressed: dataBusy
              ? null
              : () => Navigator.of(context).pushNamed(AppRoutes.dataHealth),
          icon: const Icon(Icons.health_and_safety_outlined),
          label: const Text('数据体检'),
        ),
        const Text('只检查聚合数据、实际状态覆盖和备份状态，不展示活动明细。'),
        const SizedBox(height: AppSpacing.x3),
        OutlinedButton.icon(
          key: const Key('restore-json-button'),
          onPressed: dataBusy ? null : _restore,
          icon: const Icon(Icons.restore_rounded),
          label: Text(
            _restoring ? (_writingRestore ? '正在恢复…' : '正在检查…') : '从 JSON 备份恢复',
          ),
        ),
        const Text('恢复前会完整检查，并自动保存当前数据的安全副本。'),
        if (ref.watch(backupSafetyPathProvider).value case final path?) ...[
          const SizedBox(height: AppSpacing.x3),
          TextButton.icon(
            key: const Key('share-safety-backup-button'),
            onPressed: dataBusy ? null : () => _shareSafetyBackup(path),
            icon: const Icon(Icons.shield_outlined),
            label: const Text('分享上次恢复前备份'),
          ),
        ],
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
    final fileStore = ref.read(temporaryExportFileStoreProvider);
    File? temporaryFile;
    setState(() => _exporting = true);
    try {
      final result = await ref
          .read(jsonExportServiceProvider)
          .create(exportedAt: ref.read(clockProvider).now());
      temporaryFile = await fileStore.write(result);
      await SharePlus.instance.share(
        ShareParams(
          title: 'PowerManager 数据备份',
          text: 'PowerManager MVP-A JSON 数据备份',
          files: [XFile(temporaryFile.path, mimeType: 'application/json')],
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
      if (temporaryFile != null) {
        try {
          await fileStore.delete(temporaryFile);
        } catch (error, stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'PowerManager temporary export cleanup',
            ),
          );
        }
      }
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _saveLocalBackup() async {
    setState(() => _savingLocalBackup = true);
    try {
      await ref.read(localBackupServiceProvider).saveLatest();
      ref.invalidate(localBackupMetadataProvider);
      ref.invalidate(dataHealthReportProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('本机备份已保存并通过检查。')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('本机备份保存失败，旧备份未改变。')));
      }
    } finally {
      if (mounted) {
        setState(() => _savingLocalBackup = false);
      }
    }
  }

  Future<void> _restore() async {
    setState(() {
      _restoring = true;
      _writingRestore = false;
    });
    try {
      const jsonType = XTypeGroup(
        label: 'PowerManager JSON',
        extensions: ['json'],
        mimeTypes: ['application/json'],
      );
      final file = await openFile(acceptedTypeGroups: const [jsonType]);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final service = ref.read(jsonBackupRestoreServiceProvider);
      final inspection = service.inspect(fileName: file.name, bytes: bytes);
      final currentCounts = await service.currentCounts();
      if (!mounted) return;
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) => BackupPreviewSheet(
          inspection: inspection,
          currentCounts: currentCounts,
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _writingRestore = true);
      await service.restore(inspection);
      _invalidateAfterRestore();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('恢复成功，已保存恢复前安全副本。')));
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    } on BackupFormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('恢复失败，当前数据未改变。')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _restoring = false;
          _writingRestore = false;
        });
      }
    }
  }

  void _invalidateAfterRestore() {
    ref.invalidate(appSettingsProvider);
    ref.invalidate(currentPreparationProvider);
    ref.invalidate(morningCompletionStatusProvider);
    ref.invalidate(currentMorningCheckInProvider);
    ref.invalidate(currentDailyObservationProvider);
    ref.invalidate(canSupplementYesterdayProvider);
    ref.invalidate(historyReviewProvider);
    ref.invalidate(backupSafetyPathProvider);
    ref.invalidate(localBackupMetadataProvider);
    ref.invalidate(dataHealthReportProvider);
  }

  Future<void> _shareLocalBackup(String path) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'PowerManager 本机备份',
          text: 'PowerManager 最近一次本机 JSON 备份',
          files: [XFile(path, mimeType: 'application/json')],
          fileNameOverrides: const ['powermanager-latest-backup.json'],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('分享失败，请重试。')));
      }
    }
  }

  Future<void> _shareSafetyBackup(String path) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'PowerManager 恢复前安全备份',
          text: 'PowerManager 上次恢复前的 JSON 数据备份',
          files: [XFile(path, mimeType: 'application/json')],
          fileNameOverrides: const ['powermanager-before-last-restore.json'],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('分享失败，请重试。')));
      }
    }
  }
}

String _formatLocalTime(DateTime value) {
  final local = value.toLocal();
  String two(int part) => part.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  return '${(bytes / 1024).toStringAsFixed(1)} KiB';
}

class BackupPreviewSheet extends StatelessWidget {
  const BackupPreviewSheet({
    super.key,
    required this.inspection,
    required this.currentCounts,
  });

  final BackupInspection inspection;
  final BackupDataCounts currentCounts;

  @override
  Widget build(BuildContext context) {
    final backup = inspection.backup;
    final range = inspection.earliestLifeDay == null
        ? '无生活日数据'
        : inspection.earliestLifeDay == inspection.latestLifeDay
        ? '${inspection.earliestLifeDay}'
        : '${inspection.earliestLifeDay} ～ ${inspection.latestLifeDay}';
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.x4,
          AppSpacing.page,
          AppSpacing.page + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          key: const Key('backup-preview-sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('备份检查通过', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.x3),
            _PreviewLine(label: '文件', value: inspection.fileName),
            _PreviewLine(label: '来源版本', value: backup.appVersion),
            _PreviewLine(
              label: '导出时间',
              value: backup.exportedAt.toLocal().toString(),
            ),
            _PreviewLine(label: '生活日范围', value: range),
            const Divider(height: AppSpacing.x6),
            const _PreviewLine(label: '应用设置', value: '1 → 1'),
            _PreviewLine(
              label: '规则版本',
              value:
                  '${currentCounts.ruleVersions} → ${inspection.counts.ruleVersions}',
            ),
            _PreviewLine(
              label: '晨间确认',
              value:
                  '${currentCounts.morningCheckIns} → ${inspection.counts.morningCheckIns}',
            ),
            _PreviewLine(
              label: '活动记录',
              value:
                  '${currentCounts.activityRecords} → ${inspection.counts.activityRecords}',
            ),
            _PreviewLine(
              label: '实际状态',
              value:
                  '${currentCounts.energyObservations} → ${inspection.counts.energyObservations}',
            ),
            _PreviewLine(
              label: '日总结',
              value:
                  '${currentCounts.dailySummaries} → ${inspection.counts.dailySummaries}',
            ),
            _PreviewLine(
              label: '提醒回执',
              value:
                  '${currentCounts.promptReceipts} → ${inspection.counts.promptReceipts}',
            ),
            const SizedBox(height: AppSpacing.x4),
            const Text('恢复会完整替换当前数据。开始前将自动保存当前数据的安全副本。'),
            const SizedBox(height: AppSpacing.x4),
            FilledButton(
              key: const Key('continue-restore-button'),
              onPressed: () => _confirm(context),
              child: const Text('继续恢复'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('backup-restore-confirmation'),
        title: const Text('确认替换当前数据？'),
        content: const Text('备份通过检查。恢复会替换当前全部记录，过程中请不要关闭应用。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('暂不恢复'),
          ),
          FilledButton(
            key: const Key('confirm-restore-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('保存副本并恢复'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.unit),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
