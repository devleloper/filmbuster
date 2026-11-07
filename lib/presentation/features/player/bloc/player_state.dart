import 'package:equatable/equatable.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../domain/models/player_source.dart';
import '../models/playback_status.dart';
import '../models/player_tracks.dart';

class PlayerState extends Equatable {
  const PlayerState({
    this.loading = true,
    this.failure,
    this.playback,
    this.tracks = PlayerTracks.empty,
    this.currentSource,
    this.isSwitchingQuality = false,
    this.isSeekBuffering = false,
    this.pendingSeekTarget,
    this.engineGeneration = 0,
    this.fillsScreen = false,
    this.artworkPath,
    this.movieTitle,
    this.sources = const [],
    this.notice,
    this.noticeId = 0,
  });

  final bool loading;
  final AppFailure? failure;
  final PlaybackStatus? playback;
  final PlayerTracks tracks;
  final PlayerSource? currentSource;
  final bool isSwitchingQuality;

  /// A seek or a stream rebuild is in progress.
  final bool isSeekBuffering;

  /// Where the viewer asked to seek, until playback gets there.
  final Duration? pendingSeekTarget;

  /// Changes whenever the engine replaces its player, and with it the
  /// render handle.
  final int engineGeneration;

  final bool fillsScreen;

  final String? artworkPath;
  final String? movieTitle;
  final List<PlayerSource> sources;

  /// A one-off message for the viewer.
  final String? notice;

  /// Grows with every notice set through [copyWith], so a repeated message
  /// shows again.
  final int noticeId;

  bool get hasVideo => playback != null;

  /// Ignores playback progress, which only moves the controls.
  bool sameSurfaceAs(PlayerState other) =>
      loading == other.loading &&
      failure == other.failure &&
      hasVideo == other.hasVideo &&
      engineGeneration == other.engineGeneration &&
      fillsScreen == other.fillsScreen &&
      isSeekBuffering == other.isSeekBuffering &&
      playback?.aspectRatio == other.playback?.aspectRatio;

  @override
  List<Object?> get props => [
    loading,
    failure,
    playback,
    tracks,
    currentSource,
    isSwitchingQuality,
    isSeekBuffering,
    pendingSeekTarget,
    engineGeneration,
    fillsScreen,
    artworkPath,
    movieTitle,
    sources,
    notice,
    noticeId,
  ];

  PlayerState copyWith({
    bool? loading,
    AppFailure? failure,
    bool clearFailure = false,
    PlaybackStatus? playback,
    PlayerTracks? tracks,
    PlayerSource? currentSource,
    bool? isSwitchingQuality,
    bool? isSeekBuffering,
    Duration? pendingSeekTarget,
    bool clearPendingSeekTarget = false,
    int? engineGeneration,
    bool? fillsScreen,
    String? notice,
  }) {
    return PlayerState(
      loading: loading ?? this.loading,
      failure: clearFailure ? null : (failure ?? this.failure),
      playback: playback ?? this.playback,
      tracks: tracks ?? this.tracks,
      currentSource: currentSource ?? this.currentSource,
      isSwitchingQuality: isSwitchingQuality ?? this.isSwitchingQuality,
      isSeekBuffering: isSeekBuffering ?? this.isSeekBuffering,
      pendingSeekTarget: clearPendingSeekTarget
          ? null
          : (pendingSeekTarget ?? this.pendingSeekTarget),
      engineGeneration: engineGeneration ?? this.engineGeneration,
      fillsScreen: fillsScreen ?? this.fillsScreen,
      artworkPath: artworkPath,
      movieTitle: movieTitle,
      sources: sources,
      notice: notice ?? this.notice,
      noticeId: notice == null ? noticeId : noticeId + 1,
    );
  }
}
