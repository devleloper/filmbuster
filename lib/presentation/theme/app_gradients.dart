import 'package:flutter/painting.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  static const LinearGradient screenBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.background, AppColors.backgroundDeep],
  );

  static const LinearGradient topScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.scrimMedium, AppColors.transparent],
  );

  static const LinearGradient bottomScrim = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [AppColors.scrimStrong, AppColors.transparent],
  );

  static const BoxDecoration screenBackgroundDecoration = BoxDecoration(
    gradient: screenBackground,
  );
}
