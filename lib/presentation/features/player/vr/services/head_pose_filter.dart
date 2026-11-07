import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' as vm64;

/// Orientation estimate from device-frame sensor samples in sensors_plus
/// conventions: right-handed device axes, gyroscope in rad/s, accelerometer
/// in m/s² pointing up when the device is at rest.
///
/// A complementary filter: the gyroscope is integrated, the accelerometer
/// pulls pitch and roll back to gravity, and the gyroscope bias is learned
/// while the head is still. Yaw has no absolute reference and can drift
/// slowly; the recenter gesture re-anchors it.
class HeadPoseFilter {
  static const double _gravity = 9.81;

  /// How strongly gravity pulls pitch and roll back, per second.
  static const double _tiltGain = 1.0;

  /// Angular speed, rad/s, below which the head counts as still and the
  /// gyroscope bias is learned.
  static const double _stillRate = 0.04;

  /// Seconds the learned bias takes to follow a still gyroscope.
  static const double _biasTimeConstant = 5.0;

  /// Longest gap between gyroscope samples, in seconds, that is integrated.
  static const double _maxStep = 0.1;

  /// Readings further than this share of g from gravity mean motion, not tilt.
  static const double _gravityTolerance = 0.2;

  static final vm64.Vector3 _worldUp = vm64.Vector3(0, 0, 1);

  vm64.Quaternion _device = vm64.Quaternion.identity();
  vm64.Quaternion _anchor = vm64.Quaternion.identity();
  vm64.Quaternion _toScreen = _screenFromDevice(1);

  final vm64.Vector3 _bias = vm64.Vector3.zero();
  vm64.Vector3? _up;
  bool _aligned = false;

  bool get isAligned => _aligned;

  /// Gyroscope bias learned so far, rad/s in device axes.
  @visibleForTesting
  vm64.Vector3 get gyroBias => _bias.clone();

  void addAccelerometer(double x, double y, double z) {
    final a = vm64.Vector3(x, y, z);
    final norm = a.length;
    if ((norm - _gravity).abs() > _gravityTolerance * _gravity) {
      _up = null;
      return;
    }
    final up = a / norm;
    _up = up;
    if (!_aligned) {
      _device = vm64.Quaternion.fromTwoVectors(up, _worldUp);
      _aligned = true;
    }
  }

  void addGyroscope(double x, double y, double z, double dtSeconds) {
    if (dtSeconds <= 0 || dtSeconds > _maxStep) return;

    final rate = vm64.Vector3(x, y, z);
    final up = _up;
    if (up != null && (rate - _bias).length < _stillRate) {
      _bias.add((rate - _bias)..scale(dtSeconds / _biasTimeConstant));
    }

    final omega = rate - _bias;
    if (up != null && _aligned) {
      // vector_math's rotated() applies the inverse of asRotationMatrix(),
      // so this takes world up into device axes.
      final estimatedUp = _device.rotated(_worldUp);
      omega.add(up.cross(estimatedUp)..scale(_tiltGain));
    }

    final angle = omega.length * dtSeconds;
    if (angle > 1e-9) {
      _device = _device * vm64.Quaternion.axisAngle(omega.normalized(), angle);
      _device.normalize();
    }
  }

  /// Makes the current pose the forward direction. The landscape side
  /// (device top on the left or on the right) is taken from gravity.
  void recenter() {
    _anchor = vm64.Quaternion.copy(_device);
    final up = _up;
    _toScreen = _screenFromDevice(up == null || up.x >= 0 ? 1 : -1);
  }

  /// Rotation to apply to the scene, in Flutter's frame (x right, y down).
  vm64.Matrix3 viewRotation() {
    final head =
        _toScreen * _anchor.conjugated() * _device * _toScreen.conjugated();
    final m = head.normalized().conjugated().asRotationMatrix();
    for (final i in const [0, 2]) {
      m.setEntry(1, i, -m.entry(1, i));
      m.setEntry(i, 1, -m.entry(i, 1));
    }
    return m;
  }

  /// Device axes to landscape screen axes (x right, y up, z towards the
  /// viewer). [side] is 1 when the device top points left (up is device +x)
  /// and -1 when it points right.
  static vm64.Quaternion _screenFromDevice(int side) =>
      vm64.Quaternion.axisAngle(vm64.Vector3(0, 0, 1), side * pi / 2);
}
