import '../../../../../domain/models/player_source.dart';
import '../../bloc/player_state.dart';
import '../../models/playback_status.dart';
import '../../models/player_tracks.dart';

/// What the player controls show.
class PlayerOverlayData {
  const PlayerOverlayData({
    required this.status,
    this.tracks = PlayerTracks.empty,
    this.sources = const [],
    this.currentSource,
    this.isSwitchingQuality = false,
    this.fillsScreen = false,
    this.pendingSeekTarget,
    this.artworkPath,
    this.movieTitle,
  });

  /// The controls for [state], which has video once loading is over.
  PlayerOverlayData.of(PlayerState state)
    : this(
        status: state.playback!,
        tracks: state.tracks,
        sources: state.sources,
        currentSource: state.currentSource,
        isSwitchingQuality: state.isSwitchingQuality,
        fillsScreen: state.fillsScreen,
        pendingSeekTarget: state.pendingSeekTarget,
        artworkPath: state.artworkPath,
        movieTitle: state.movieTitle,
      );

  final PlaybackStatus status;
  final PlayerTracks tracks;
  final List<PlayerSource> sources;
  final PlayerSource? currentSource;
  final bool isSwitchingQuality;
  final bool fillsScreen;

  /// Where the viewer asked to seek, until playback gets there.
  final Duration? pendingSeekTarget;

  final String? artworkPath;
  final String? movieTitle;
}
