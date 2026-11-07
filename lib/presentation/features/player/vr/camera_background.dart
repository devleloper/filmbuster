import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import 'services/vr_camera.dart';

/// The camera feed filling the scene, darkened by [dimming] (0 to 1).
class CameraBackground extends StatelessWidget {
  const CameraBackground({
    super.key,
    required this.controller,
    required this.dimming,
  });

  final CameraController controller;
  final double dimming;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _CameraFeed(controller),
        AnimatedContainer(
          duration: AppMotion.of(context, AppDurations.medium),
          curve: Curves.easeOut,
          color: AppColors.black.withValues(alpha: dimming),
        ),
      ],
    );
  }
}

/// A small live view of [camera], which it opens.
class CameraPreviewThumbnail extends StatefulWidget {
  const CameraPreviewThumbnail({super.key, required this.camera});

  final VrCamera camera;

  @override
  State<CameraPreviewThumbnail> createState() => _CameraPreviewThumbnailState();
}

class _CameraPreviewThumbnailState extends State<CameraPreviewThumbnail> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final controller = await widget.camera.open();
    if (mounted) setState(() => _controller = controller);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const ColoredBox(
        color: AppColors.surface,
        child: Center(
          child: Icon(Icons.videocam, color: AppColors.textDisabled, size: 24),
        ),
      );
    }
    return ClipRRect(
      borderRadius: AppRadius.smAll,
      child: _CameraFeed(controller),
    );
  }
}

class _CameraFeed extends StatelessWidget {
  const _CameraFeed(this.controller);

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    // The preview size is reported in sensor orientation, which is
    // landscape; the swap gives the portrait box the preview is drawn in.
    final previewSize = controller.value.previewSize!;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: previewSize.height,
        height: previewSize.width,
        child: CameraPreview(controller),
      ),
    );
  }
}
