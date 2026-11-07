import 'package:flutter/widgets.dart';

import '../../utils/double_tap_tracker.dart';
import '../../utils/pinch_fill_tracker.dart';

/// Taps and pinches on the video surface. A single tap is reported at once,
/// without waiting to rule out a double tap.
class PlayerSurfaceGestures extends StatefulWidget {
  const PlayerSurfaceGestures({
    super.key,
    required this.onTap,
    required this.onDoubleTap,
    required this.onPinch,
    required this.child,
  });

  /// Gets the global position of the tap.
  final ValueChanged<Offset> onTap;

  /// Gets the global position of the second tap.
  final ValueChanged<Offset> onDoubleTap;

  /// Gets true for a pinch that spreads to fill the screen, false for one
  /// that closes to fit the video.
  final ValueChanged<bool> onPinch;

  final Widget child;

  @override
  State<PlayerSurfaceGestures> createState() => _PlayerSurfaceGesturesState();
}

class _PlayerSurfaceGesturesState extends State<PlayerSurfaceGestures> {
  final DoubleTapTracker _doubleTaps = DoubleTapTracker();
  final PinchFillTracker _pinch = PinchFillTracker();

  void _onTapUp(TapUpDetails details) {
    final position = details.globalPosition;
    if (_doubleTaps.register(position, DateTime.now())) {
      widget.onDoubleTap(position);
    } else {
      widget.onTap(position);
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_pinch.update(details.scale) case final fillsScreen?) {
      widget.onPinch(fillsScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _onTapUp,
      onScaleStart: (_) => _pinch.start(),
      onScaleUpdate: _onScaleUpdate,
      behavior: HitTestBehavior.opaque,
      // Taps act by screen position; a screen reader gets the labelled
      // controls instead.
      excludeFromSemantics: true,
      child: widget.child,
    );
  }
}
