import 'dart:async';

import '../models/playback_status.dart';
import 'playback_engine.dart';

/// Waits on what the engine reports, each within a deadline: a stalled stream
/// may report nothing at all.
extension PlaybackEngineWaits on PlaybackEngine {
  /// Playback this far past a position proves that the stream flows.
  static const progressProof = Duration(seconds: 1);

  /// Whether a status reported from now on passes [test] within [within].
  Future<bool> reportsWithin(
    bool Function(PlaybackStatus status) test,
    Duration within,
  ) async {
    try {
      await statusChanges.firstWhere(test).timeout(within);
      return true;
    } on TimeoutException {
      return false;
    } on StateError {
      // The stream closed without a match.
      return false;
    }
  }

  /// Whether playback has started, or starts within [within].
  Future<bool> startsWithin(Duration within) async =>
      status.hasStarted ||
      await reportsWithin((next) => next.hasStarted, within);

  /// Whether playback gets near [target] within [within].
  Future<bool> settlesWithin(Duration target, Duration within) async =>
      status.isNear(target) ||
      await reportsWithin((next) => next.isNear(target), within);

  /// Whether playback moves on past [position] within [within].
  Future<bool> playsOnPastWithin(Duration position, Duration within) =>
      reportsWithin(
        (next) => next.playing && next.position > position + progressProof,
        within,
      );
}
