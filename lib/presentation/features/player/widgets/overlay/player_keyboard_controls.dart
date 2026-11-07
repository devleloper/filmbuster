import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../widgets/key_repeat_activator.dart';
import '../../models/seek_steps.dart';
import 'repeat_seek_controller.dart';

class _PlayPauseIntent extends Intent {
  const _PlayPauseIntent();
}

class _BackIntent extends Intent {
  const _BackIntent();
}

/// The player's keys. Enter, Space or the D-pad centre toggles playback once
/// per press and Escape goes back. While [focusNode] itself has focus, Left
/// and Right seek for as long as they are held and Up shows the controls; on
/// a focused control the arrows move focus instead.
class PlayerKeyboardControls extends StatefulWidget {
  const PlayerKeyboardControls({
    super.key,
    required this.focusNode,
    required this.onPlayPause,
    required this.onBack,
    required this.onSeekStep,
    required this.onShowControls,
    required this.child,
  });

  final FocusNode focusNode;
  final VoidCallback onPlayPause;
  final VoidCallback onBack;

  /// Gets a signed number of seconds.
  final ValueChanged<int> onSeekStep;

  final VoidCallback onShowControls;
  final Widget child;

  @override
  State<PlayerKeyboardControls> createState() => _PlayerKeyboardControlsState();
}

class _PlayerKeyboardControlsState extends State<PlayerKeyboardControls> {
  static final _playPauseKeys = {
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.gameButtonA,
  };

  // Repeats are consumed rather than ignored: macOS beeps for every unhandled
  // repeat while a key is held.
  static final _shortcuts = <ShortcutActivator, Intent>{
    for (final key in _playPauseKeys) ...{
      SingleActivator(key, includeRepeats: false): const _PlayPauseIntent(),
      KeyRepeatActivator(key): const DoNothingIntent(),
    },
    const SingleActivator(LogicalKeyboardKey.escape): const _BackIntent(),
    const SingleActivator(LogicalKeyboardKey.goBack): const _BackIntent(),
  };

  late final RepeatSeekController _repeatSeek = RepeatSeekController(
    onSeekStep: (seconds) => widget.onSeekStep(seconds),
  );

  @override
  void dispose() {
    _repeatSeek.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final seekDirection = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      _ => null,
    };
    if (seekDirection != null && event is KeyUpEvent) _repeatSeek.stop();
    if (!node.hasPrimaryFocus) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (event is KeyDownEvent) widget.onShowControls();
      return KeyEventResult.handled;
    }
    if (seekDirection == null) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      widget.onSeekStep(seekDirection * arrowSeekSeconds);
      _repeatSeek.start(seekDirection);
    }
    // Key repeats need nothing: the controller seeks until the key is up.
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _PlayPauseIntent: CallbackAction<_PlayPauseIntent>(
            onInvoke: (_) {
              _repeatSeek.stop();
              widget.onPlayPause();
              return null;
            },
          ),
          _BackIntent: CallbackAction<_BackIntent>(
            onInvoke: (_) {
              widget.onBack();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: widget.focusNode,
          autofocus: true,
          onKeyEvent: _onKeyEvent,
          child: widget.child,
        ),
      ),
    );
  }
}
