import 'package:dio/dio.dart';

import '../error/app_failure.dart';

/// Maps transport errors to [AppFailure]s whose message is the first of: the
/// caller's copy for the status, the backend's problem `detail`, the
/// rate-limit copy for 429, the caller's fallback, the failure's default.
abstract final class FailureMapper {
  static const rateLimitedMessage =
      'Too many requests. Please wait a moment and try again.';

  static const _maxDetailLength = 200;

  static AppFailure fromDio(
    DioException error, {
    Map<int, String> statusMessages = const {},
    String? fallbackMessage,
  }) {
    final stackTrace = error.stackTrace;
    switch (error.type) {
      case DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout:
        return TimeoutFailure(cause: error, stackTrace: stackTrace);
      case DioExceptionType.connectionError:
        return NetworkFailure(cause: error, stackTrace: stackTrace);
      case DioExceptionType.badCertificate:
        return NetworkFailure(
          message: 'Secure connection to the server failed.',
          cause: error,
          stackTrace: stackTrace,
        );
      case DioExceptionType.badResponse ||
          DioExceptionType.unknown ||
          DioExceptionType.cancel:
        return _fromStatus(error, statusMessages, fallbackMessage);
    }
  }

  static AppFailure _fromStatus(
    DioException error,
    Map<int, String> statusMessages,
    String? fallbackMessage,
  ) {
    final status = error.response?.statusCode;
    final message =
        statusMessages[status] ??
        _problemDetail(error.response?.data) ??
        (status == 429 ? rateLimitedMessage : null) ??
        fallbackMessage;
    final stackTrace = error.stackTrace;

    return switch (status) {
      404 => NotFoundFailure(
        message: message,
        cause: error,
        stackTrace: stackTrace,
      ),
      400 || 422 => ValidationFailure(
        message: message,
        cause: error,
        stackTrace: stackTrace,
      ),
      final int code when code == 429 || code >= 500 => ServerFailure(
        message: message,
        cause: error,
        stackTrace: stackTrace,
      ),
      _ => UnknownFailure(
        message: message,
        cause: error,
        stackTrace: stackTrace,
      ),
    };
  }

  /// The `detail` of an RFC 9457 problem. The backend keeps it short and
  /// user-safe; a raw body, HTML or an oversized or multi-line text is
  /// ignored so the caller's copy is shown instead.
  static String? _problemDetail(Object? data) {
    if (data is! Map) return null;
    final detail = data['detail'];
    if (detail is! String) return null;
    final trimmed = detail.trim();
    if (trimmed.isEmpty || trimmed.length > _maxDetailLength) return null;
    if (trimmed.contains('\n') || trimmed.contains('<')) return null;
    return trimmed;
  }
}
