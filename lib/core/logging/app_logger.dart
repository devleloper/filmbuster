import 'package:flutter/foundation.dart';

/// A tagged logger that writes in debug builds only.
class AppLogger {
  const AppLogger(this._tag);

  final String _tag;

  void debug(String message) => _write(message);

  void warn(String message) => _write('WARN $message');

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _write('ERROR $message${error == null ? '' : ' — $error'}');
    if (kDebugMode && stackTrace != null) debugPrint('$stackTrace');
  }

  void _write(String message) {
    if (kDebugMode) debugPrint('[$_tag] $message');
  }

  /// [url] without its query, which may carry search terms or tokens.
  static String redactUrl(String url) {
    final index = url.indexOf('?');
    if (index < 0) return url;
    return '${url.substring(0, index)}?<redacted>';
  }
}
