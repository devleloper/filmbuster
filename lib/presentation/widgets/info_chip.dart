import 'package:flutter/widgets.dart';

import '../../core/utils/responsive.dart';
import '../theme/app_theme.dart';

/// A small rounded label, such as a genre or a department.
class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.scaled(10),
        vertical: r.scaled(AppSpacing.xs),
      ),
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(r.scaled(AppRadius.md)),
      ),
      child: Text(
        label,
        style: r.scaleText(
          AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
