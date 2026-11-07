import 'dart:math';

import 'package:filmbuster/presentation/features/player/vr/services/head_pose_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as vm64;

const double _g = 9.81;
const double _dt = 0.01;

/// Feeds [seconds] of samples at 100 Hz. A null [accel] means the
/// accelerometer sample is rejected (device accelerating): only the gyro counts.
void _run(
  HeadPoseFilter filter, {
  required double seconds,
  vm64.Vector3? gyro,
  vm64.Vector3? accel,
}) {
  final steps = (seconds / _dt).round();
  final w = gyro ?? vm64.Vector3.zero();
  final a = accel ?? vm64.Vector3.zero();
  for (var i = 0; i < steps; i++) {
    filter
      ..addAccelerometer(a.x, a.y, a.z)
      ..addGyroscope(w.x, w.y, w.z, _dt);
  }
}

/// Where a point straight ahead of the viewer lands after the view rotation,
/// in Flutter's frame (x right, y down, z towards the viewer).
vm64.Vector3 _ahead(HeadPoseFilter filter) =>
    filter.viewRotation().transformed(vm64.Vector3(0, 0, -1));

void main() {
  group('HeadPoseFilter', () {
    // Landscape with the device top on the left: device +x points up.
    final landscapeLeftUp = vm64.Vector3(_g, 0, 0);
    // Landscape with the device top on the right: device -x points up.
    final landscapeRightUp = vm64.Vector3(-_g, 0, 0);

    HeadPoseFilter recentered(vm64.Vector3 up) {
      final filter = HeadPoseFilter();
      _run(filter, seconds: 0.2, accel: up);
      filter.recenter();
      return filter;
    }

    test('aligns on the first valid accelerometer sample', () {
      final filter = HeadPoseFilter();
      expect(filter.isAligned, isFalse);
      filter.addAccelerometer(0, 0, 0);
      expect(filter.isAligned, isFalse);
      filter.addAccelerometer(_g, 0, 0);
      expect(filter.isAligned, isTrue);
    });

    test('view is identity right after recenter', () {
      for (final up in [landscapeLeftUp, landscapeRightUp]) {
        final m = recentered(up).viewRotation();
        expect(
          m.absoluteError(vm64.Matrix3.identity()),
          lessThan(1e-6),
          reason: 'up=$up',
        );
      }
    });

    test('turning the head left moves the scene right', () {
      // Yaw is a rotation about world up, which is device +x here.
      final filter = recentered(landscapeLeftUp);
      _run(filter, seconds: 0.5, gyro: vm64.Vector3(1, 0, 0));
      final p = _ahead(filter);
      expect(p.x, closeTo(sin(0.5), 1e-3));
      expect(p.y, closeTo(0, 1e-3));
    });

    test('yaw sign does not depend on the landscape side', () {
      final filter = recentered(landscapeRightUp);
      _run(filter, seconds: 0.5, gyro: vm64.Vector3(-1, 0, 0));
      final p = _ahead(filter);
      expect(p.x, closeTo(sin(0.5), 1e-3));
      expect(p.y, closeTo(0, 1e-3));
    });

    test('looking up moves the scene down', () {
      // Pitch up is a rotation about the screen's left-to-right axis, which
      // is device -y with the top on the left.
      final filter = recentered(landscapeLeftUp);
      _run(filter, seconds: 0.3, gyro: vm64.Vector3(0, -1, 0));
      final p = _ahead(filter);
      expect(p.y, closeTo(sin(0.3), 1e-3));
      expect(p.x, closeTo(0, 1e-3));
    });

    test('the accelerometer pulls a tilted estimate back to level', () {
      final filter = recentered(landscapeLeftUp);
      _run(filter, seconds: 0.3, gyro: vm64.Vector3(0, -1, 0));
      final tilted = _ahead(filter).y.abs();
      _run(filter, seconds: 5, accel: landscapeLeftUp);
      expect(_ahead(filter).y.abs(), lessThan(tilted * 0.05));
    });

    test('tilt correction keeps yaw level while turning and holding', () {
      // Gravity is valid on every step, so the tilt correction is active
      // during the turn as well as during the hold.
      final filter = recentered(landscapeLeftUp);
      _run(
        filter,
        seconds: 0.5,
        gyro: vm64.Vector3(1, 0, 0),
        accel: landscapeLeftUp,
      );
      var p = _ahead(filter);
      expect(p.x, closeTo(sin(0.5), 0.02));
      expect(p.y, closeTo(0, 0.02));

      _run(filter, seconds: 5, accel: landscapeLeftUp);
      p = _ahead(filter);
      expect(p.x, closeTo(sin(0.5), 0.02));
      expect(p.y, closeTo(0, 0.02));
    });

    test('learns a constant gyroscope bias while still', () {
      final filter = recentered(landscapeLeftUp);
      final bias = vm64.Vector3(0.01, -0.005, 0.02);
      _run(filter, seconds: 30, gyro: bias, accel: landscapeLeftUp);
      expect((filter.gyroBias - bias).length, lessThan(0.002));

      filter.recenter();
      _run(filter, seconds: 10, gyro: bias, accel: landscapeLeftUp);
      expect(_ahead(filter).x.abs(), lessThan(0.02));
    });

    test('ignores invalid time steps', () {
      final filter = recentered(landscapeLeftUp);
      filter.addGyroscope(1, 0, 0, 0);
      filter.addGyroscope(1, 0, 0, -0.01);
      filter.addGyroscope(1, 0, 0, 1);
      expect(
        filter.viewRotation().absoluteError(vm64.Matrix3.identity()),
        lessThan(1e-9),
      );
    });
  });
}
