import 'package:equatable/equatable.dart';

import '../../../../domain/models/player_source.dart';
import '../models/playback_status.dart';
import '../models/player_tracks.dart';

sealed class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => const [];
}

class PlayerStarted extends PlayerEvent {
  const PlayerStarted();
}

class PlayerRetryRequested extends PlayerEvent {
  const PlayerRetryRequested();
}

class PlayerPlayPauseToggled extends PlayerEvent {
  const PlayerPlayPauseToggled();
}

class PlayerSeekRequested extends PlayerEvent {
  const PlayerSeekRequested(this.target);

  final Duration target;

  @override
  List<Object?> get props => [target];
}

class PlayerRelativeSeekRequested extends PlayerEvent {
  const PlayerRelativeSeekRequested(this.seconds);

  final int seconds;

  @override
  List<Object?> get props => [seconds];
}

/// Commits the target that a burst of relative seeks has built up.
class PlayerSeekCommitRequested extends PlayerEvent {
  const PlayerSeekCommitRequested();
}

class PlayerStallRecoveryRequested extends PlayerEvent {
  const PlayerStallRecoveryRequested();
}

class PlayerQualitySwitchRequested extends PlayerEvent {
  const PlayerQualitySwitchRequested(this.source);

  final PlayerSource source;

  @override
  List<Object?> get props => [source];
}

class PlayerAudioTrackSelected extends PlayerEvent {
  const PlayerAudioTrackSelected(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Shows the subtitle track [id], or turns subtitles off when it is null.
class PlayerSubtitleTrackSelected extends PlayerEvent {
  const PlayerSubtitleTrackSelected(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

class PlayerFillScreenChanged extends PlayerEvent {
  const PlayerFillScreenChanged(this.fillsScreen);

  final bool fillsScreen;

  @override
  List<Object?> get props => [fillsScreen];
}

class PlayerPlaybackStatusChanged extends PlayerEvent {
  const PlayerPlaybackStatusChanged(this.status);

  final PlaybackStatus status;

  @override
  List<Object?> get props => [status];
}

class PlayerTracksChanged extends PlayerEvent {
  const PlayerTracksChanged(this.tracks);

  final PlayerTracks tracks;

  @override
  List<Object?> get props => [tracks];
}
