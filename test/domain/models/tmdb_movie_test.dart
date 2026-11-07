import 'package:filmbuster/domain/models/tmdb_movie.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TmdbMovie.fromJson', () {
    test('reads the camelCase MovieSummary contract', () {
      final movie = TmdbMovie.fromJson(const {
        'id': 1,
        'title': 'Dune',
        'posterPath': '/p.jpg',
        'backdropPath': null,
        'voteAverage': 8,
        'releaseDate': '2021-09-15',
        'overview': null,
        'genreIds': [12, 878],
      });
      expect(movie.posterPath, '/p.jpg');
      expect(movie.backdropPath, isNull);
      expect(movie.voteAverage, 8.0);
      expect(movie.genreIds, [12, 878]);
    });

    test('ignores snake_case keys', () {
      final movie = TmdbMovie.fromJson(const {
        'id': 1,
        'title': 'Dune',
        'poster_path': '/p.jpg',
        'genre_ids': [12],
      });
      expect(movie.posterPath, isNull);
      expect(movie.genreIds, isEmpty);
    });

    test('a missing title or id is a type error', () {
      expect(
        () => TmdbMovie.fromJson(const {'id': 1, 'name': 'N'}),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => TmdbMovie.fromJson(const {'title': 'T'}),
        throwsA(isA<TypeError>()),
      );
    });

    test('tolerates a malformed genre list', () {
      expect(
        TmdbMovie.fromJson(const {
          'id': 1,
          'title': 'T',
          'genreIds': ['x', 5, null],
        }).genreIds,
        [5],
      );
    });

    test('is compared by value', () {
      const json = {'id': 7, 'title': 'A'};
      expect(TmdbMovie.fromJson(json), TmdbMovie.fromJson(json));
    });

    test('releaseYear reads the year of the release date', () {
      TmdbMovie withDate(String? date) =>
          TmdbMovie(id: 1, title: 'T', releaseDate: date);
      expect(withDate('2010-09-30').releaseYear, 2010);
      expect(withDate(null).releaseYear, isNull);
      expect(withDate('').releaseYear, isNull);
      expect(withDate('soon').releaseYear, isNull);
    });
  });
}
