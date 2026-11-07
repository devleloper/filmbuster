import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../theme/app_theme.dart';

/// Returns the engine's current render handle, which it replaces whenever it
/// rebuilds its player.
typedef VideoControllerSource = VideoController Function();

/// The video with its subtitles; [fillsScreen] zooms the frame until it
/// covers the screen.
class PlayerVideoSurface extends StatelessWidget {
  const PlayerVideoSurface({
    super.key,
    required this.controller,
    required this.aspectRatio,
    required this.fillsScreen,
  });

  static const double fallbackAspectRatio = 16 / 9;
  static const double _maxCoverScale = 3;
  static const _zoomDuration = Duration(milliseconds: 260);

  final VideoController controller;

  /// Width over height of the video, null until the engine reports it.
  final double? aspectRatio;
  final bool fillsScreen;

  double _coverScale(Size screen) {
    final video = aspectRatio ?? fallbackAspectRatio;
    final container = screen.height == 0
        ? fallbackAspectRatio
        : screen.width / screen.height;
    final ratio = video / container;
    return (ratio > 1 ? ratio : 1 / ratio).clamp(1, _maxCoverScale);
  }

  @override
  Widget build(BuildContext context) {
    final scale = fillsScreen ? _coverScale(MediaQuery.sizeOf(context)) : 1.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: AnimatedScale(
            scale: scale,
            duration: AppMotion.of(context, _zoomDuration),
            curve: Curves.easeOutCubic,
            child: Video(
              controller: controller,
              controls: null,
              fill: AppColors.black,
              subtitleViewConfiguration: const SubtitleViewConfiguration(
                visible: false,
              ),
            ),
          ),
        ),
        // Drawn outside the zoom so subtitles stay on screen in cover mode.
        SubtitleView(
          controller: controller,
          configuration: const SubtitleViewConfiguration(),
        ),
      ],
    );
  }
}
