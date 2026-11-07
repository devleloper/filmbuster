import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/seek_steps.dart';

/// Keeps seeking by [arrowSeekSeconds] while an arrow key is held.
class RepeatSeekController {
  RepeatSeekController({required this.onSeekStep});

  static const interval = Duration(milliseconds: 150);

  /// Gets a signed number of seconds.
  final ValueChanged<int> onSeekStep;

  Timer? _timer;
  int _direction = 0;

  /// Starts repeating towards [direction]: -1 back, 1 forward.
  void start(int direction) {
    if (_direction == direction) return;
    stop();
    _direction = direction;
    _timer = Timer.periodic(
      interval,
      (_) => onSeekStep(direction * arrowSeekSeconds),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _direction = 0;
  }

  void dispose() => stop();
}
