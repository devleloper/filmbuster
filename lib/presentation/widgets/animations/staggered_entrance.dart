import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_theme.dart';

/// Fades, slides and scales [child] in after a delay that grows with its
/// [index], so that neighbours in a list enter one after another.
///
/// [child] appears at rest when [enabled] is false or the platform asks for
/// reduced motion.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.enabled = true,
  });

  final int index;
  final Widget child;
  final bool enabled;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> {
  // The delay restarts every few items, so items far down a long list do not
  // wait long.
  static const int _delayCycle = 10;

  // Decided once: a rebuild must neither restart the entrance nor swap the
  // subtree of a child that may hold focus.
  late final bool _animates = widget.enabled && !AppMotion.reduced(context);

  @override
  Widget build(BuildContext context) {
    if (!_animates) return widget.child;

    const curve = Curves.easeOut;
    return RepaintBoundary(
      child: widget.child
          .animate(delay: AppDurations.stagger * (widget.index % _delayCycle))
          .fadeIn(duration: AppDurations.slow, curve: curve)
          .slide(
            begin: const Offset(0, 0.15),
            duration: AppDurations.slow,
            curve: curve,
          )
          .scale(
            begin: const Offset(0.8, 0.8),
            duration: AppDurations.slow,
            curve: curve,
          ),
    );
  }
}
