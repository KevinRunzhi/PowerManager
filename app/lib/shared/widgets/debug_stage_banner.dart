import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:power_manager/app/theme/app_colors.dart';

class DebugStageBanner extends StatelessWidget {
  const DebugStageBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return const IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          minimum: EdgeInsets.only(bottom: 4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.backgroundOverlay,
              borderRadius: BorderRadius.all(Radius.circular(999)),
              border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                'MVP-A · Stage 14 · 备份恢复闭环',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
