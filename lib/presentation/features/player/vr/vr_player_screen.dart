import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/feedback/app_loading_indicator.dart';
import '../../../widgets/feedback/status_views.dart';
import '../bloc/player_bloc.dart';
import '../bloc/player_state.dart';
import '../models/seek_steps.dart';
import '../widgets/player_commands.dart';
import '../widgets/player_video_surface.dart';
import 'camera_background.dart';
import 'per_eye.dart';
import 'services/head_gesture_detector.dart';
import 'services/head_tracker.dart';
import 'services/vr_camera.dart';
import 'stereo_viewport.dart';
import 'vr_action_indicator.dart';
import 'vr_exit_progress.dart';
import 'vr_headset_mode.dart';
import 'vr_mode_selection.dart';

/// Side-by-side stereo playback for a phone in a headset. Head gestures
/// control playback; on screen, a tap cycles the camera dimming, a double
/// tap recenters and restores the screen size, pinching resizes the screen
/// and a long press exits.
class VrPlayerScreen extends StatefulWidget {
  const VrPlayerScreen({
    super.key,
    required this.selection,
    required this.camera,
    required this.headTracker,
    required this.commands,
    required this.videoController,
  });

  final VrModeSelection selection;

  /// Feeds the spatial scene.
  final VrCamera camera;

  final HeadTracker headTracker;

  final PlayerCommands commands;

  final VideoControllerSource videoController;

  @override
  State<VrPlayerScreen> createState() => _VrPlayerScreenState();
}

typedef _VrAction = ({IconData icon, String label});

