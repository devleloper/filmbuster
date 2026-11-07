import '../../../../domain/models/player_source.dart';

/// What the viewer asks of the player through its controls.
abstract interface class PlayerCommands {
  void back();

  /// Loads the source again after playback failed.
  void retry();

  void togglePlayPause();

  void seekTo(Duration target);

  /// Skips [seconds] forward, or back when negative.
  void seekBy(int seconds);

  void selectQuality(PlayerSource source);

  void selectAudioTrack(String id);

  /// Shows the subtitle track [id], or turns subtitles off when it is null.
  void selectSubtitleTrack(String? id);

  void setFillsScreen(bool fillsScreen);

  void enterVr();
}
