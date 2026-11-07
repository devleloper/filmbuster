import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';
import 'app_focusable.dart';

/// Tappable card that lifts and shows the focus ring under keyboard or D-pad
/// focus. Screen readers announce it as a button labelled by its text.
class FocusableLiftCard extends StatelessWidget {
  const FocusableLiftCard({
    super.key,
    required this.child,
    required this.onTap,
    this.focusNode,
    this.borderRadius = AppRadius.lgAll,
  });

  final Widget child;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return AppFocusable(
      onPressed: onTap,
      focusNode: focusNode,
      borderRadius: borderRadius,
      pressedScale: 1,
      focusedScale: AppFocus.liftScale,
      child: child,
    );
  }
}
