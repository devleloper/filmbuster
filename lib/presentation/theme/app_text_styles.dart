import 'package:flutter/widgets.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const String fontFamily = 'Poppins';

  static const TextStyle base = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
  );

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
    fontSize: 16,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textSecondary,
    decoration: TextDecoration.none,
    fontSize: 14,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textMuted,
    decoration: TextDecoration.none,
    fontSize: 14,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textTertiary,
    decoration: TextDecoration.none,
    fontSize: 12,
  );

  static const TextStyle captionStrong = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    decoration: TextDecoration.none,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  /// Height of one line of [style] as [Text] draws it in [context], merged
  /// into the ambient [DefaultTextStyle] and at the user's text scale.
  static double lineHeightOf(BuildContext context, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'Ag',
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }
}
