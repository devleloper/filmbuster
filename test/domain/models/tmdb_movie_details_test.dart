import 'package:filmbuster/domain/models/tmdb_credit_person.dart';
import 'package:filmbuster/domain/models/tmdb_movie.dart';
import 'package:filmbuster/domain/models/tmdb_movie_details.dart';
import 'package:filmbuster/domain/models/tmdb_trailer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/api_json.dart';

void main() {
  group('TmdbMovieDetails', () {
    test('parses credits, similar movies and trailers', () {
      final json = <String, dynamic>{
        'id': 5,
        'title': 'Arrival',
        'genres': ['Sci-Fi', 'Drama'],
        'runtime': 116,
        'credits': {
          'cast': [
            {'id': 1, 'name': 'Amy', 'character': 'Louise'},
          ],
          'crew': [
            {'id': 2, 'name': 'Denis', 'job': 'Director'},
          ],
        },
        'similar': [
          {'id': 9, 'title': 'Sicario'},
        ],
        'trailers': [trailerJson()],
      };

      final details = TmdbMovieDetails.fromJson(json);

      expect(details.genres, ['Sci-Fi', 'Drama']);
      expect(details.cast.single.role, 'Louise');
      expect(details.crew.single.role, 'Director');
      expect(details.similar.single.id, 9);
      expect(
        details.trailers.single,
        TmdbTrailer(url: Uri.parse('https://www.youtube.com/watch?v=abc_123')),
      );
    });

    test('defaults every absent collection to empty', () {
      final details = TmdbMovieDetails.fromJson(const {
        'id': 5,
        'title': 'Minimal',
      });
      expect(details.cast, isEmpty);
      expect(details.crew, isEmpty);
      expect(details.similar, isEmpty);
      expect(details.genres, isEmpty);
      expect(details.trailers, isEmpty);
    });

    test('a collection of the wrong shape throws', () {
      expect(
        () => TmdbMovieDetails.fromJson(const {
          'id': 5,
          'title': 'X',
          'similar': {'results': []},
        }),
        throwsFormatException,
      );
      expect(
        () => TmdbMovieDetails.fromJson(const {
          'id': 5,
          'title': 'X',
          'trailers': ['https://www.youtube.com/watch?v=abc'],
        }),
        throwsFormatException,
      );
      expect(
        () => TmdbMovieDetails.fromJson(const {
          'id': 5,
          'title': 'X',
          'genres': [1, 2],
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('toSummary keeps the card fields', () {
      const details = TmdbMovieDetails(
        id: 5,
        title: 'Arrival',
        posterPath: '/a.jpg',
        backdropPath: '/b.jpg',
        voteAverage: 7.9,
        releaseDate: '2016-11-10',
        overview: 'Linguist meets visitors.',
      );
      expect(
        details.toSummary(),
        const TmdbMovie(
          id: 5,
          title: 'Arrival',
          posterPath: '/a.jpg',
          backdropPath: '/b.jpg',
          voteAverage: 7.9,
          releaseDate: '2016-11-10',
          overview: 'Linguist meets visitors.',
        ),
      );
    });

    test('credits list the cast before the crew', () {
      const details = TmdbMovieDetails(
        id: 5,
        title: 'Arrival',
        cast: [TmdbCreditPerson(id: 1, name: 'Amy')],
        crew: [TmdbCreditPerson(id: 2, name: 'Denis')],
      );
      expect(details.credits.map((person) => person.id), [1, 2]);
    });

    test('copyWith replaces similar and keeps the rest', () {
      const details = TmdbMovieDetails(
        id: 5,
        title: 'Arrival',
        similar: [TmdbMovie(id: 9, title: 'Sicario')],
      );
      final copy = details.copyWith(similar: const []);
      expect(copy.similar, isEmpty);
      expect(copy.title, 'Arrival');
      expect(details.copyWith(), details);
    });
  });
}
