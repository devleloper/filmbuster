import 'package:equatable/equatable.dart';

import '../../domain/models/player_source.dart';

class PlayerRouteArgs extends Equatable {
  const PlayerRouteArgs({
    required this.source,
    this.sources = const [],
    this.movieTitle,
    this.artworkPath,
  });

  final PlayerSource source;

  /// Every playable source of the movie, offered as quality options.
  final List<PlayerSource> sources;

  final String? movieTitle;

  /// The movie's backdrop or poster, shown while the viewer seeks.
  final String? artworkPath;

  @override
  List<Object?> get props => [source, sources, movieTitle, artworkPath];
}
