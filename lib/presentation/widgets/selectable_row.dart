import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'app_focusable.dart';

/// One option of a single-choice list, such as a subtitle track or a
/// quality level, with a radio dot in front of its title.
class SelectableRow extends StatelessWidget {
  const SelectableRow({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.autofocus = false,
  });

  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool autofocus;

  static const double _minHeight = 56;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;

    // The vertical padding sits outside the focusable area so the focus ring
    // stays inside the row and a scrolling list does not clip it.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: AppFocusable(
        onPressed: onTap,
        checked: isSelected,
        autofocus: autofocus,
        borderRadius: AppRadius.smAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                _RadioDot(selected: isSelected),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.xxxs,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primaryYellow
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  static const double _size = 20;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryYellow : AppColors.textTertiary;
    return AnimatedScale(
      scale: selected ? 1 : 0.8,
      duration: AppMotion.of(context, AppDurations.medium),
      curve: Curves.elasticOut,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? color : null,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}
