import 'package:flutter/gestures.dart' show Offset, kDoubleTapTimeout;

/// `GestureDetector.onDoubleTap` would delay every single tap until the
/// double-tap window closes; the player answers single taps at once.
class DoubleTapTracker {
  static const window = kDoubleTapTimeout;

  static const double _slop = 50;

  DateTime? _lastTapAt;
  Offset? _lastTapPosition;

  /// Records a tap at [position] made at [time], and returns whether it
  /// completes a double tap.
  bool register(Offset position, DateTime time) {
    final lastTapAt = _lastTapAt;
    final lastTapPosition = _lastTapPosition;
    final isDoubleTap =
        lastTapAt != null &&
        lastTapPosition != null &&
        time.difference(lastTapAt) < window &&
        (position - lastTapPosition).distance < _slop;

    _lastTapAt = isDoubleTap ? null : time;
    _lastTapPosition = isDoubleTap ? null : position;
    return isDoubleTap;
  }
}
