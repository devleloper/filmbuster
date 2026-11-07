import 'package:filmbuster/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/debug_print.dart';

void main() {
  test('redactUrl drops the query, which may carry search terms', () {
    expect(
      AppLogger.redactUrl('https://api.example.com/api/v1/tmdb/search?q=dune'),
      'https://api.example.com/api/v1/tmdb/search?<redacted>',
    );
    expect(
      AppLogger.redactUrl('https://api.example.com/a'),
      'https://api.example.com/a',
    );
  });

  test('writes tagged lines through debugPrint', () {
    final lines = recordDebugPrint();

    const AppLogger('Http').warn('slow');

    expect(lines, ['[Http] WARN slow']);
  });
}
