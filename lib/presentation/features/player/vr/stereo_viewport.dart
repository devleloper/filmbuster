import 'package:flutter/widgets.dart';

import '../../../theme/app_colors.dart';
import 'vr_cinema_scene.dart';

/// Renders the cinema scene twice, side by side, one view per eye.
class StereoViewport extends StatelessWidget {
  const StereoViewport({
    super.key,
    required this.headMatrix,
    required this.child,
    this.glowChild,
    this.backgroundBuilder,
  });

  final Matrix4 headMatrix;
  final Widget child;
  final Widget? glowChild;

  /// Builds what each eye sees around the screen, such as the camera feed;
  /// the scene is black without it.
  final WidgetBuilder? backgroundBuilder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final alignment in [Alignment.centerLeft, Alignment.centerRight])
          Expanded(child: RepaintBoundary(child: _eye(context, alignment))),
      ],
    );
  }

  Widget _eye(BuildContext context, Alignment alignment) {
    return Stack(
      fit: StackFit.expand,
      children: [
        backgroundBuilder?.call(context) ??
            const ColoredBox(color: AppColors.black),
        ClipRect(
          child: Align(
            alignment: alignment,
            widthFactor: 0.5,
            child: VrCinemaScene(
              headMatrix: headMatrix,
              glowChild: glowChild,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
