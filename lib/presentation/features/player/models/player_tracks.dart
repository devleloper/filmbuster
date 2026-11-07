import 'package:equatable/equatable.dart';

/// An audio or subtitle track of the open media.
class MediaTrack extends Equatable {
  const MediaTrack({required this.id, this.title, this.language});

  final String id;
  final String? title;
  final String? language;

  @override
  List<Object?> get props => [id, title, language];
}

class PlayerTracks extends Equatable {
  const PlayerTracks({
    this.audio = const [],
    this.subtitles = const [],
    this.audioId,
    this.subtitleId,
    this.subtitlesOff = false,
  });

  static const PlayerTracks empty = PlayerTracks();

  final List<MediaTrack> audio;
  final List<MediaTrack> subtitles;

  /// The audio track the viewer picked, or null while the engine chooses.
  final String? audioId;

  /// The subtitle track the viewer picked, or null while the engine chooses
  /// or when [subtitlesOff] is set.
  final String? subtitleId;
  final bool subtitlesOff;

  @override
  List<Object?> get props => [
    audio,
    subtitles,
    audioId,
    subtitleId,
    subtitlesOff,
  ];
}