class _VrPlayerScreenState extends State<VrPlayerScreen>
    with SingleTickerProviderStateMixin {
  static const _holdToExit = Duration(milliseconds: 1200);
  static const _minVideoScale = 0.5;
  static const _maxVideoScale = 2.5;

  final HeadGestureDetector _headGestures = HeadGestureDetector();
  late final StreamSubscription<HeadGesture> _gestureSubscription;
  late final AnimationController _exitProgress;
  CameraController? _cameraFeed;
  late double _dimming = widget.selection.spatialDimming;

  _VrAction? _action;
  int _actionCount = 0;

  double _videoScale = 1;
  double _videoScaleAtPinchStart = 1;

  @override
  void initState() {
    super.initState();
    _gestureSubscription = _headGestures.gestureStream.listen(_onHeadGesture);
    _exitProgress = AnimationController(vsync: this, duration: _holdToExit)
      ..addStatusListener((status) {
        if (status.isCompleted) _exit();
      });

    if (widget.selection.mode == VrMode.spatial) _openCamera();
  }

  Future<void> _openCamera() async {
    final feed = await widget.camera.open();
    if (mounted) setState(() => _cameraFeed = feed);
  }

  @override
  void dispose() {
    _exitProgress.dispose();
    _gestureSubscription.cancel();
    _headGestures.dispose();
    super.dispose();
  }

  void _showAction(IconData icon, String label) {
    setState(() {
      _action = (icon: icon, label: label);
      _actionCount++;
    });
  }

  void _onHeadGesture(HeadGesture gesture) {
    final commands = widget.commands;
    HapticFeedback.mediumImpact();

    switch (gesture) {
      case HeadGesture.togglePlay:
        final playing =
            context.read<PlayerBloc>().state.playback?.playing ?? false;
        commands.togglePlayPause();
        if (playing) {
          _showAction(Icons.pause_rounded, 'Pause');
        } else {
          _showAction(Icons.play_arrow_rounded, 'Play');
        }
      case HeadGesture.seekForward:
        commands.seekBy(skipSeconds);
        _showAction(Icons.forward_10_rounded, '+${skipSeconds}s');
      case HeadGesture.seekBackward:
        commands.seekBy(-skipSeconds);
        _showAction(Icons.replay_10_rounded, '-${skipSeconds}s');
      case HeadGesture.recenter:
        _recenter();
    }
  }

  void _recenter() {
    widget.headTracker.resetOrientation();
    _showAction(Icons.center_focus_strong_rounded, 'Recenter');
  }

  void _restoreScreenSize() {
    setState(() {
      _videoScale = 1;
      _videoScaleAtPinchStart = 1;
    });
  }

  void _cycleDimming() {
    if (widget.selection.mode != VrMode.spatial) return;

    final next = VrModeSelection.nextDimmingStep(_dimming);
    setState(() => _dimming = next);
    _showAction(
      next > 0 ? Icons.brightness_medium : Icons.brightness_high,
      'Dim: ${(next * 100).round()}%',
    );
    HapticFeedback.selectionClick();
  }

  void _exit() {
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.pop(context);
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount == 2) _videoScaleAtPinchStart = _videoScale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount != 2) return;
    setState(() {
      _videoScale = (_videoScaleAtPinchStart * details.scale).clamp(
        _minVideoScale,
        _maxVideoScale,
      );
    });
  }

  void _cancelExit() {
    if (_exitProgress.isAnimating) _exitProgress.reset();
  }

  @override
  Widget build(BuildContext context) {
    return VrHeadsetMode(
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onTap: _cycleDimming,
        onDoubleTap: () {
          _restoreScreenSize();
          _recenter();
          HapticFeedback.lightImpact();
        },
        onLongPressStart: (_) => _exitProgress.forward(),
        onLongPressEnd: (_) => _cancelExit(),
        onLongPressCancel: _cancelExit,
        behavior: HitTestBehavior.opaque,
        child: BlocBuilder<PlayerBloc, PlayerState>(
          buildWhen: (previous, current) => !current.sameSurfaceAs(previous),
          builder: (context, state) {
            if (state.failure case final failure?) {
              return ErrorStateView(
                title: 'Playback error',
                message: failure.message,
                onBack: () => Navigator.pop(context),
              );
            }
            final playback = state.playback;
            if (state.loading || playback == null) {
              return const Center(child: AppLoadingIndicator());
            }
            return _scene(
              widget.videoController(),
              playback.aspectRatio ?? PlayerVideoSurface.fallbackAspectRatio,
            );
          },
        ),
      ),
    );
  }

  Widget _scene(VideoController controller, double aspectRatio) {
    final cameraFeed = _cameraFeed;
    final action = _action;

    Widget screen(BoxFit fit) => Transform.scale(
      scale: _videoScale,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Video(
          controller: controller,
          fill: AppColors.transparent,
          fit: fit,
          controls: null,
          subtitleViewConfiguration: const SubtitleViewConfiguration(
            visible: false,
          ),
        ),
      ),
    );

    return StreamBuilder<Matrix4>(
      stream: widget.headTracker.viewMatrix,
      initialData: Matrix4.identity(),
      builder: (context, snapshot) => Stack(
        children: [
          Positioned.fill(
            child: StereoViewport(
              headMatrix: snapshot.requireData,
              glowChild: screen(BoxFit.cover),
              backgroundBuilder:
                  cameraFeed != null && cameraFeed.value.isInitialized
                  ? (_) => CameraBackground(
                      dimming: _dimming,
                      controller: cameraFeed,
                    )
                  : null,
              child: screen(BoxFit.contain),
            ),
          ),
          PerEye(
            bottom: AppSpacing.xxxl + AppSpacing.sm,
            builder: (_) => SubtitleView(
              controller: controller,
              configuration: _subtitleStyle,
            ),
          ),
          if (action != null)
            PerEye(
              builder: (isLeftEye) => Center(
                child: VrActionIndicator(
                  key: ValueKey((_actionCount, isLeftEye)),
                  icon: action.icon,
                  label: action.label,
                  onComplete: () {
                    if (isLeftEye && mounted) setState(() => _action = null);
                  },
                ),
              ),
            ),
          PerEye(builder: (_) => Center(child: VrExitProgress(_exitProgress))),
        ],
      ),
    );
  }

  static const _subtitleStyle = SubtitleViewConfiguration(
    style: TextStyle(
      color: AppColors.white,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      shadows: [
        Shadow(offset: Offset(1, 1), blurRadius: 4, color: AppColors.black),
        Shadow(offset: Offset(-1, -1), blurRadius: 4, color: AppColors.black),
      ],
    ),
    textAlign: TextAlign.center,
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  );
}
