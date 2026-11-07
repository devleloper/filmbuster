import 'package:filmbuster/domain/models/tmdb_trailer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/api_json.dart';

void main() {
  group('TmdbTrailer.fromJson', () {
    test('reads an https trailer', () {
      final parsed = TmdbTrailer.fromJson(trailerJson());

      expect(parsed.url, Uri.parse('https://www.youtube.com/watch?v=abc_123'));
    });

    test('needs nothing but the url', () {
      final parsed = TmdbTrailer.fromJson(const {
        'url': 'https://www.youtube.com/watch?v=abc_123',
      });

      expect(parsed.url.host, 'www.youtube.com');
    });

    test('a trailer url that is not https is rejected', () {
      for (final url in [
        'http://www.youtube.com/watch?v=abc',
        'javascript:alert(1)',
        '/watch?v=abc',
      ]) {
        expect(
          () => TmdbTrailer.fromJson(trailerJson(url: url)),
          throwsFormatException,
          reason: url,
        );
      }
    });
  });
}
