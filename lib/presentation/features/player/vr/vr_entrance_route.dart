import 'package:flutter/widgets.dart';

import '../../../theme/app_colors.dart';

/// Fades the player to black, then lets the VR scene grow in.
class VrEntranceRoute extends PageRouteBuilder<void> {
  VrEntranceRoute({required WidgetBuilder builder, required bool reduceMotion})
    : super(
        opaque: false,
        transitionDuration: reduceMotion ? Duration.zero : _duration,
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: _transition,
      );

  /// Long enough to read as putting on a headset.
  static const _duration = Duration(milliseconds: 1200);

  static const _blackout = Interval(0, 0.5, curve: Curves.easeInOut);
  static const _sceneFadeIn = Interval(0.4, 1, curve: Curves.easeInOut);
  static const _sceneGrow = Interval(0.4, 1, curve: Curves.easeOutCubic);

  static Widget _transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return Stack(
      children: [
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: _blackout),
          child: const ColoredBox(
            color: AppColors.black,
            child: SizedBox.expand(),
          ),
        ),
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: _sceneFadeIn),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1,
            ).animate(CurvedAnimation(parent: animation, curve: _sceneGrow)),
            child: child,
          ),
        ),
      ],
    );
  }
}
