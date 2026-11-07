import 'package:flutter/widgets.dart';

import '../../../../../core/utils/responsive.dart';
import '../../../../widgets/app_icon_button.dart';

/// The player's controls in keyboard and D-pad traversal order.
enum PlayerControl {
  back,
  enterVr,
  fullscreen,
  centerPlayPause,
  seekBar,
  rewind,
  playPause,
  forward,
  quality,
  subtitles,
  audio,
}

class PlayerControlOrder extends StatelessWidget {
  const PlayerControlOrder(this.control, {super.key, required this.child});

  final PlayerControl control;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(control.index.toDouble()),
      child: child,
    );
  }
}

class PlayerButton extends StatelessWidget {
  const PlayerButton({
    super.key,
    required this.control,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final PlayerControl control;
  final IconData icon;
  final String label;

  final VoidCallback? onPressed;

  static double _sizeFor(ResponsiveBreakpoint breakpoint) =>
      switch (breakpoint) {
        ResponsiveBreakpoint.compact => 48,
        ResponsiveBreakpoint.medium => 52,
        ResponsiveBreakpoint.large => 56,
        ResponsiveBreakpoint.xlarge => 64,
      };

  @override
  Widget build(BuildContext context) {
    final size = _sizeFor(ResponsiveLayout.of(context).breakpoint);
    return PlayerControlOrder(
      control,
      child: AppIconButton(
        icon: icon,
        semanticLabel: label,
        onPressed: onPressed,
        size: size,
        iconSize: size / 2,
      ),
    );
  }
}
