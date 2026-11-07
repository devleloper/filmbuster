import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

abstract final class DioFactory {
  static const _connectTimeout = Duration(seconds: 8);

  /// Long enough for the backend, which gives up on TMDB after 8 seconds.
  static const _receiveTimeout = Duration(seconds: 15);

  static Dio create({required String baseUrl}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
      ),
    );
    if (kDebugMode) dio.interceptors.add(_DebugLogInterceptor());
    return dio;
  }
}

class _DebugLogInterceptor extends Interceptor {
  static const _log = AppLogger('Http');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.debug('${options.method} ${_redactedUri(options)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log.debug(
      '${response.statusCode} ${_redactedUri(response.requestOptions)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    _log.error(
      '${err.type.name} ${_redactedUri(err.requestOptions)}'
      '${status == null ? '' : ' ($status)'}',
    );
    handler.next(err);
  }

  static String _redactedUri(RequestOptions options) =>
      AppLogger.redactUrl(options.uri.toString());
}
