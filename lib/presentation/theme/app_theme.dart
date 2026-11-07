import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

export 'app_colors.dart';
export 'app_durations.dart';
export 'app_focus.dart';
export 'app_gradients.dart';
export 'app_motion.dart';
export 'app_radius.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';

/// Dark theme for the Material infrastructure the app still relies on: text
/// selection, progress indicators and Cupertino controls.
ThemeData buildAppTheme() {
  const baseText = AppTextStyles.base;
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryYellow,
      secondary: AppColors.primaryYellow,
      surface: AppColors.surface,
    ),
    textTheme: const TextTheme(
      displayLarge: baseText,
      displayMedium: baseText,
      displaySmall: baseText,
      headlineMedium: baseText,
      headlineSmall: baseText,
      titleLarge: baseText,
      bodyLarge: baseText,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodyMuted,
      labelLarge: baseText,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryYellow,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      selectionColor: AppColors.selection,
      cursorColor: AppColors.primaryYellow,
      selectionHandleColor: AppColors.primaryYellow,
    ),
    useMaterial3: true,
    cupertinoOverrideTheme: const CupertinoThemeData(
      primaryColor: AppColors.primaryYellow,
      primaryContrastingColor: AppColors.black,
      brightness: Brightness.dark,
      selectionHandleColor: AppColors.primaryYellow,
    ),
  );
}

/// Theme for the framework [LicensePage], with a focus fill that keeps D-pad
/// focus visible on its list tiles and back button.
ThemeData buildLicensePageTheme() {
  final base = buildAppTheme();
  final focusOverlay = WidgetStateProperty.resolveWith<Color?>(
    (states) =>
        states.contains(WidgetState.focused) ? AppColors.focusFill : null,
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    focusColor: AppColors.focusFill,
    colorScheme: base.colorScheme.copyWith(
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceTint: AppColors.transparent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTextStyles.titleLarge,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: AppColors.border),
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: AppColors.textPrimary,
      iconColor: AppColors.textPrimary,
      selectedColor: AppColors.primaryYellow,
      selectedTileColor: AppColors.glassSurfaceStrong,
      titleTextStyle: AppTextStyles.labelMedium,
      // White, not textTertiary: it must keep 4.5:1 on the focus fill.
      subtitleTextStyle: AppTextStyles.caption.copyWith(
        color: AppColors.textPrimary,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(overlayColor: focusOverlay),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        overlayColor: focusOverlay,
        foregroundColor: const WidgetStatePropertyAll(AppColors.primaryYellow),
      ),
    ),
  );
}
