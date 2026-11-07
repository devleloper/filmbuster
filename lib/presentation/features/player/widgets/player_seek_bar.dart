import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_slider.dart';
import '../../../widgets/media_image.dart';
import '../models/playback_status.dart';
import '../utils/duration_format.dart';

/// While the thumb is dragged or an arrow key is held, a preview shows the
/// time it would seek to; the seek happens on release.
class PlayerSeekBar extends StatefulWidget {
  const PlayerSeekBar({
    super.key,
    required this.status,
    required this.onSeek,
    this.pendingTarget,
    this.artworkPath,
    this.onSeekDragChanged,
    this.scaleFactor = 1.0,
  });

  final PlaybackStatus status;
  final ValueChanged<Duration> onSeek;

  /// A requested position that playback has not reached yet; shown instead
  /// of the current one.
  final Duration? pendingTarget;

  final String? artworkPath;

  final ValueChanged<bool>? onSeekDragChanged;
  final double scaleFactor;

  @override
  State<PlayerSeekBar> createState() => _PlayerSeekBarState();
}

class _PlayerSeekBarState extends State<PlayerSeekBar> {
  static const double _keyboardStep = 0.02;

  double? _draggedFraction;

  Duration get _duration => widget.status.duration;

  double? _fractionOf(Duration? position) {
    final total = _duration.inMilliseconds;
    if (position == null || total <= 0) return null;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  double get _sliderValue =>
      _draggedFraction ??
      _fractionOf(widget.pendingTarget) ??
      _fractionOf(widget.status.position) ??
      0;

  Duration _positionAt(double fraction) {
    final total = _duration.inSeconds;
    if (total <= 0) return widget.status.position;
    return Duration(seconds: (fraction * total).round().clamp(0, total));
  }

  void _onChangeStart(double value) {
    setState(() => _draggedFraction = value);
    widget.onSeekDragChanged?.call(true);
  }

  void _onChangeEnd(double value) {
    setState(() => _draggedFraction = null);
    widget.onSeekDragChanged?.call(false);
    widget.onSeek(_positionAt(value));
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scaleFactor;
    final thumbRadius = (8 * scale).clamp(6.0, 14.0);
    // AppSlider centres its track in a box of
    // max(2 * thumbRadius, kMinInteractiveDimension), and that box sizes this
    // Stack. The preview is anchored to the track centre, not the box
    // bottom, so the larger hit area never moves it onto the thumb.
    final trackCentre = math.max(thumbRadius, kMinInteractiveDimension / 2);
    final dragValue = _draggedFraction;

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        clipBehavior: Clip.none,
        children: [
          AppSlider(
            value: _sliderValue,
            secondaryValue: _fractionOf(widget.status.buffer),
            keyboardStep: _keyboardStep,
            trackHeight: (4 * scale).clamp(2.0, 8.0),
            thumbRadius: thumbRadius,
            semanticLabel: 'Seek',
            onChangeStart: _onChangeStart,
            onChanged: (value) => setState(() => _draggedFraction = value),
            onChangeEnd: _onChangeEnd,
          ),
          if (dragValue != null)
            Positioned(
              left:
                  constraints.maxWidth * dragValue -
                  _ThumbnailPreview.widthFor(scale) / 2,
              bottom: trackCentre + _previewGap(scale),
              child: _ThumbnailPreview(
                timestamp: formatPlaybackDuration(_positionAt(dragValue)),
                artworkPath: widget.artworkPath,
                scaleFactor: scale,
              ),
            ),
        ],
      ),
    );
  }

  static double _previewGap(double scale) => 18 * scale;
}

class _ThumbnailPreview extends StatelessWidget {
  const _ThumbnailPreview({
    required this.timestamp,
    required this.artworkPath,
    required this.scaleFactor,
  });

  static double widthFor(double scale) => (200 * scale).roundToDouble();

  final String timestamp;
  final String? artworkPath;
  final double scaleFactor;

  @override
  Widget build(BuildContext context) {
    final width = widthFor(scaleFactor);
    final height = (120 * scaleFactor).roundToDouble();
    final radius = BorderRadius.circular(AppRadius.sm * scaleFactor);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.scrimHeavy,
        borderRadius: radius,
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.borderStrong),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: radius,
            // Dimmed by blending, which is cheaper than an Opacity layer
            // redrawn on every drag frame.
            child: MediaImage.backdrop(
              path: artworkPath,
              width: width,
              height: height,
              color: AppColors.white.withValues(alpha: 0.3),
              colorBlendMode: BlendMode.modulate,
              placeholder: const SizedBox.shrink(),
              fallback: const SizedBox.shrink(),
            ),
          ),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: (AppSpacing.md * scaleFactor).roundToDouble(),
                vertical: (AppSpacing.sm * scaleFactor).roundToDouble(),
              ),
              decoration: BoxDecoration(
                color: AppColors.scrimStrong,
                borderRadius: BorderRadius.circular(AppRadius.sm * scaleFactor),
              ),
              child: Text(
                timestamp,
                style: AppTextStyles.base.copyWith(
                  fontSize: (18 * scaleFactor).roundToDouble(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
