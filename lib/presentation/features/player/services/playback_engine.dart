import 'package:media_kit_video/media_kit_video.dart';

import '../models/playback_status.dart';
import '../models/player_tracks.dart';

/// Plays one stream at a time. [statusChanges] and [trackChanges] outlive
/// [recreateAt]; calls carry no deadlines, the caller decides how long to wait.
abstract interface class PlaybackEngine {
  /// Render handle for the `Video` widget; changes with [generation].
  VideoController get controller;

  /// Counts [recreateAt] calls.
  int get generation;

  bool get isCreated;

  PlaybackStatus get status;

  Stream<PlaybackStatus> get statusChanges;

  Stream<PlayerTracks> get trackChanges;

  void create();

  Future<void> open(String url, {Duration start = Duration.zero});

  Future<void> seek(Duration target);

  Future<void> play();

  Future<void> pause();

  Future<void> selectAudioTrack(String id);

  /// Shows the subtitle track [id], or none when [id] is null.
  Future<void> selectSubtitleTrack(String? id);

  /// Makes the stream reconnect on network errors instead of ending
  /// playback. Applies once per player, after the first frames arrive.
  Future<void> hardenForStreaming();

  /// Replaces a player that stopped responding with a new one that opens
  /// [url] at [position]. Listeners get [PlaybackStatus.empty] before the
  /// new player's values.
  Future<void> recreateAt(String url, Duration position);

  Future<void> dispose();
}
