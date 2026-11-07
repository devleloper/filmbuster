import 'dart:async';

import '../models/playback_status.dart';

/// Calls [onStall] once playback has been buffering for [timeout] without a
/// break.
class StallWatchdog {
  StallWatchdog({required this.timeout, required this.onStall});

  final Duration timeout;
  final void Function() onStall;

  Timer? _timer;

  /// Follows playback through [status]. A seek buffers by design, so a
  /// buffering status while [seeking] starts no watch.
  void observe(PlaybackStatus status, {required bool seeking}) {
    if (!status.buffering) {
      cancel();
      return;
    }
    if (_timer != null || seeking) return;
    _timer = Timer(timeout, () {
      _timer = null;
      onStall();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
