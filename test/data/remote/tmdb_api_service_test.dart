import 'package:dio/dio.dart';
import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/data/remote/tmdb_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/api_json.dart';
import '../../support/dio.dart';
import '../../support/mocks.dart';

void main() {
  late MockDio dio;
  late TmdbApiService api;

  setUp(() {
    dio = MockDio();
    api = TmdbApiService(dio);
  });

  Map<String, dynamic> page(List<Object?> results) => {
    'page': 1,
    'totalPages': 1,
    'results': results,
  };

  group('decoding', () {
    test('a movie page decodes into its movies', () async {
      dio.answerGet(
        page([
          {'id': 1, 'title': 'Dune'},
          {'id': 2, 'title': 'Arrival'},
        ]),
      );

      final movies = await api.getPopular();
      expect(movies.map((m) => m.id), [1, 2]);
      verify(() => dio.get<dynamic>('/api/v1/tmdb/discover/popular')).called(1);
    });

    test('an empty page is an empty list, not an error', () async {
      dio.answerGet(page(const []));

      expect(await api.getTopRated(), isEmpty);
    });

    test('a bare array instead of a page is a ParsingFailure', () async {
      dio.answerGet([
        {'id': 1, 'title': 'Dune'},
      ]);

      await expectLater(api.getTopRated(), throwsA(isA<ParsingFailure>()));
    });

    test('a page without results is a ParsingFailure', () async {
      dio.answerGet({'page': 1, 'totalPages': 0});

      await expectLater(api.getTrending(), throwsA(isA<ParsingFailure>()));
    });

    test('a malformed entry is a ParsingFailure, not a silent skip', () async {
      dio.answerGet(
        page([
          {'id': 1, 'title': 'Dune'},
          'garbage',
        ]),
      );

      await expectLater(api.getTrending(), throwsA(isA<ParsingFailure>()));
    });

    test('person movies decode PersonMovieList.results', () async {
      dio.answerGet({
        'results': [
          {'id': 3, 'title': 'Sintel', 'character': 'Sintel', 'job': null},
        ],
      });

      final movies = await api.getPersonMovies(7);
      expect(movies.single.title, 'Sintel');
      verify(() => dio.get<dynamic>('/api/v1/tmdb/person/7/movies')).called(1);
    });

    test('person movies under a movies key instead of results fail', () async {
      dio.answerGet({'movies': const []});

      await expectLater(api.getPersonMovies(7), throwsA(isA<ParsingFailure>()));
    });

    test('movie details carry official trailers', () async {
      dio.answerGet({
        'id': 45745,
        'title': 'Sintel',
        'credits': {'cast': const [], 'crew': const []},
        'similar': const [],
        'trailers': [trailerJson()],
      });

      final details = await api.getMovieDetails(45745);
      expect(
        details.trailers.single.url,
        Uri.parse('https://www.youtube.com/watch?v=abc_123'),
      );
    });
  });

  group('error mapping', () {
    test('a connection error becomes NetworkFailure', () async {
      dio.failGet(dioError(type: DioExceptionType.connectionError));

      await expectLater(api.getPopular(), throwsA(isA<NetworkFailure>()));
    });

    test('a timeout becomes TimeoutFailure', () async {
      dio.failGet(dioError(type: DioExceptionType.receiveTimeout));

      await expectLater(api.getPopular(), throwsA(isA<TimeoutFailure>()));
    });

    test(
      'a 404 on movie details becomes NotFoundFailure with our copy',
      () async {
        dio.failGet(dioError(statusCode: 404));

        await expectLater(
          api.getMovieDetails(1),
          throwsA(
            isA<NotFoundFailure>().having(
              (f) => f.message,
              'message',
              'Movie not found.',
            ),
          ),
        );
      },
    );

    test('a problem+json detail becomes the failure message', () async {
      dio.failGet(
        dioError(
          statusCode: 502,
          data: {
            'type': 'urn:filmbuster:problem:upstream-error',
            'title': 'Bad Gateway',
            'status': 502,
            'detail': 'The movie service is unavailable. Try again later.',
            'requestId': 'abc',
          },
        ),
      );

      await expectLater(
        api.getPopular(),
        throwsA(
          isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            'The movie service is unavailable. Try again later.',
          ),
        ),
      );
    });

    test('a 500 becomes ServerFailure', () async {
      dio.failGet(dioError(statusCode: 500));

      await expectLater(api.getMovieDetails(1), throwsA(isA<ServerFailure>()));
    });

    test('a non-object detail payload becomes ParsingFailure', () async {
      dio.answerGet('<html>proxy error</html>');

      await expectLater(api.getMovieDetails(1), throwsA(isA<ParsingFailure>()));
    });

    test(
      'a schema mismatch becomes ParsingFailure, not UnknownFailure',
      () async {
        dio.answerGet({'id': 'not-an-int'});

        await expectLater(
          api.getMovieDetails(1),
          throwsA(isA<ParsingFailure>()),
        );
      },
    );

    test('a transport failure keeps the DioException as its cause', () async {
      dio.failGet(dioError(type: DioExceptionType.connectionError));

      await expectLater(
        api.getPopular(),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.cause,
            'cause',
            isA<DioException>(),
          ),
        ),
      );
    });
  });

  group('search', () {
    test('passes the query', () async {
      dio.answerGet(page(const []));

      await api.searchMovies('dune');

      final captured =
          verify(
                () => dio.get<dynamic>(
                  '/api/v1/tmdb/search',
                  queryParameters: captureAny(named: 'queryParameters'),
                ),
              ).captured.single
              as Map<String, dynamic>;

      expect(captured, {'q': 'dune'});
    });
  });
}
