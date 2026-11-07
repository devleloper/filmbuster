import 'dart:async';

import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/logging/app_logger.dart';

/// The back camera behind the spatial VR scene.
///
/// One instance serves the mode picker's preview and then the scene: the
/// picker is still closing when the scene opens, and two sessions on one
/// camera would fight over it.
class VrCamera {
  static const _log = AppLogger('VrCamera');

  CameraController? _controller;
  Future<void>? _opening;
  int _closeCount = 0;

  /// The initialized controller, or null without camera permission or a
  /// usable camera, or when [close] is called while it opens.
  Future<CameraController?> open() async {
    if (_controller?.value.isInitialized ?? false) return _controller;
    final closeCount = _closeCount;
    await (_opening ??= _initialize().whenComplete(() => _opening = null));
    return closeCount == _closeCount ? _controller : null;
  }

  /// Releases the camera, once a pending [open] has finished; [open] may
  /// start it again.
  Future<void> close() async {
    _closeCount++;
    await _opening;
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  Future<void> _initialize() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );
    try {
      await controller.initialize();
      _controller = controller;
    } catch (error) {
      _log.error('camera init failed', error);
      unawaited(controller.dispose());
    }
  }
}
