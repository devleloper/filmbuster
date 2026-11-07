import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math_64.dart' as vm64;

import 'head_pose_filter.dart';

/// 3DoF head tracking for VR Cinema from the gyroscope and accelerometer.
///
/// Emits a view rotation in Flutter's screen frame (x right, y down) relative
/// to the head pose at the last [resetOrientation]; the first reset happens
/// once gravity is known, or at once without an accelerometer.
class HeadTracker {
  HeadTracker({
    Stream<GyroscopeEvent>? gyroscope,
    Stream<AccelerometerEvent>? accelerometer,
  }) {
    _accelSubscription =
        (accelerometer ??
                accelerometerEventStream(samplingPeriod: _samplingPeriod))
            .listen(
              (e) => _filter.addAccelerometer(e.x, e.y, e.z),
              onError: (Object _) => _accelUnavailable = true,
            );
    _gyroSubscription =
        (gyroscope ?? gyroscopeEventStream(samplingPeriod: _samplingPeriod))
            .listen(_onGyro, onError: (Object _) {});
  }

  static const Duration _samplingPeriod = SensorInterval.gameInterval;
  static const double _smoothAlpha = 0.25;

  final _viewMatrixController = StreamController<vm64.Matrix4>.broadcast();

  Stream<vm64.Matrix4> get viewMatrix => _viewMatrixController.stream;

  final _filter = HeadPoseFilter();

  late final StreamSubscription<GyroscopeEvent> _gyroSubscription;
  late final StreamSubscription<AccelerometerEvent> _accelSubscription;

  DateTime? _lastGyroTime;
  bool _accelUnavailable = false;
  bool _hasReset = false;
  vm64.Quaternion _smoothedView = vm64.Quaternion.identity();

  void _onGyro(GyroscopeEvent event) {
    final last = _lastGyroTime;
    _lastGyroTime = event.timestamp;
    if (last != null) {
      final dt = event.timestamp.difference(last).inMicroseconds / 1e6;
      _filter.addGyroscope(event.x, event.y, event.z, dt);
    }

    if (!_hasReset) {
      if (!_filter.isAligned && !_accelUnavailable) return;
      _hasReset = true;
      resetOrientation();
      return;
    }

    _emitFrame();
  }

  void _emitFrame() {
    if (_viewMatrixController.isClosed) return;

    final target = vm64.Quaternion.fromRotation(_filter.viewRotation());
    _smoothedView = _slerp(_smoothedView, target, _smoothAlpha);

    _viewMatrixController.add(
      vm64.Matrix4.identity()..setRotation(_smoothedView.asRotationMatrix()),
    );
  }

  static vm64.Quaternion _slerp(
    vm64.Quaternion a,
    vm64.Quaternion b,
    double t,
  ) {
    var dot = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
    var target = b;
    if (dot < 0) {
      target = vm64.Quaternion(-b.x, -b.y, -b.z, -b.w);
      dot = -dot;
    }

    if (dot > 0.9995) {
      final result = vm64.Quaternion(
        a.x + t * (target.x - a.x),
        a.y + t * (target.y - a.y),
        a.z + t * (target.z - a.z),
        a.w + t * (target.w - a.w),
      );
      result.normalize();
      return result;
    }
    final theta = acos(dot.clamp(-1.0, 1.0));
    final sinTheta = sin(theta);
    final wa = sin((1 - t) * theta) / sinTheta;
    final wb = sin(t * theta) / sinTheta;
    final result = vm64.Quaternion(
      wa * a.x + wb * target.x,
      wa * a.y + wb * target.y,
      wa * a.z + wb * target.z,
      wa * a.w + wb * target.w,
    );
    result.normalize();
    return result;
  }

  void resetOrientation() {
    _filter.recenter();

    _smoothedView = vm64.Quaternion.identity();
    _emitFrame();
  }

  void dispose() {
    _gyroSubscription.cancel();
    _accelSubscription.cancel();
    _viewMatrixController.close();
  }
}
