import 'package:filmbuster/domain/models/json_parsing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseAbsoluteUrl', () {
    test('accepts an absolute https URL', () {
      expect(
        parseAbsoluteUrl('https://example.org/a?b=1'),
        Uri.parse('https://example.org/a?b=1'),
      );
    });

    test('accepts http only when allowed', () {
      expect(
        () => parseAbsoluteUrl('http://example.org/a'),
        throwsFormatException,
      );
      expect(
        parseAbsoluteUrl('http://example.org/a', allowHttp: true).scheme,
        'http',
      );
    });

    test('rejects relative URLs and other schemes', () {
      for (final url in ['/a', 'https:///a', 'ftp://example.org/a']) {
        expect(
          () => parseAbsoluteUrl(url, allowHttp: true),
          throwsFormatException,
          reason: url,
        );
      }
    });
  });
}
