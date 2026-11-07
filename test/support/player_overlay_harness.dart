import 'package:filmbuster/domain/models/player_source.dart';
import 'package:filmbuster/presentation/features/player/models/playback_status.dart';
import 'package:filmbuster/presentation/features/player/widgets/overlay/overlay_visibility_controller.dart';
import 'package:filmbuster/presentation/features/player/widgets/overlay/player_button.dart';
import 'package:filmbuster/presentation/features/player/widgets/overlay/player_overlay_data.dart';
import 'package:filmbuster/presentation/features/player/widgets/player_commands.dart';
import 'package:filmbuster/presentation/features/player/widgets/player_overlay.dart';
import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/app_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const samplePlayback = PlaybackStatus(
  position: Duration(seconds: 36),
  duration: Duration(minutes: 9, seconds: 56),
  playing: true,
);

/// [PlayerCommands] that pass the commands a test listens for to its
/// callbacks and ignore the rest.
class CallbackPlayerCommands implements PlayerCommands {
  CallbackPlayerCommands({
    this.onPlayPause,
    this.onSeekTo,
    this.onSeekBy,
    this.onAudioTrack,
    this.onSubtitleTrack,
    this.onFillsScreen,
  });

  final VoidCallback? onPlayPause;
  final ValueChanged<Duration>? onSeekTo;
  final ValueChanged<int>? onSeekBy;
  final ValueChanged<String>? onAudioTrack;
  final ValueChanged<String?>? onSubtitleTrack;
  final ValueChanged<bool>? onFillsScreen;

  @override
  void back() {}

  @override
  void retry() {}

  @override
  void togglePlayPause() => onPlayPause?.call();

  @override
  void seekTo(Duration target) => onSeekTo?.call(target);

  @override
  void seekBy(int seconds) => onSeekBy?.call(seconds);

  @override
  void selectQuality(PlayerSource source) {}

  @override
  void selectAudioTrack(String id) => onAudioTrack?.call(id);

  @override
  void selectSubtitleTrack(String? id) => onSubtitleTrack?.call(id);

  @override
  void setFillsScreen(bool fillsScreen) => onFillsScreen?.call(fillsScreen);

  @override
  void enterVr() {}
}

/// A [PlayerOverlay] for Big Buck Bunny whose commands do nothing unless
/// given.
PlayerOverlay buildOverlay({
  PlaybackStatus status = samplePlayback,
  bool fillsScreen = false,
  PlayerCommands? commands,
}) => PlayerOverlay(
  data: PlayerOverlayData(
    status: status,
    fillsScreen: fillsScreen,
    movieTitle: 'Big Buck Bunny',
  ),
  commands: commands ?? CallbackPlayerCommands(),
);

Future<void> waitForControls(WidgetTester tester) =>
    tester.pump(AppDurations.medium * 2);

/// The fade-out starts on the frame after the auto-hide timer fires, hence
/// two pumps.
Future<void> waitForAutoHide(WidgetTester tester) async {
  await tester.pump(
    OverlayVisibilityController.idleTimeout + const Duration(seconds: 1),
  );
  await tester.pump(const Duration(seconds: 1));
}

/// Focuses the seek bar, as Tab or the D-pad would.
Future<void> focusSeekBar(WidgetTester tester) async {
  final paint = find.descendant(
    of: find.byType(AppSlider),
    matching: find.byType(CustomPaint),
  );
  Focus.of(tester.element(paint.first)).requestFocus();
  await tester.pump();
}

Finder playerButton(String label) => find.byWidgetPredicate(
  (widget) => widget is PlayerButton && widget.label == label,
);

/// Focuses the bar button labelled [label], as Tab or the D-pad would.
Future<void> focusPlayerButton(WidgetTester tester, String label) async {
  final icon = find.descendant(
    of: playerButton(label),
    matching: find.byType(Icon),
  );
  Focus.of(tester.element(icon)).requestFocus();
  await tester.pump();
}
