import 'package:flutter/material.dart';
import 'package:power_manager/app/theme/app_spacing.dart';

Future<void> showOnboardingDialog(
  BuildContext context, {
  bool dismissible = true,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: dismissible,
    builder: (context) => PopScope(
      canPop: dismissible,
      child: AlertDialog(
        key: const Key('onboarding-dialog'),
        title: const Text('先认识“估计精力”'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('估计与实际分开记录：数字是系统估计，你的实际感受始终单独保存。'),
            SizedBox(height: AppSpacing.x3),
            Text('100 是默认尺度，不是上限，也不是健康分数。'),
            SizedBox(height: AppSpacing.x3),
            Text('当前生活日的活动可以补记、编辑和删除；结算后的历史只读。'),
          ],
        ),
        actions: [
          FilledButton(
            key: const Key('onboarding-confirm-button'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道了'),
          ),
        ],
      ),
    ),
  );
}
