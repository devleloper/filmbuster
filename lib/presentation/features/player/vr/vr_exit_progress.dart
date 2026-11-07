import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/feedback/app_loading_indicator.dart';

/// Fills a ring as the viewer holds a finger down to leave VR.
class VrExitProgress extends AnimatedWidget {
  const VrExitProgress(Animation<double> progress, {super.key})
    : super(listenable: progress);

  @override
  Widget build(BuildContext context) {
    final progress = (listenable as Animation<double>).value;
    return Opacity(
      opacity: progress,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          color: AppColors.scrimMedium,
          borderRadius: AppRadius.xlAll,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.borderStrong),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AppProgressRing(value: progress),
                const Icon(Icons.close, color: AppColors.white, size: 24),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Holding to Exit...',
              style: AppTextStyles.captionStrong,
            ),
          ],
        ),
      ),
    );
  }
}
