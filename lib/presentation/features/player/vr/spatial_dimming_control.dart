import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_slider.dart';

/// Sets how dark the camera feed behind the spatial scene is, from 0 up to
/// [maxDimming].
class SpatialDimmingControl extends StatelessWidget {
  const SpatialDimmingControl({
    super.key,
    required this.dimming,
    required this.maxDimming,
    required this.onChanged,
  });

  final double dimming;
  final double maxDimming;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.brightness_6_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
              AppSpacing.hGapSm,
              const Text(
                'Background Dimming',
                style: AppTextStyles.labelMedium,
              ),
              const Spacer(),
              Text(
                '${(dimming * 100).round()}%',
                style: AppTextStyles.captionStrong.copyWith(
                  color: AppColors.primaryYellow,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          AppSlider(
            value: dimming / maxDimming,
            semanticLabel: 'Spatial dimming',
            thumbColor: AppColors.primaryYellow,
            onChanged: (value) => onChanged(value * maxDimming),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bright', style: AppTextStyles.caption),
              Text('Dark', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
