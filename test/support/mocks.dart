import 'package:dio/dio.dart';
import 'package:filmbuster/domain/models/content_license.dart';
import 'package:filmbuster/domain/models/movie_source.dart';
import 'package:filmbuster/domain/models/tmdb_movie.dart';
import 'package:filmbuster/domain/models/tmdb_movie_details.dart';
import 'package:filmbuster/domain/models/tmdb_person_details.dart';
import 'package:filmbuster/domain/repositories/movie_repository.dart';
import 'package:filmbuster/domain/repositories/movie_sources_repository.dart';
import 'package:filmbuster/domain/repositories/open_movie_repository.dart';
import 'package:filmbuster/domain/repositories/person_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockMovieRepository extends Mock implements MovieRepository {}

extension HomeCatalogues on MockMovieRepository {
  /// Makes the three Home catalogues answer with [movies].
  void stubCatalogues(List<TmdbMovie> movies) {
    when(getPopular).thenAnswer((_) async => movies);
    when(getTopRated).thenAnswer((_) async => movies);
    when(getTrending).thenAnswer((_) async => movies);
  }
}

class MockPersonRepository extends Mock implements PersonRepository {}

class MockMovieSourcesRepository extends Mock
    implements MovieSourcesRepository {}

class MockOpenMovieRepository extends Mock implements OpenMovieRepository {}

class MockDio extends Mock implements Dio {}

abstract final class Fixtures {
  static const movie = TmdbMovie(id: 1, title: 'Dune', posterPath: '/d.jpg');
  static const otherMovie = TmdbMovie(id: 2, title: 'Arrival');

  static List<TmdbMovie> movies(int count) => [
    for (var id = 1; id <= count; id++)
      TmdbMovie(id: id, title: 'Open movie $id'),
  ];

  static const movieDetails = TmdbMovieDetails(id: 1, title: 'Dune');

  static const person = TmdbPersonDetails(id: 10, name: 'Denis Villeneuve');

  static MovieSource source({
    String id = 'openmovies.dune-720p',
    String mimeType = 'video/mp4',
    String? codecs = 'avc1.640028, mp4a.40.2',
    String quality = '720p',
  }) => MovieSource(
    id: id,
    providerName: 'Open movies',
    kind: SourceKind.direct,
    url: Uri.parse('https://media.example.org/$id.mp4'),
    quality: quality,
    mimeType: mimeType,
    codecs: codecs,
    license: const ContentLicense(spdxId: 'CC-BY-3.0', name: 'CC BY 3.0'),
    attribution: 'Example Studio',
    sourcePageUrl: Uri.parse('https://studio.example.org/dune'),
  );
}
