import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// The one focus indicator of the design system: a [haloColor] band wrapped
/// in a [ringColor] ring, drawn outside the focused control.
///
/// Yellow and black differ by 13:1, so at least one of them keeps 3:1
/// against any backdrop, including a white video frame or a yellow button.
abstract final class AppFocus {
  static const Color ringColor = AppColors.primaryYellow;
  static const Color haloColor = AppColors.black;
  static const double haloWidth = 2;
  static const double ringWidth = 2.5;

  /// How far the indicator reaches past the control. A clipping parent needs
  /// at least this much padding around focusable children.
  static const double ringExtent = haloWidth + ringWidth;

  static const double liftScale = 1.04;
  static const double pressScale = 0.95;
}
