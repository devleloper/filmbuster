import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logging/app_logger.dart';

/// Opens only absolute `https` URLs, always in the external browser or app,
/// never in an in-app web view.
abstract final class ExternalUrl {
  static const _log = AppLogger('ExternalUrl');

  static const String semanticHint = 'Opens in browser';

  static bool isAllowed(Uri? uri) =>
      uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;

  /// A tap handler that opens [uri], or `null` (a disabled link) when [uri]
  /// is missing or not allowed.
  static VoidCallback? onTapFor(Uri? uri) =>
      isAllowed(uri) ? () => unawaited(_open(uri!)) : null;

  static Future<void> _open(Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) _log.warn('no app opened ${uri.host}');
    } catch (error, stackTrace) {
      _log.error('could not open ${uri.host}', error, stackTrace);
    }
  }
}
