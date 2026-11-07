import 'dart:async';

import 'package:filmbuster/presentation/features/player/vr/services/head_tracker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

const _gravity = 9.81;

final _start = DateTime(2026);

/// A phone in landscape inside a headset, its top on the left.
class _Headset {
  _Headset() {
    tracker.viewMatrix.listen(frames.add);
    addTearDown(() async {
      tracker.dispose();
      await _gyroscope.close();
      await _accelerometer.close();
    });
  }

  final _gyroscope = StreamController<GyroscopeEvent>();
  final _accelerometer = StreamController<AccelerometerEvent>();
  late final HeadTracker tracker = HeadTracker(
    gyroscope: _gyroscope.stream,
    accelerometer: _accelerometer.stream,
  );
  final List<Matrix4> frames = [];

  /// Holds still for one sample, [atMs] after the start.
  Future<void> holdStill({required int atMs}) =>
      _sample(yawRate: 0, atMs: atMs);

  /// Turns the head at [yawRate] rad/s for one sample.
  Future<void> turn({required double yawRate, required int atMs}) =>
      _sample(yawRate: yawRate, atMs: atMs);

  Future<void> _sample({required double yawRate, required int atMs}) {
    final at = _start.add(Duration(milliseconds: atMs));
    _accelerometer.add(AccelerometerEvent(_gravity, 0, 0, at));
    _gyroscope.add(GyroscopeEvent(yawRate, 0, 0, at));
    return pumpEventQueue();
  }
}

void main() {
  test('the first view, once gravity is known, looks straight ahead', () async {
    final headset = _Headset();

    await headset.holdStill(atMs: 0);

    expect(headset.frames.single, matrixMoreOrLessEquals(Matrix4.identity()));
  });

  test('recentering after a turn looks straight ahead again', () async {
    final headset = _Headset();
    await headset.holdStill(atMs: 0);
    for (var atMs = 20; atMs <= 400; atMs += 20) {
      await headset.turn(yawRate: 2, atMs: atMs);
    }
    expect(
      headset.frames.last,
      isNot(matrixMoreOrLessEquals(Matrix4.identity())),
    );

    headset.tracker.resetOrientation();
    await pumpEventQueue();

    expect(headset.frames.last, matrixMoreOrLessEquals(Matrix4.identity()));
  });
}
