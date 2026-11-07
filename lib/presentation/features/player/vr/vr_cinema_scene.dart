import 'dart:ui';

import 'package:flutter/widgets.dart';

/// A virtual screen in front of the viewer, turned by [headMatrix], with a
/// blurred glow behind it.
class VrCinemaScene extends StatelessWidget {
  const VrCinemaScene({
    super.key,
    required this.headMatrix,
    required this.child,
    this.glowChild,
  });

  static const double _screenDistance = 500;
  static const double _glowScale = 1.15;
  static const double _glowBlurSigma = 20;
  static const double _glowOpacity = 0.5;

  final Matrix4 headMatrix;
  final Widget child;

  /// Blurred behind [child]; [child] itself when null.
  final Widget? glowChild;

  @override
  Widget build(BuildContext context) {
    final transform = headMatrix.clone()
      ..multiply(Matrix4.translationValues(0, 0, -_screenDistance));

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Opacity(
              opacity: _glowOpacity,
              child: Transform.scale(
                scale: _glowScale,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: _glowBlurSigma,
                    sigmaY: _glowBlurSigma,
                    tileMode: TileMode.decal,
                  ),
                  child: glowChild ?? child,
                ),
              ),
            ),
          ),
        ),
        Center(
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ],
    );
  }
}
