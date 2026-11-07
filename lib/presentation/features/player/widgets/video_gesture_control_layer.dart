import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../../theme/app_theme.dart';
import 'glass_slider_indicator.dart';

/// Vertical drags along the left edge change the screen brightness, along
/// the right edge the volume. [child] gets every other gesture.
class VideoGestureControlLayer extends StatefulWidget {
  const VideoGestureControlLayer({super.key, required this.child});

  final Widget child;

  @override
  State<VideoGestureControlLayer> createState() =>
      _VideoGestureControlLayerState();
}

enum _Level { brightness, volume }

class _VideoGestureControlLayerState extends State<VideoGestureControlLayer> {
  static const double _edgeZoneWidthFraction = 0.3;

  static const double _dragDistanceForFullRange = 200;
  static const double _indicatorInset = 36;
  static const _lingerAfterDrag = Duration(milliseconds: 800);

  static const double _unknownLevel = 0.5;

  final ValueNotifier<_Level?> _adjustedLevel = ValueNotifier(null);
  final ValueNotifier<double> _value = ValueNotifier(_unknownLevel);
  final ValueNotifier<bool> _fading = ValueNotifier(false);
  Timer? _hideTimer;

  // Set once the dragged level has been read: updates that arrive earlier
  // would write a stale value.
  _Level? _loadedLevel;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _adjustedLevel.dispose();
    _value.dispose();
    _fading.dispose();
    super.dispose();
  }

  Future<void> _onDragStart(_Level level) async {
    _hideTimer?.cancel();
    _loadedLevel = null;
    final value = await _readLevel(level);
    if (!mounted) return;
    _loadedLevel = level;
    _value.value = value;
    _fading.value = false;
    _adjustedLevel.value = level;
  }

  void _onDragUpdate(_Level level, DragUpdateDetails details) {
    if (_loadedLevel != level) return;
    final value = (_value.value - details.delta.dy / _dragDistanceForFullRange)
        .clamp(0.0, 1.0);
    _value.value = value;
    unawaited(_writeLevel(level, value));
  }

  void _onDragEnd() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_lingerAfterDrag, () => _fading.value = true);
  }

  void _onFadeEnd() {
    if (!_fading.value) return;
    _adjustedLevel.value = null;
    _fading.value = false;
  }

  static Future<double> _readLevel(_Level level) async {
    try {
      final value = switch (level) {
        _Level.brightness => await ScreenBrightness.instance.application,
        _Level.volume =>
          await FlutterVolumeController.getVolume() ?? _unknownLevel,
      };
      return value.isNaN || value < 0 || value > 1 ? _unknownLevel : value;
    } catch (_) {
      return _unknownLevel;
    }
  }

  static Future<void> _writeLevel(_Level level, double value) async {
    try {
      switch (level) {
        case _Level.brightness:
          await ScreenBrightness.instance.setApplicationScreenBrightness(value);
        case _Level.volume:
          await FlutterVolumeController.setVolume(value);
      }
    } catch (_) {
      // Platforms without these controls ignore the drag.
    }
  }

  Widget _dragZone(_Level level) {
    return GestureDetector(
      onVerticalDragStart: (_) => _onDragStart(level),
      onVerticalDragUpdate: (details) => _onDragUpdate(level, details),
      onVerticalDragEnd: (_) => _onDragEnd(),
      behavior: HitTestBehavior.translucent,
      child: const SizedBox.expand(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zoneWidth = MediaQuery.sizeOf(context).width * _edgeZoneWidthFraction;

    return ValueListenableBuilder<_Level?>(
      valueListenable: _adjustedLevel,
      builder: (context, active, _) => Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(ignoring: active != null, child: widget.child),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: zoneWidth,
            child: _dragZone(_Level.brightness),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: zoneWidth,
            child: _dragZone(_Level.volume),
          ),
          if (active != null)
            Positioned(
              left: active == _Level.brightness ? _indicatorInset : null,
              right: active == _Level.volume ? _indicatorInset : null,
              top: 0,
              bottom: 0,
              child: ValueListenableBuilder<bool>(
                valueListenable: _fading,
                builder: (context, fading, child) => AnimatedOpacity(
                  opacity: fading ? 0 : 1,
                  duration: AppDurations.fast,
                  curve: fading ? Curves.easeIn : Curves.easeOut,
                  onEnd: _onFadeEnd,
                  child: child,
                ),
                child: Center(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _value,
                    builder: (context, value, _) =>
                        _LevelIndicator(level: active, value: value),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelIndicator extends StatelessWidget {
  const _LevelIndicator({required this.level, required this.value});

  final _Level level;
  final double value;

  @override
  Widget build(BuildContext context) {
    final bar = GlassSliderIndicator(value: value);
    final icon = Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.scrimSoft,
        shape: BoxShape.circle,
        boxShadow: AppShadows.overVideo,
      ),
      child: Icon(
        level == _Level.brightness ? Icons.wb_sunny : Icons.volume_up,
        color: AppColors.white,
        size: 24,
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: level == _Level.brightness
          ? [bar, const SizedBox(width: AppSpacing.md), icon]
          : [icon, const SizedBox(width: AppSpacing.md), bar],
    );
  }
}
