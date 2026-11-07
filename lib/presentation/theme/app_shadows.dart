import 'package:flutter/painting.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  /// Lifts controls and indicators that float over video off the frame.
  static const List<BoxShadow> overVideo = [
    BoxShadow(
      color: AppColors.scrimFaint,
      blurRadius: 12,
      spreadRadius: 1,
      offset: Offset(0, 4),
    ),
  ];

  /// Separates floating messages from the content under them.
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: AppColors.scrimFaint,
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}
