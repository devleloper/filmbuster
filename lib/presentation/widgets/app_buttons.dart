import 'package:flutter/material.dart' show kMinInteractiveDimension;
import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'app_focusable.dart';

/// Filled yellow call-to-action button.
class PrimaryButton extends _AppButton {
  const PrimaryButton({
    super.key,
    required super.child,
    super.onPressed,
    super.semanticLabel,
    super.borderRadius,
    super.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xxl,
      vertical: AppSpacing.md,
    ),
  });

  @override
  BoxDecoration get _decoration =>
      BoxDecoration(color: AppColors.primaryYellow, borderRadius: borderRadius);

  @override
  TextStyle get _textStyle =>
      AppTextStyles.labelMedium.copyWith(color: AppColors.black);
}

/// Outlined button for the secondary action next to a [PrimaryButton].
class SecondaryButton extends _AppButton {
  const SecondaryButton({
    super.key,
    required super.child,
    super.onPressed,
    super.semanticLabel,
  }) : super(
         padding: const EdgeInsets.symmetric(
           horizontal: AppSpacing.xl,
           vertical: AppSpacing.md,
         ),
       );

  @override
  BoxDecoration get _decoration => BoxDecoration(
    border: Border.all(color: AppColors.accentBorder, width: 1.5),
    borderRadius: borderRadius,
  );

  @override
  TextStyle get _textStyle =>
      AppTextStyles.labelMedium.copyWith(color: AppColors.primaryYellow);
}

abstract class _AppButton extends StatelessWidget {
  const _AppButton({
    super.key,
    required this.child,
    required this.padding,
    this.onPressed,
    this.semanticLabel,
    this.borderRadius = AppRadius.lgAll,
  });

  final Widget child;
  final VoidCallback? onPressed;

  /// Replaces the text of [child] for screen readers when it needs context.
  final String? semanticLabel;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  BoxDecoration get _decoration;

  TextStyle get _textStyle;

  @override
  Widget build(BuildContext context) {
    return AppFocusable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      borderRadius: borderRadius,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: kMinInteractiveDimension,
            minHeight: kMinInteractiveDimension,
          ),
          padding: padding,
          decoration: _decoration,
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: DefaultTextStyle(style: _textStyle, child: child),
          ),
        ),
      ),
    );
  }
}
