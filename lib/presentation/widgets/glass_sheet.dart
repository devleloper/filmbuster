import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

/// Frosted bottom sheet with a title above a scrollable [child].
class GlassSheet extends StatelessWidget {
  const GlassSheet({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  /// Padding for a list inside the sheet. The top inset keeps the focus ring
  /// of the first row clear of the list's clip edge.
  static const EdgeInsets listPadding = EdgeInsets.fromLTRB(
    AppSpacing.xxxl,
    AppFocus.ringExtent,
    AppSpacing.xxxl,
    AppSpacing.xl,
  );

  static const double _heightFactor = 0.55;

  @override
  Widget build(BuildContext context) {
    return GlassSheetSurface(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * _heightFactor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxxl,
                AppSpacing.xl,
                AppSpacing.xxxl,
                AppSpacing.md,
              ),
              child: Text(title, style: AppTextStyles.titleLarge),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// The frosted surface of a bottom sheet, for sheets that lay out their own
/// content.
class GlassSheetSurface extends StatelessWidget {
  const GlassSheetSurface({
    super.key,
    this.padding = EdgeInsets.zero,
    required this.child,
  });

  final EdgeInsetsGeometry padding;
  final Widget child;

  static const double _blurSigma = 12;
  static const BorderSide _edge = BorderSide(
    width: 0.5,
    color: AppColors.borderStrong,
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.sheetTop,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: Container(
          padding: padding,
          decoration: const BoxDecoration(
            color: AppColors.glassSheet,
            borderRadius: AppRadius.sheetTop,
            border: Border(top: _edge, left: _edge, right: _edge),
          ),
          child: child,
        ),
      ),
    );
  }
}
