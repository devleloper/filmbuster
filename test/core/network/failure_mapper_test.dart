import 'package:dio/dio.dart';
import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/core/network/failure_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/dio.dart';

void main() {
  group('FailureMapper.fromDio', () {
    test('maps transport error types', () {
      expect(
        FailureMapper.fromDio(
          dioError(type: DioExceptionType.connectionTimeout),
        ),
        isA<TimeoutFailure>(),
      );
      expect(
        FailureMapper.fromDio(dioError(type: DioExceptionType.sendTimeout)),
        isA<TimeoutFailure>(),
      );
      expect(
        FailureMapper.fromDio(dioError(type: DioExceptionType.receiveTimeout)),
        isA<TimeoutFailure>(),
      );
      expect(
        FailureMapper.fromDio(dioError(type: DioExceptionType.connectionError)),
        isA<NetworkFailure>(),
      );
      expect(
        FailureMapper.fromDio(dioError(type: DioExceptionType.badCertificate)),
        isA<NetworkFailure>().having(
          (f) => f.message,
          'message',
          'Secure connection to the server failed.',
        ),
      );
    });

    test('a cancelled request without a response is an UnknownFailure', () {
      expect(
        FailureMapper.fromDio(dioError(type: DioExceptionType.cancel)),
        isA<UnknownFailure>(),
      );
    });

    test('maps status codes to failure types', () {
      expect(
        FailureMapper.fromDio(dioError(statusCode: 404)),
        isA<NotFoundFailure>(),
      );
      expect(
        FailureMapper.fromDio(dioError(statusCode: 400)),
        isA<ValidationFailure>(),
      );
      expect(
        FailureMapper.fromDio(dioError(statusCode: 422)),
        isA<ValidationFailure>(),
      );
      expect(
        FailureMapper.fromDio(dioError(statusCode: 503)),
        isA<ServerFailure>(),
      );
    });

    Map<String, dynamic> problem(int status, String detail) => {
      'type': 'urn:filmbuster:problem:test',
      'title': 'Title',
      'status': status,
      'detail': detail,
      'requestId': 'req-1',
    };

    test('uses the problem detail when present', () {
      final failure = FailureMapper.fromDio(
        dioError(
          statusCode: 400,
          data: problem(400, 'Parameter "q" must not be empty.'),
        ),
        fallbackMessage: 'Search failed.',
      );
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, 'Parameter "q" must not be empty.');
    });

    test('ignores message/error fields and raw bodies', () {
      expect(
        FailureMapper.fromDio(
          dioError(statusCode: 500, data: {'message': 'x', 'error': 'raw'}),
          fallbackMessage: 'Could not load movies.',
        ).message,
        'Could not load movies.',
      );
      expect(
        FailureMapper.fromDio(
          dioError(statusCode: 502, data: '<html>Bad gateway</html>'),
          fallbackMessage: 'Could not load movies.',
        ).message,
        'Could not load movies.',
      );
    });

    test('ignores an unsafe or oversized detail', () {
      for (final detail in ['', '   ', 'a' * 201, 'line\nline', '<b>x</b>']) {
        expect(
          FailureMapper.fromDio(
            dioError(statusCode: 500, data: problem(500, detail)),
            fallbackMessage: 'fallback',
          ).message,
          'fallback',
          reason: detail,
        );
      }
    });

    test('429 is a ServerFailure with rate-limit copy', () {
      final bare = FailureMapper.fromDio(
        dioError(statusCode: 429),
        fallbackMessage: 'Could not load movies.',
      );
      expect(bare, isA<ServerFailure>());
      expect(bare.message, FailureMapper.rateLimitedMessage);

      final withDetail = FailureMapper.fromDio(
        dioError(statusCode: 429, data: problem(429, 'Slow down, please.')),
      );
      expect(withDetail.message, 'Slow down, please.');
    });

    test('a status override wins over the backend message', () {
      final failure = FailureMapper.fromDio(
        dioError(statusCode: 503, data: problem(503, 'Upstream is busy.')),
        statusMessages: const {503: 'Service unavailable.'},
      );
      expect(failure.message, 'Service unavailable.');
    });

    test('falls back to the caller-provided message', () {
      final failure = FailureMapper.fromDio(
        dioError(statusCode: 500),
        fallbackMessage: 'Could not load movies.',
      );
      expect(failure.message, 'Could not load movies.');
    });

    test('keeps the original exception for logging', () {
      final error = dioError(statusCode: 500);
      expect(FailureMapper.fromDio(error).cause, same(error));
    });

    test('never leaks a stringified DioException into the message', () {
      final failure = FailureMapper.fromDio(dioError(statusCode: 500));
      expect(failure.message.toLowerCase(), isNot(contains('dioexception')));
    });
  });

  group('toAppFailure', () {
    test('preserves an already-typed failure', () {
      const failure = NotFoundFailure();
      expect(failure.toAppFailure(), same(failure));
    });

    test('wraps anything else as UnknownFailure', () {
      final failure = ArgumentError('boom').toAppFailure(StackTrace.current);
      expect(failure, isA<UnknownFailure>());
      expect(failure.cause, isA<ArgumentError>());
    });
  });
}
