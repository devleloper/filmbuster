import 'dart:convert';

import '../../domain/models/content_license.dart';
import '../../domain/models/json_parsing.dart';
import '../../domain/models/movie_source.dart';
import '../../domain/models/open_movie.dart';
import '../../domain/models/tmdb_movie_details.dart';
import '../../domain/models/tmdb_person_details.dart';

/// The parsed `catalog.json`. Every reference is checked while parsing, so
/// a [CatalogContents] is always internally consistent.
class CatalogContents {
  const CatalogContents._({
    required this.order,
    required this.movies,
    required this.people,
    required this.openMovies,
    required this.sources,
  });

  static const int _schemaVersion = 1;
  static const String _providerId = 'bundled';
  static const String providerName = 'Open movies';

  /// Curated order of all movie ids.
  final List<int> order;
  final Map<int, TmdbMovieDetails> movies;
  final Map<int, TmdbPersonDetails> people;
  final Map<int, OpenMovie> openMovies;
  final Map<int, List<MovieSource>> sources;

  List<TmdbMovieDetails> get ordered => [for (final id in order) movies[id]!];

  /// Throws [FormatException] or [TypeError] for any schema violation.
  factory CatalogContents.parse(String raw) {
    final json = parseJsonObject(jsonDecode(raw));
    final version = json['schemaVersion'] as int;
    if (version != _schemaVersion) {
      throw FormatException('Unsupported schemaVersion $version');
    }

    final people = _people(json['people']);
    final movies = <int, TmdbMovieDetails>{};
    final openMovies = <int, OpenMovie>{};
    final sources = <int, List<MovieSource>>{};
    for (final item in json['movies'] as List<dynamic>) {
      final entry = parseJsonObject(item);
      final details = TmdbMovieDetails.fromJson(entry);
      if (movies.containsKey(details.id)) {
        throw FormatException('Duplicate movie id ${details.id}');
      }
      for (final credit in details.credits) {
        if (!people.containsKey(credit.id)) {
          throw FormatException('Unknown person id ${credit.id}');
        }
      }
      final open = parseJsonObject(entry['openMovie']);
      movies[details.id] = details;
      openMovies[details.id] = _openMovie(details, open);
      sources[details.id] = _sources(open);
    }

    return CatalogContents._(
      order: _order(json['order'] as List<dynamic>, movies.keys),
      movies: Map.unmodifiable(movies),
      people: Map.unmodifiable(people),
      openMovies: Map.unmodifiable(openMovies),
      sources: Map.unmodifiable(sources),
    );
  }

  static Map<int, TmdbPersonDetails> _people(Object? raw) {
    final people = <int, TmdbPersonDetails>{};
    for (final person in parseJsonList(raw, TmdbPersonDetails.fromJson)) {
      if (people.containsKey(person.id)) {
        throw FormatException('Duplicate person id ${person.id}');
      }
      people[person.id] = person;
    }
    return people;
  }

  static List<int> _order(List<dynamic> raw, Iterable<int> movieIds) {
    final order = raw.cast<int>().toList(growable: false);
    if (order.length != movieIds.length ||
        !order.toSet().containsAll(movieIds)) {
      throw const FormatException('order must list every movie exactly once');
    }
    return order;
  }

  static OpenMovie _openMovie(
    TmdbMovieDetails details,
    Map<String, dynamic> open,
  ) {
    final directors = [
      for (final credit in details.crew)
        if (credit.job == 'Director') credit.name,
    ];
    if (directors.isEmpty) {
      throw FormatException('${details.title} has no director');
    }
    return OpenMovie(
      tmdbId: details.id,
      title: details.title,
      year: open['year'] as int,
      directedBy: directors.join(', '),
      attribution: open['attribution'] as String,
      license: ContentLicense.fromJson(parseJsonObject(open['license'])),
      sourceUrl: parseAbsoluteUrl(open['sourcePageUrl'] as String),
    );
  }

  static List<MovieSource> _sources(Map<String, dynamic> open) {
    final slug = open['slug'] as String;
    final sources = parseJsonList(
      open['streams'],
      (stream) => _source(slug, open, stream),
    );
    if (sources.isEmpty) throw FormatException('$slug has no streams');
    return sources;
  }

  /// Goes through [MovieSource.fromJson] so bundled streams pass the same
  /// validation as sources from the API.
  static MovieSource _source(
    String slug,
    Map<String, dynamic> open,
    Map<String, dynamic> stream,
  ) {
    final quality = stream['quality'] as String;
    return MovieSource.fromJson({
      'id': '$_providerId.$slug-$quality',
      'providerName': providerName,
      'kind': 'direct',
      'url': stream['url'],
      'quality': quality,
      'mimeType': stream['mimeType'],
      'codecs': stream['codecs'],
      'license': open['license'],
      'attribution': open['attribution'],
      'sourcePageUrl': open['sourcePageUrl'],
    });
  }
}
