import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

enum HeadGesture { togglePlay, seekForward, seekBackward, recenter }

enum _Spike {
  nod(HeadGesture.togglePlay),
  turnLeft(HeadGesture.seekBackward),
  turnRight(HeadGesture.seekForward);

  const _Spike(this.gesture);

  final HeadGesture gesture;
}

/// Turns head movements into [HeadGesture]s.
///
/// Two nods, or two turns to the same side, within [_gestureWindow] form a
/// gesture; shaking the head left, right and left again recenters.
class HeadGestureDetector {
  HeadGestureDetector({Stream<GyroscopeEvent>? gyroscope}) {
    _subscription =
        (gyroscope ?? gyroscopeEventStream(samplingPeriod: _samplingPeriod))
            .listen(_onGyroscope);
  }

  /// Angular speed, in rad/s, that counts as a deliberate movement.
  static const double _spikeThreshold = 1.5;
  static const _gestureWindow = Duration(milliseconds: 800);

  /// Keeps one long movement from counting as two spikes.
  static const _minSpikeSeparation = Duration(milliseconds: 200);
  static const _shakeWindow = Duration(milliseconds: 2500);

  /// Quiet time after a gesture, so the head returning does not trigger
  /// another.
  static const _cooldown = Duration(seconds: 1);
  static const _samplingPeriod = Duration(milliseconds: 20);

  final StreamController<HeadGesture> _gestures =
      StreamController<HeadGesture>.broadcast();
  late final StreamSubscription<GyroscopeEvent> _subscription;

  _Spike? _pendingSpike;
  DateTime? _pendingSince;
  final List<({bool left, DateTime at})> _shakes = [];
  bool? _lastShakeLeft;
  DateTime? _lastGestureAt;

  Stream<HeadGesture> get gestureStream => _gestures.stream;

  void _onGyroscope(GyroscopeEvent event) {
    final now = event.timestamp;
    final lastGestureAt = _lastGestureAt;
    if (lastGestureAt != null && now.difference(lastGestureAt) < _cooldown) {
      return;
    }

    _trackShake(event.x, now);

    final spike = _spikeOf(event);
    final pendingSpike = _pendingSpike;
    final pendingSince = _pendingSince;

    if (pendingSpike == null || pendingSince == null) {
      if (spike != null) _startPending(spike, now);
      return;
    }

    final sincePending = now.difference(pendingSince);
    if (spike == null) {
      if (sincePending > _gestureWindow) _clearPending();
    } else if (sincePending >= _gestureWindow) {
      _startPending(spike, now);
    } else if (sincePending > _minSpikeSeparation && spike == pendingSpike) {
      _emit(spike.gesture, now);
    }
  }

  static _Spike? _spikeOf(GyroscopeEvent event) {
    if (event.y.abs() > _spikeThreshold) return _Spike.nod;
    if (event.x > _spikeThreshold) return _Spike.turnLeft;
    if (event.x < -_spikeThreshold) return _Spike.turnRight;
    return null;
  }

  void _trackShake(double turnRate, DateTime now) {
    _shakes.removeWhere((shake) => now.difference(shake.at) > _shakeWindow);

    if (turnRate.abs() <= _spikeThreshold) return;
    final left = turnRate > 0;
    if (_lastShakeLeft == left) return;
    _lastShakeLeft = left;
    _shakes.add((left: left, at: now));

    if (_shakes case [
      ...,
      final first,
      final second,
      final third,
    ] when first.left != second.left && second.left != third.left) {
      _emit(HeadGesture.recenter, now);
    }
  }

  void _startPending(_Spike spike, DateTime now) {
    _pendingSpike = spike;
    _pendingSince = now;
  }

  void _clearPending() {
    _pendingSpike = null;
    _pendingSince = null;
  }

  void _emit(HeadGesture gesture, DateTime now) {
    _gestures.add(gesture);
    _lastGestureAt = now;
    _clearPending();
    _shakes.clear();
    _lastShakeLeft = null;
  }

  void dispose() {
    _subscription.cancel();
    _gestures.close();
  }
}
