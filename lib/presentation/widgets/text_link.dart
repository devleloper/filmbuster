import 'package:flutter/material.dart' show Icons, kMinInteractiveDimension;
import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'app_focusable.dart';

/// An underlined yellow label with an optional trailing icon and a 48 dp
/// minimum target; a null [onTap] draws it as disabled text.
class TextLink extends StatelessWidget {
  const TextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.icon = Icons.open_in_new_rounded,
    this.style = AppTextStyles.labelMedium,
  });

  final String label;
  final VoidCallback? onTap;

  /// Screen-reader label for a [label] that is ambiguous out of context.
  final String? semanticLabel;
  final String? semanticHint;

  /// `Icons.open_in_new_rounded` for links that leave the app,
  /// `Icons.chevron_right_rounded` for in-app pages, null for none.
  final IconData? icon;

  /// Colour and underline are overridden.
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? AppColors.primaryYellow : AppColors.textDisabled;
    final textStyle = style.copyWith(
      color: color,
      decoration: enabled ? TextDecoration.underline : TextDecoration.none,
      decorationColor: color,
    );

    return AppFocusable(
      onPressed: onTap,
      link: true,
      semanticLabel: semanticLabel ?? label,
      semanticHint: semanticHint,
      borderRadius: AppRadius.smAll,
      pressedScale: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: kMinInteractiveDimension,
          minWidth: kMinInteractiveDimension,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xxs,
            children: [
              Flexible(child: Text(label, style: textStyle)),
              if (icon != null)
                Icon(
                  icon,
                  size: style.fontSize,
                  applyTextScaling: true,
                  color: color,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
