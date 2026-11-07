import 'package:flutter/widgets.dart';

/// Window-width classes, from the narrowest up, with the sizes each one uses.
enum ResponsiveBreakpoint {
  compact(0, 1.0, 16, 130),
  medium(600, 1.15, 20, 150),
  large(900, 1.3, 24, 170),
  xlarge(1200, 1.5, 32, 190);

  const ResponsiveBreakpoint(
    this.minWidth,
    this.scaleFactor,
    this.horizontalPadding,
    this.posterCardWidth,
  );

  final double minWidth;
  final double scaleFactor;
  final double horizontalPadding;
  final double posterCardWidth;

  static ResponsiveBreakpoint forWidth(double width) =>
      values.lastWhere((breakpoint) => width >= breakpoint.minWidth);
}

/// Sizes that grow with the window width.
class ResponsiveLayout {
  const ResponsiveLayout._(this.breakpoint);

  /// The widest a paragraph of body text gets; longer lines are hard to read.
  static const double maxTextWidth = 720;

  final ResponsiveBreakpoint breakpoint;

  static ResponsiveLayout of(BuildContext context) => ResponsiveLayout._(
    ResponsiveBreakpoint.forWidth(MediaQuery.sizeOf(context).width),
  );

  double get scaleFactor => breakpoint.scaleFactor;
  double get horizontalPadding => breakpoint.horizontalPadding;
  double get posterCardWidth => breakpoint.posterCardWidth;
  double get posterCardHeight => posterCardWidth * 3 / 2;

  double scaleFontSize(double base) => base * scaleFactor;

  TextStyle scaleText(TextStyle style) =>
      style.copyWith(fontSize: scaleFontSize(style.fontSize!));

  /// Rounded to whole logical pixels so edges stay sharp.
  double scaled(double value) => (value * scaleFactor).roundToDouble();
}
