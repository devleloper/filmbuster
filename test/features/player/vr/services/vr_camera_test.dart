import 'dart:async';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:filmbuster/presentation/features/player/vr/services/vr_camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

/// A back camera that finishes starting when the test says so.
class _SlowCamera extends CameraPlatform {
  final _started = Completer<void>();

  /// Ids of the cameras released so far.
  final List<int> released = [];

  void finishStarting() => _started.complete();

  @override
  Future<List<CameraDescription>> availableCameras() async => const [
    CameraDescription(
      name: 'back',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    ),
  ];

  @override
  Future<int> createCameraWithSettings(
    CameraDescription cameraDescription,
    MediaSettings mediaSettings,
  ) async => 1;

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) => _started.future;

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      Stream.fromFuture(
        _started.future.then(
          (_) => CameraInitializedEvent(
            cameraId,
            640,
            480,
            ExposureMode.auto,
            false,
            FocusMode.auto,
            false,
          ),
        ),
      );

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) =>
      StreamController<CameraErrorEvent>().stream;

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream.empty();

  @override
  Future<void> dispose(int cameraId) async => released.add(cameraId);
}

class _CameraAllowed extends PermissionHandlerPlatform {
  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async => {
    for (final permission in permissions) permission: PermissionStatus.granted,
  };
}

void main() {
  late _SlowCamera device;

  setUp(() {
    device = _SlowCamera();
    CameraPlatform.instance = device;
    PermissionHandlerPlatform.instance = _CameraAllowed();
  });

  test('a camera closed while it opens is not handed to the opener', () async {
    final camera = VrCamera();
    final opened = camera.open();
    // Permission granted, the camera is starting.
    await pumpEventQueue();

    final closed = camera.close();
    device.finishStarting();

    expect(await opened, isNull);
    await closed;
    expect(device.released, [1]);
  });

  test('a close releases the camera an earlier open handed out', () async {
    final camera = VrCamera();
    final opened = camera.open();
    device.finishStarting();
    expect((await opened)?.value.isInitialized, isTrue);

    await camera.close();

    expect(device.released, [1]);
  });
}
