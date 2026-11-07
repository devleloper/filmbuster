import 'package:dio/dio.dart';
import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/data/remote/movie_sources_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/api_json.dart';
import '../../support/debug_print.dart';
import '../../support/dio.dart';
import '../../support/mocks.dart';

void main() {
  late MockDio dio;
  late MovieSourcesApiService api;

  setUp(() {
    dio = MockDio();
    api = MovieSourcesApiService(dio);
  });

  test('reads the sources of a movie from the contract path', () async {
    dio.answerGet({
      'tmdbId': 45745,
      'partial': false,
      'results': [movieSourceJson()],
    });

    final list = await api.getSources(45745);

    verify(() => dio.get<dynamic>('/api/v1/movies/45745/sources')).called(1);
    expect(list.results.single.id, 'openmovies.sintel-1080p');
  });

  test('a source with an http license deed stays playable', () async {
    const deed = 'http://creativecommons.org/licenses/by/3.0/';
    dio.answerGet({
      'tmdbId': 45745,
      'partial': false,
      'results': [movieSourceJson(licenseUrl: deed)],
    });

    final list = await api.getSources(45745);

    expect(list.results.single.license.url, Uri.parse(deed));
  });

  test('a rejected source URL is not logged with its query', () async {
    final lines = recordDebugPrint();
    dio.answerGet({
      'tmdbId': 1,
      'partial': false,
      'results': [
        movieSourceJson(url: 'http://cdn.example.org/a.mp4?token=SECRET123'),
      ],
    });

    await expectLater(api.getSources(1), throwsA(isA<ParsingFailure>()));

    final log = lines.join('\n');
    expect(log, contains('response does not match the contract'));
    expect(log, isNot(contains('SECRET123')));
  });

  final malformed = <String, Object?>{
    'a bare array': <Object>[],
    'missing results': {'tmdbId': 1, 'partial': false},
    'missing partial': {'tmdbId': 1, 'results': <Object>[]},
    'a direct http URL': {
      'tmdbId': 1,
      'partial': false,
      'results': [movieSourceJson(url: 'http://example.org/a.mp4')],
    },
    'a non-https source page': {
      'tmdbId': 1,
      'partial': false,
      'results': [movieSourceJson(sourcePageUrl: 'http://example.org/')],
    },
    'a non-object item': {
      'tmdbId': 1,
      'partial': false,
      'results': ['x'],
    },
  };
  for (final MapEntry(:key, :value) in malformed.entries) {
    test('$key is a ParsingFailure', () async {
      dio.answerGet(value);
      await expectLater(api.getSources(1), throwsA(isA<ParsingFailure>()));
    });
  }

  test('502 sources-unavailable is a ServerFailure with the detail', () async {
    dio.failGet(
      dioError(
        statusCode: 502,
        data: {
          'type': 'urn:filmbuster:problem:sources-unavailable',
          'title': 'Bad Gateway',
          'status': 502,
          'detail': 'Playback sources are unavailable. Please try again later.',
        },
      ),
    );
    await expectLater(
      api.getSources(1),
      throwsA(
        isA<ServerFailure>().having(
          (f) => f.message,
          'message',
          'Playback sources are unavailable. Please try again later.',
        ),
      ),
    );
  });

  test('a timeout is a TimeoutFailure', () async {
    dio.failGet(dioError(type: DioExceptionType.receiveTimeout));
    await expectLater(api.getSources(1), throwsA(isA<TimeoutFailure>()));
  });
}
