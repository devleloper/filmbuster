import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';
import '../text_link.dart';

/// License credit for an open movie: "CC BY 3.0 · Blender Foundation · Source".
///
/// The license name links to the license deed and the source label to the
/// licensor's page, as CC BY requires.
class LicenseCredit extends StatelessWidget {
  const LicenseCredit({
    super.key,
    required this.licenseName,
    required this.author,
    required this.sourceLabel,
    required this.onLicenseTap,
    required this.onSourceTap,
    this.licenseSemanticLabel,
    this.sourceSemanticLabel,
    this.linkHint,
  });

  /// Short name with version, e.g. "CC BY 3.0".
  final String licenseName;

  /// Attribution as the licensor asks for it, e.g. "Blender Foundation".
  final String author;

  final String sourceLabel;

  final VoidCallback? onLicenseTap;
  final VoidCallback? onSourceTap;

  /// Screen-reader labels; default to the visible texts.
  final String? licenseSemanticLabel;
  final String? sourceSemanticLabel;

  final String? linkHint;

  @override
  Widget build(BuildContext context) {
    // textSecondary instead of caption's textTertiary: this line sits on
    // backdrop scrims, where 54 % white can fall below 4.5:1.
    final textStyle = AppTextStyles.caption.copyWith(
      color: AppColors.textSecondary,
    );
    // About the size of a middle dot in the same text.
    final dotRadius =
        MediaQuery.textScalerOf(context).scale(textStyle.fontSize!) / 10;
    return _DotSeparatedWrap(
      dotColor: AppColors.textSecondary,
      dotRadius: dotRadius,
      children: [
        TextLink(
          label: licenseName,
          onTap: onLicenseTap,
          semanticLabel: licenseSemanticLabel,
          semanticHint: linkHint,
          icon: null,
          style: AppTextStyles.captionStrong,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(author, style: textStyle),
        ),
        TextLink(
          label: sourceLabel,
          onTap: onSourceTap,
          semanticLabel: sourceSemanticLabel,
          semanticHint: linkHint,
          style: AppTextStyles.captionStrong,
        ),
      ],
    );
  }
}

// Dots are painted rather than added as children, so no line starts or ends
// with one and screen readers skip them.
class _DotSeparatedWrap extends Wrap {
  const _DotSeparatedWrap({
    required this.dotColor,
    required this.dotRadius,
    required super.children,
  }) : super(
         spacing: AppSpacing.sm,
         crossAxisAlignment: WrapCrossAlignment.center,
       );

  final Color dotColor;
  final double dotRadius;

  @override
  RenderWrap createRenderObject(BuildContext context) =>
      _RenderDotSeparatedWrap(
        dotColor: dotColor,
        dotRadius: dotRadius,
        spacing: spacing,
        crossAxisAlignment: crossAxisAlignment,
        textDirection: textDirection ?? Directionality.maybeOf(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderDotSeparatedWrap renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
    renderObject
      ..dotColor = dotColor
      ..dotRadius = dotRadius;
  }
}

class _RenderDotSeparatedWrap extends RenderWrap {
  _RenderDotSeparatedWrap({
    required Color dotColor,
    required double dotRadius,
    super.spacing,
    super.crossAxisAlignment,
    super.textDirection,
  }) : _dotColor = dotColor,
       _dotRadius = dotRadius;

  Color _dotColor;
  set dotColor(Color value) {
    if (value == _dotColor) return;
    _dotColor = value;
    markNeedsPaint();
  }

  double _dotRadius;
  set dotRadius(double value) {
    if (value == _dotRadius) return;
    _dotRadius = value;
    markNeedsPaint();
  }

  Rect _rectOf(RenderBox child) =>
      (child.parentData! as WrapParentData).offset & child.size;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final rtl = textDirection == TextDirection.rtl;
    final dot = Paint()..color = _dotColor;
    var child = firstChild;
    while (child != null) {
      final next = childAfter(child);
      if (next == null) break;
      final a = _rectOf(child);
      final b = _rectOf(next);
      // A child that does not continue in reading order starts the next run.
      const rounding = 0.5;
      final sameRun = rtl
          ? b.right <= a.left + rounding
          : b.left >= a.right - rounding;
      if (sameRun) {
        final x = rtl ? (b.right + a.left) / 2 : (a.right + b.left) / 2;
        final y = (a.center.dy + b.center.dy) / 2;
        context.canvas.drawCircle(offset + Offset(x, y), _dotRadius, dot);
      }
      child = next;
    }
  }
}
