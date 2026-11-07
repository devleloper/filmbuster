import 'package:equatable/equatable.dart';

import 'release_year.dart';

/// The summary of a movie shown on cards and in lists.
class TmdbMovie extends Equatable {
  const TmdbMovie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.releaseDate,
    this.overview,
    this.genreIds = const [],
  });

  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final double? voteAverage;
  final String? releaseDate;
  final String? overview;
  final List<int> genreIds;

  factory TmdbMovie.fromJson(Map<String, dynamic> json) {
    return TmdbMovie(
      id: json['id'] as int,
      title: json['title'] as String,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      releaseDate: json['releaseDate'] as String?,
      overview: json['overview'] as String?,
      genreIds: _genreIds(json['genreIds']),
    );
  }

  /// Genres only decorate a card, so malformed entries are dropped instead of
  /// failing the whole page.
  static List<int> _genreIds(Object? raw) => switch (raw) {
    final List<dynamic> ids => [
      for (final id in ids)
        if (id is num) id.toInt(),
    ],
    _ => const [],
  };

  int? get releaseYear => releaseYearOf(releaseDate);

  @override
  List<Object?> get props => [
    id,
    title,
    posterPath,
    backdropPath,
    voteAverage,
    releaseDate,
    overview,
    genreIds,
  ];
}
