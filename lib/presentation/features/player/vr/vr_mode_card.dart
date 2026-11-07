import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_focusable.dart';

/// A selectable VR environment: a preview above its icon and title.
class VrModeCard extends StatelessWidget {
  const VrModeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.preview,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected ? AppColors.primaryYellow : AppColors.white;

    return AppFocusable(
      onPressed: onTap,
      checked: isSelected,
      semanticLabel: title,
      borderRadius: AppRadius.mdAll,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppDurations.fast),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selection : AppColors.glassSurface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: isSelected ? AppColors.accentBorder : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(borderRadius: AppRadius.smAll, child: preview),
            ),
            AppSpacing.vGapSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  title,
                  style: AppTextStyles.captionStrong.copyWith(color: accent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
