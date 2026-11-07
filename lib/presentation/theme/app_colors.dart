import 'package:flutter/painting.dart';

abstract final class AppColors {
  static const Color primaryYellow = Color(0xFFF7C705);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color background = Color(0xFF0D0D0D);
  static const Color backgroundDeep = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF111111);

  static const Color glassSurface = Color(0x0AFFFFFF);
  static const Color glassSurfaceStrong = Color(0x0FFFFFFF);
  static const Color glassSheet = Color(0xA6000000);

  static const Color border = Color(0x14FFFFFF);
  static const Color borderStrong = Color(0x33FFFFFF);

  /// Outline for secondary buttons: 4.9:1 against [background].
  static const Color accentBorder = Color(0x99F7C705);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textMuted = Color(0x99FFFFFF);
  static const Color textTertiary = Color(0x8AFFFFFF);
  static const Color textDisabled = Color(0x61FFFFFF);

  static const Color scrimFaint = Color(0x40000000);
  static const Color scrimSoft = Color(0x80000000);
  static const Color scrimMedium = Color(0x99000000);
  static const Color scrimStrong = Color(0xCC000000);
  static const Color scrimHeavy = Color(0xE6000000);

  static const Color transparent = Color(0x00000000);

  static const Color selection = Color(0x4DF7C705);

  /// Focus fill for Material infrastructure. Composited over [background] it
  /// reaches 3.7:1 against it (WCAG 1.4.11) and 5.2:1 for white text on top
  /// (WCAG 1.4.3).
  static const Color focusFill = Color(0x80F7C705);

  static const Color error = Color(0xFFFF5252);
}
