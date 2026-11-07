import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';

/// Keeps every tab branch mounted and cross-fades to the current one.
class AnimatedShellContent extends StatelessWidget {
  const AnimatedShellContent({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (index, child) in children.indexed)
          _ShellBranch(visible: index == currentIndex, child: child),
      ],
    );
  }
}

class _ShellBranch extends StatelessWidget {
  const _ShellBranch({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppDurations.medium);
    return AnimatedScale(
      scale: visible ? 1 : 0.96,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: ExcludeFocus(
          excluding: !visible,
          child: IgnorePointer(
            ignoring: !visible,
            child: TickerMode(enabled: visible, child: child),
          ),
        ),
      ),
    );
  }
}
