import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';

/// Yellow outlined pill that marks demo content.
class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key, required this.label, this.semanticLabel});

  final String label;

  /// Screen-reader text when it should say more than [label].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          color: AppColors.glassSurfaceStrong,
          shape: StadiumBorder(
            side: BorderSide(color: AppColors.primaryYellow),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          // Ellipsis is the last resort; the semantics label stays whole.
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.captionStrong.copyWith(
              color: AppColors.primaryYellow,
            ),
          ),
        ),
      ),
    );
  }
}
