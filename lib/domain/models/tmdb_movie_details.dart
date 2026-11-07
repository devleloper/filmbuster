import 'package:equatable/equatable.dart';

import 'json_parsing.dart';
import 'release_year.dart';
import 'tmdb_credit_person.dart';
import 'tmdb_movie.dart';
import 'tmdb_trailer.dart';

/// Everything the Detail screen shows about one movie.
class TmdbMovieDetails extends Equatable {
  const TmdbMovieDetails({
    required this.id,
    required this.title,
    this.overview,
    this.releaseDate,
    this.voteAverage,
    this.posterPath,
    this.backdropPath,
    this.genres = const [],
    this.runtime,
    this.cast = const [],
    this.crew = const [],
    this.similar = const [],
    this.trailers = const [],
  });

  final int id;
  final String title;
  final String? overview;
  final String? releaseDate;
  final double? voteAverage;
  final String? posterPath;
  final String? backdropPath;
  final List<String> genres;
  final int? runtime;
  final List<TmdbCreditPerson> cast;
  final List<TmdbCreditPerson> crew;
  final List<TmdbMovie> similar;

  /// Official trailers and teasers, best first.
  final List<TmdbTrailer> trailers;

  int? get releaseYear => releaseYearOf(releaseDate);

  /// Absent collections parse as empty; a collection of the wrong shape throws.
  factory TmdbMovieDetails.fromJson(Map<String, dynamic> json) {
    final credits = json['credits'] as Map<String, dynamic>?;

    return TmdbMovieDetails(
      id: json['id'] as int,
      title: json['title'] as String,
      overview: json['overview'] as String?,
      releaseDate: json['releaseDate'] as String?,
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      genres: (json['genres'] as List<dynamic>? ?? const [])
          .cast<String>()
          .toList(growable: false),
      runtime: json['runtime'] as int?,
      cast: _optionalList(credits?['cast'], TmdbCreditPerson.fromJson),
      crew: _optionalList(credits?['crew'], TmdbCreditPerson.fromJson),
      similar: _optionalList(json['similar'], TmdbMovie.fromJson),
      trailers: _optionalList(json['trailers'], TmdbTrailer.fromJson),
    );
  }

  static List<T> _optionalList<T>(
    Object? raw,
    T Function(Map<String, dynamic> json) fromJson,
  ) => parseJsonList(raw, fromJson, nullAsEmpty: true);

  Iterable<TmdbCreditPerson> get credits => cast.followedBy(crew);

  TmdbMovie toSummary() => TmdbMovie(
    id: id,
    title: title,
    posterPath: posterPath,
    backdropPath: backdropPath,
    voteAverage: voteAverage,
    releaseDate: releaseDate,
    overview: overview,
  );

  TmdbMovieDetails copyWith({
    List<TmdbMovie>? similar,
    List<TmdbTrailer>? trailers,
  }) => TmdbMovieDetails(
    id: id,
    title: title,
    overview: overview,
    releaseDate: releaseDate,
    voteAverage: voteAverage,
    posterPath: posterPath,
    backdropPath: backdropPath,
    genres: genres,
    runtime: runtime,
    cast: cast,
    crew: crew,
    similar: similar ?? this.similar,
    trailers: trailers ?? this.trailers,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    overview,
    releaseDate,
    voteAverage,
    posterPath,
    backdropPath,
    genres,
    runtime,
    cast,
    crew,
    similar,
    trailers,
  ];
}
