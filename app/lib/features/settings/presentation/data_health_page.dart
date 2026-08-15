import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:power_manager/app/theme/app_colors.dart';
import 'package:power_manager/app/theme/app_spacing.dart';
import 'package:power_manager/application/data_health_service.dart';
import 'package:power_manager/application/mvp_b_upgrade_readiness_service.dart';
import 'package:power_manager/application/providers.dart';
import 'package:power_manager/domain/energy/energy_enums.dart';
import 'package:power_manager/domain/energy/learning_eligibility_service.dart';
import 'package:power_manager/domain/learning/shadow_learning.dart';
import 'package:share_plus/share_plus.dart';

class DataHealthPage extends ConsumerWidget {
  const DataHealthPage({super.key});

  static const pageKey = Key('data-health-page');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(dataHealthReportProvider);
    return Scaffold(
      key: pageKey,
      appBar: AppBar(
        title: const Text('数据体检'),
        actions: [
          IconButton(
            key: const Key('refresh-data-health-button'),
            tooltip: '重新检查',
            onPressed: report.isLoading
                ? null
                : () => ref.invalidate(dataHealthReportProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: report.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _HealthError(
            onRetry: () => ref.invalidate(dataHealthReportProvider),
          ),
          data: (value) => _HealthContent(report: value),
        ),
      ),
    );
  }
}

class _HealthContent extends StatelessWidget {
  const _HealthContent({required this.report});

