import 'package:flutter/material.dart';

import '../../../../domain/models/player_source.dart';
import '../../../theme/app_durations.dart';
import '../models/seek_steps.dart';
import 'overlay/overlay_visibility_controller.dart';
import 'overlay/player_bottom_controls.dart';
import 'overlay/player_center_control.dart';
import 'overlay/player_keyboard_controls.dart';
import 'overlay/player_overlay_data.dart';
import 'overlay/player_surface_gestures.dart';
import 'overlay/player_top_controls.dart';
import 'player_commands.dart';
import 'seek_indicator.dart';

/// Controls over the video that fade out when idle, plus the surface
/// gestures (double tap to skip, pinch to fill) and the player's keys.
class PlayerOverlay extends StatefulWidget {
  const PlayerOverlay({super.key, required this.data, required this.commands});

  final PlayerOverlayData data;
  final PlayerCommands commands;

  @override
  State<PlayerOverlay> createState() => _PlayerOverlayState();
}

class _PlayerOverlayState extends State<PlayerOverlay>
    with SingleTickerProviderStateMixin {
  late final OverlayVisibilityController _visibility;
  late final AnimationController _fade;
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _fade,
    curve: Curves.easeInOut,
  );
  late final PlayerCommands _controlCommands = _ControlCommands(
    () => widget.commands,
    onPlayPause: _togglePlayPause,
    onSeekBy: _seekBy,
  );
  final FocusNode _focusNode = FocusNode();
  final FocusNode _centerPlayPauseFocusNode = FocusNode();
  final GlobalKey _bottomControlsKey = GlobalKey();

  int? _indicatedSeconds;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: AppDurations.medium)
      ..addStatusListener(_onFadeStatusChanged)
      ..forward();
    _visibility = OverlayVisibilityController()
      ..addListener(_onVisibilityChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Controls that fade out leave a screen reader with nothing to focus.
    _visibility.pinned = MediaQuery.accessibleNavigationOf(context);
  }

  @override
  void dispose() {
    _visibility
      ..removeListener(_onVisibilityChanged)
      ..dispose();
    _focusNode.dispose();
    _centerPlayPauseFocusNode.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _onVisibilityChanged() {
    if (_visibility.visible) {
      _fade.forward();
    } else {
      _fade.reverse();
    }
    setState(() {});
  }

  // The faded-out controls give way to the bare surface only once the fade
  // ends. While paused nothing else rebuilds the overlay, and the invisible
  // centre button would take the next tap.
  void _onFadeStatusChanged(AnimationStatus status) {
    if (!status.isDismissed || !mounted) return;
    // A focused control would take focus out of the player as it goes, and
    // the keys with it.
    if (_focusNode.hasFocus) _focusNode.requestFocus();
    setState(() {});
  }

  void _togglePlayPause() {
    widget.commands.togglePlayPause();
    _visibility.show();
  }

  void _seekBy(int seconds, {bool revealControls = true}) {
    widget.commands.seekBy(seconds);
    setState(() => _indicatedSeconds = seconds);
    if (revealControls) _visibility.show();
  }

  void _onSeekDragChanged(bool dragging) {
    if (dragging) {
      _visibility.hold();
    } else {
      _visibility.release();
    }
  }

  void _onSurfaceTap(Offset position) {
    if (!_visibility.visible || _isOnBottomControls(position)) {
      _visibility.show();
    } else {
      _visibility.hide();
    }
  }

  void _onSurfaceDoubleTap(Offset position) {
    final onLeftHalf = position.dx < MediaQuery.sizeOf(context).width / 2;
    _seekBy(onLeftHalf ? -skipSeconds : skipSeconds);
  }

  // The panel's height depends on breakpoint, orientation, text scale and
  // safe area, so the tap zone is the laid-out panel itself.
  bool _isOnBottomControls(Offset globalPosition) {
    final box = _bottomControlsKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return false;
    return box.size.contains(box.globalToLocal(globalPosition));
  }

  void _showControlsAndFocusPlayPause() {
    _visibility.show();
    // Controls that have faded out take the focus once they are built again.
    _centerPlayPauseFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final indicator = switch (_indicatedSeconds) {
      final seconds? => SeekIndicator(
        seconds: seconds,
        onAnimationComplete: () {
          if (mounted) setState(() => _indicatedSeconds = null);
        },
      ),
      null => null,
    };
    final controlsGone = !_visibility.visible && _fade.isDismissed;

    return PlayerKeyboardControls(
      focusNode: _focusNode,
      onPlayPause: _controlCommands.togglePlayPause,
      onBack: _controlCommands.back,
      onSeekStep: (seconds) => _seekBy(seconds, revealControls: false),
      onShowControls: _showControlsAndFocusPlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PlayerSurfaceGestures(
            onTap: _onSurfaceTap,
            onDoubleTap: _onSurfaceDoubleTap,
            onPinch: _controlCommands.setFillsScreen,
            child: controlsGone
                ? Stack(fit: StackFit.expand, children: [?indicator])
                : FadeTransition(
                    opacity: _opacity,
                    child: _controls(indicator),
                  ),
          ),
          // Hidden or fading controls have no semantics left. This node has
          // no hit area, so pointer taps still reach the surface.
          if (!_visibility.visible)
            Semantics(
              container: true,
              button: true,
              label: 'Show player controls',
              onTap: _visibility.show,
              child: const SizedBox.expand(),
            ),
        ],
      ),
    );
  }

  Widget _controls(Widget? indicator) {
    final data = widget.data;
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Stack(
        children: [
          ?indicator,
          PlayerCenterControl(
            isPlaying: data.status.playing,
            onPlayPause: _controlCommands.togglePlayPause,
            focusNode: _centerPlayPauseFocusNode,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: PlayerTopControls(
              title: data.movieTitle,
              fillsScreen: data.fillsScreen,
              commands: _controlCommands,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: PlayerBottomControls(
              key: _bottomControlsKey,
              data: data,
              commands: _controlCommands,
              onSeekDragChanged: _onSeekDragChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// The player's commands as the controls send them: play/pause also keeps
/// the controls on screen, and a skip also shows how far it went.
class _ControlCommands implements PlayerCommands {
  _ControlCommands(
    this._player, {
    required VoidCallback onPlayPause,
    required ValueChanged<int> onSeekBy,
  }) : _onPlayPause = onPlayPause,
       _onSeekBy = onSeekBy;

  final PlayerCommands Function() _player;
  final VoidCallback _onPlayPause;
  final ValueChanged<int> _onSeekBy;

  @override
  void togglePlayPause() => _onPlayPause();

  @override
  void seekBy(int seconds) => _onSeekBy(seconds);

  @override
  void back() => _player().back();

  @override
  void retry() => _player().retry();

  @override
  void seekTo(Duration target) => _player().seekTo(target);

  @override
  void selectQuality(PlayerSource source) => _player().selectQuality(source);

  @override
  void selectAudioTrack(String id) => _player().selectAudioTrack(id);

  @override
  void selectSubtitleTrack(String? id) => _player().selectSubtitleTrack(id);

  @override
  void setFillsScreen(bool fillsScreen) =>
      _player().setFillsScreen(fillsScreen);

  @override
  void enterVr() => _player().enterVr();
}
