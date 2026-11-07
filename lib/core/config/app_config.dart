import 'package:flutter/foundation.dart';

import 'data_source_mode.dart';

/// Build-time configuration from `--dart-define` or `--dart-define-from-file`.
abstract final class AppConfig {
  static const String _compileTimeBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Lays the app out for a remote control on any device, for trying the
  /// TV layout on a phone or desktop.
  static const bool forceLeanback = bool.fromEnvironment('FORCE_LEANBACK');

  /// The backend URL, or `null` when none is configured (demo mode).
  static String? get baseUrl => normalizeBaseUrl(_compileTimeBaseUrl);

  static DataSourceMode get dataSource =>
      baseUrl == null ? DataSourceMode.demo : DataSourceMode.live;

  @visibleForTesting
  static String? normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
