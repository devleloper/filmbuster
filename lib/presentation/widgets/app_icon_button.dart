import 'package:flutter/material.dart' show kMinInteractiveDimension;
import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'app_focusable.dart';

/// Round icon-only button; [semanticLabel] names it for screen readers.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.size = kMinInteractiveDimension,
    this.iconSize = 24,
    this.backgroundColor,
    this.focusNode,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final double size;
  final double iconSize;

  /// Fill behind the icon, for buttons that float over video or artwork.
  final Color? backgroundColor;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return AppFocusable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      borderRadius: BorderRadius.all(Radius.circular(size / 2)),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: backgroundColor == null
            ? null
            : BoxDecoration(shape: BoxShape.circle, color: backgroundColor),
        child: Icon(
          icon,
          size: iconSize,
          color: onPressed == null ? AppColors.textDisabled : AppColors.white,
        ),
      ),
    );
  }
}
