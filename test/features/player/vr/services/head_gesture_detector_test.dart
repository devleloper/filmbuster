import 'dart:async';

import 'package:filmbuster/presentation/features/player/vr/services/head_gesture_detector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Angular speed, in rad/s, well past what counts as a deliberate movement.
const _fast = 3.0;

final _start = DateTime(2026);

class _Head {
  _Head() {
    detector.gestureStream.listen(gestures.add);
    addTearDown(() async {
      detector.dispose();
      await _gyroscope.close();
    });
  }

  final _gyroscope = StreamController<GyroscopeEvent>();
  late final HeadGestureDetector detector = HeadGestureDetector(
    gyroscope: _gyroscope.stream,
  );
  final List<HeadGesture> gestures = [];

  Future<void> nod({required int atMs}) => _move(y: _fast, atMs: atMs);

  Future<void> turnLeft({required int atMs}) => _move(x: _fast, atMs: atMs);

  Future<void> turnRight({required int atMs}) => _move(x: -_fast, atMs: atMs);

  Future<void> _move({double x = 0, double y = 0, required int atMs}) {
    _gyroscope.add(
      GyroscopeEvent(x, y, 0, _start.add(Duration(milliseconds: atMs))),
    );
    return pumpEventQueue();
  }
}

void main() {
  test('two nods in quick succession toggle playback', () async {
    final head = _Head();

    await head.nod(atMs: 0);
    await head.nod(atMs: 400);

    expect(head.gestures, [HeadGesture.togglePlay]);
  });

  test('two nods too far apart do nothing', () async {
    final head = _Head();

    await head.nod(atMs: 0);
    await head.nod(atMs: 1000);

    expect(head.gestures, isEmpty);
  });

  test('two turns to the same side seek that way', () async {
    final head = _Head();

    await head.turnRight(atMs: 0);
    await head.turnRight(atMs: 400);

    expect(head.gestures, [HeadGesture.seekForward]);
  });

  test('shaking the head left, right and left recenters', () async {
    final head = _Head();

    await head.turnLeft(atMs: 0);
    await head.turnRight(atMs: 300);
    await head.turnLeft(atMs: 600);

    expect(head.gestures, [HeadGesture.recenter]);
  });

  test('nods within a second of a gesture are ignored', () async {
    final head = _Head();
    await head.nod(atMs: 0);
    await head.nod(atMs: 400);

    // Still cooling down.
    await head.nod(atMs: 600);
    await head.nod(atMs: 1000);

    // A fresh double nod.
    await head.nod(atMs: 1500);
    await head.nod(atMs: 1900);

    expect(head.gestures, [HeadGesture.togglePlay, HeadGesture.togglePlay]);
  });
}