  final DataHealthReport report;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        _HealthCard(
          key: const Key('integrity-health-card'),
          icon: report.integrityPassed
              ? Icons.verified_outlined
              : Icons.info_outline_rounded,
          title: report.integrityPassed ? '完整性检查通过' : '需要保留当前数据',
          accent: report.integrityPassed
              ? AppColors.energyHigh
              : AppColors.energyMediumLow,
          children: [
            Text(
              report.integrityPassed
                  ? 'schema v${report.schemaVersion} 完整重放通过 · 0 项异常'
                  : '发现至少 1 项一致性问题，请先导出备份并保留当前数据。',
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              '检查时间：${_dateTime(report.checkedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        _HealthCard(
          key: const Key('mvp-b-learning-evidence-card'),
          icon: Icons.science_outlined,
          title: '自动学习进度（只读影子）',
          children: [
            const Text(
              '只读影子引擎已开启：它会自动核对证据是否就绪，但不会生成候选值或改变你的基准线。',
              key: Key('automatic-learning-mode-label'),
            ),
            const SizedBox(height: AppSpacing.x2),
            _MetricLine(
              label: '历史运行',
              value:
                  '${report.learningRuns}（待重试 ${report.retryableLearningRuns} / 已停止 ${report.terminalLearningRuns}）',
            ),
            _MetricLine(
              label: '现在的整体状态',
              value: '${report.currentMomentContractObservations}',
            ),
            _MetricLine(
              label: '昨天结束时',
              value: '${report.previousLifeDayEndContractObservations}',
            ),
            _MetricLine(
              label: '当前模型口径可用',
              value: '${report.eligibleCurrentRegimeObservations}',
            ),
            _MetricLine(
              label: '可用日期跨度',
              value: report.earliestEligibleLifeDay == null
                  ? '暂无'
                  : '${report.earliestEligibleLifeDay} 至 '
                        '${report.latestEligibleLifeDay}',
            ),
            _MetricLine(
              label: '尚未结算',
              value: '${report.unsettledContractObservations}',
            ),
            const Divider(height: AppSpacing.x6),
            if (report.automaticLearningProgress.isEmpty)
              const Text(
                '当前口径还没有可展示的影子证据。完成晨间确认、实际状态并等待生活日结算后会自动更新。',
                key: Key('automatic-learning-empty-label'),
              )
            else
              for (final progress in report.automaticLearningProgress) ...[
                _AutomaticLearningProgressView(progress: progress),
                if (progress != report.automaticLearningProgress.last)
                  const Divider(height: AppSpacing.x6),
              ],
            if (report.learningExclusionCounts.isNotEmpty) ...[
              const Divider(height: AppSpacing.x6),
              Text('排除原因', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.x2),
              for (final reason in LearningIneligibilityReason.values)
                if (report.exclusionCount(reason) > 0)
                  _MetricLine(
                    label: _learningReasonLabel(reason),
                    value: '${report.exclusionCount(reason)}',
                  ),
            ],
            const Divider(height: AppSpacing.x6),
            const Text('证据达到审计门只表示输入足够；不代表系统会改变参数。'),
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        _HealthCard(
          key: const Key('mvp-b-upgrade-readiness-health-card'),
          icon: report.mvpBUpgradeReadiness.isReady
              ? Icons.verified_user_outlined
              : Icons.backup_outlined,
          title: 'MVP-B 升级准备',
          accent: report.mvpBUpgradeReadiness.isReady
              ? AppColors.energyHigh
              : AppColors.energyMediumLow,
          children: [
            Text(
              report.mvpBUpgradeReadiness.isReady
                  ? '已准备：本机备份完整且与当前 schema v${report.schemaVersion} 数据一致。'
                  : '未准备：${_readinessStatusText(report.mvpBUpgradeReadiness.status)}',
              key: const Key('mvp-b-upgrade-readiness-health-label'),
            ),
            if (report.mvpBUpgradeReadiness.verifiedAt case final verifiedAt?)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.x2),
                child: Text(
                  '最近验证：${_dateTime(verifiedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        _HealthCard(
          key: const Key('validation-progress-card'),
          icon: Icons.track_changes_outlined,
          title: '验证进度',
          children: [
            _MetricLine(label: '已结算生活日', value: '${report.settledDays}'),
            _MetricLine(
              label: '有效生活日',
              value:
                  '${report.effectiveDays}（标准 ${report.standardEffectiveDays} / 弱 ${report.weakEffectiveDays}）',
            ),
            _MetricLine(
              label: '带实际状态的有效日',
              value:
                  '${report.effectiveDaysWithActualState} / ${report.effectiveDays}',
            ),
            _MetricLine(label: '实际状态覆盖率', value: '${report.coveragePercent}%'),
            const Divider(height: AppSpacing.x6),
            Text(
              report.reachedLegacyDiscussionCount
                  ? '旧版自用样本数量达到 14 日；它不等于 MVP-B 可学习证据。'
                  : '旧版自用讨论计数还差 '
                        '${report.daysUntilLegacyDiscussionCount} '
                        '个带实际状态的有效日；它不等于 MVP-B 可学习证据。',
              key: const Key('mvp-b-progress-label'),
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              'MVP-B 从 B0-3 开始采集同一参考时刻的新配对；当前只做证据就绪判断。',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        _HealthCard(
          key: const Key('data-overview-card'),
          icon: Icons.dataset_outlined,
          title: '数据概览',
          children: [
            _MetricLine(label: '晨间确认', value: '${report.morningCheckIns}'),
            _MetricLine(
              label: '活动记录',
              value:
                  '${report.activityRecords}（逻辑删除 ${report.deletedActivityRecords}）',
            ),
            _MetricLine(label: '每日实际状态', value: '${report.dailyActualStates}'),
            _MetricLine(label: '随时校正', value: '${report.relativeCorrections}'),
            _MetricLine(
              label: 'Legacy 观测',
              value: '${report.legacyObservations}',
            ),
            _MetricLine(
              label: '新合同观测',
              value: '${report.contractObservations}',
            ),
            _MetricLine(
              label: '活动反馈',
              value:
                  '${report.activityFeedback}（active ${report.activeActivityFeedback} / 失效 ${report.invalidatedActivityFeedback}）',
            ),
            _MetricLine(label: '影子学习运行', value: '${report.learningRuns}'),
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        _HealthCard(
          key: const Key('local-backup-health-card'),
          icon: Icons.save_outlined,
          title: '本机备份',
          children: [
            if (report.localBackup case final backup?) ...[
              _MetricLine(label: '最近保存', value: _dateTime(backup.modifiedAt)),
              _MetricLine(label: '文件大小', value: _fileSize(backup.byteLength)),
              const SizedBox(height: AppSpacing.x2),
              OutlinedButton.icon(
                key: const Key('health-share-local-backup-button'),
                onPressed: () => _shareBackup(context, backup.path),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('分享最近本机备份'),
              ),
            ] else
              const Text('尚未保存本机备份。可返回设置页手动保存。'),
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        Text(
          '体检结果只用于自用验证，不代表医学判断。只读影子运行不会调整任何参数。',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Future<void> _shareBackup(BuildContext context, String path) async {
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
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('分享失败，请重试。')));
      }
    }
  }
}

class _AutomaticLearningProgressView extends StatelessWidget {
  const _AutomaticLearningProgressView({required this.progress});

  final AutomaticLearningProgress progress;

  @override
  Widget build(BuildContext context) {
    final firstWindow = progress.windowDirectionCounts.firstOrNull;
    final secondWindow = progress.windowDirectionCounts.length < 2
        ? null
        : progress.windowDirectionCounts[1];
    return Column(
      key: Key('automatic-learning-${progress.referenceType.code}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _referenceLabel(progress.referenceType),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.x2),
        _MetricLine(label: '可用证据', value: '${progress.eligibleTotal} / 14'),
        _MetricLine(
          label: '日期跨度',
          value: '${progress.spanCalendarDays} / 21 天',
        ),
        _MetricLine(
          label: '双窗口',
          value:
              '${progress.firstWindowSize} / 7 · ${progress.secondWindowSize} / 7',
        ),
        _MetricLine(
          label: '低于 / 相符 / 高于',
          value:
              '${progress.directionCounts.lower} / '
              '${progress.directionCounts.aligned} / '
              '${progress.directionCounts.higher}',
        ),
        if (firstWindow != null)
          _MetricLine(label: '窗口 1', value: _directionCounts(firstWindow)),
        if (secondWindow != null)
          _MetricLine(label: '窗口 2', value: _directionCounts(secondWindow)),
        _MetricLine(
          label: '范围',
          value: progress.earliestLifeDay == null
              ? '暂无'
              : '${progress.earliestLifeDay} 至 ${progress.latestLifeDay}',
        ),
        _MetricLine(label: '本口径排除', value: '${progress.excludedTotal}'),
        _MetricLine(
          label: '证据门',
          value: progress.ready
              ? '已达到审计门'
              : '还差 ${progress.missingToMinimum} 条',
        ),
        _MetricLine(label: '最近运行', value: _latestRunText(progress)),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.accent,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: accent ?? AppColors.energyCalm),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.unit),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(flex: 6, child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _HealthError extends StatelessWidget {
  const _HealthError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('暂时无法完成数据体检，当前数据没有改变。'),
            const SizedBox(height: AppSpacing.x3),
            OutlinedButton(
              key: const Key('retry-data-health-button'),
              onPressed: onRetry,
              child: const Text('重新检查'),
            ),
          ],
        ),
      ),
    );
  }
}

String _dateTime(DateTime value) {
  final local = value.toLocal();
  String two(int part) => part.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

String _fileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  return '${(bytes / 1024).toStringAsFixed(1)} KiB';
}

String _readinessStatusText(MvpBUpgradeReadinessStatus status) {
  return switch (status) {
    MvpBUpgradeReadinessStatus.notChecked => '尚未执行升级备份验证。',
    MvpBUpgradeReadinessStatus.ready => '备份与当前数据一致。',
    MvpBUpgradeReadinessStatus.latestBackupMissing => '没有最近本机备份。',
    MvpBUpgradeReadinessStatus.latestBackupChanged => '最近备份已变化。',
    MvpBUpgradeReadinessStatus.currentDataChanged => '验证后当前数据已变化。',
    MvpBUpgradeReadinessStatus.contentMismatch => '备份与当前数据不一致。',
    MvpBUpgradeReadinessStatus.invalidBackup => '最近备份未通过完整性检查。',
    MvpBUpgradeReadinessStatus.invalidProof => '旧验证记录不可用。',
    MvpBUpgradeReadinessStatus.currentDataInvalid => '当前数据未通过完整性检查。',
    MvpBUpgradeReadinessStatus.currentExportFailed => '暂时无法读取当前数据。',
    MvpBUpgradeReadinessStatus.backupWriteFailed => '备份写入失败。',
    MvpBUpgradeReadinessStatus.backupReadFailed => '备份无法从磁盘回读。',
    MvpBUpgradeReadinessStatus.preparationFailed => '升级准备执行失败。',
    MvpBUpgradeReadinessStatus.checkFailed => '暂时无法完成升级准备检查。',
  };
}

String _learningReasonLabel(LearningIneligibilityReason reason) =>
    switch (reason) {
      LearningIneligibilityReason.legacyContract => '旧合同',
      LearningIneligibilityReason.missingEstimateSnapshot => '缺少估计快照',
      LearningIneligibilityReason.coverageUncertain => '活动覆盖不确定',
      LearningIneligibilityReason.missingMorningCheckIn => '缺少晨间确认',
      LearningIneligibilityReason.invalidInitialEstimate => '初始估计无效',
      LearningIneligibilityReason.unsettledLifeDay => '生活日尚未结算',
      LearningIneligibilityReason.modelRegimeMismatch => '模型口径不一致',
      LearningIneligibilityReason.integrityFailure => '记录完整性异常',
    };

String _referenceLabel(ObservationReferenceType referenceType) =>
    switch (referenceType) {
      ObservationReferenceType.currentMoment => '现在的整体状态',
      ObservationReferenceType.previousLifeDayEnd => '昨天结束时',
    };

String _directionCounts(DirectionCounts counts) =>
    '低 ${counts.lower} · 准 ${counts.aligned} · 高 ${counts.higher}';

String _latestRunText(AutomaticLearningProgress progress) {
  final status = progress.latestRunStatus;
  if (status == null) return '尚无运行';
  final currentSuffix = progress.latestRunMatchesCurrentEvidence
      ? ''
      : ' · 当前证据待运行';
  final time = progress.latestRunAt == null
      ? ''
      : ' · ${_dateTime(progress.latestRunAt!)}';
  final label = switch (status) {
    LearningRunStatus.pending => '等待运行',
    LearningRunStatus.running => '正在运行',
    LearningRunStatus.retryableFailure => '等待安全重试',
    LearningRunStatus.terminalFailure => '已安全停止',
    LearningRunStatus.completed => switch (progress.latestRunResult) {
      LearningRunResult.insufficientEvidence => '证据尚不足',
      LearningRunResult.readyForAudit => '已达到审计门',
      LearningRunResult.configurationBlocked => '配置门已关闭',
      LearningRunResult.unstable => '方向不稳定',
      LearningRunResult.noChange => '无需变化',
      LearningRunResult.candidate => '候选待处理',
      LearningRunResult.improved => '监测改善',
      LearningRunResult.worsened => '监测恶化',
      null => '结果不可用',
    },
  };
  return '$label$time$currentSuffix';
}
