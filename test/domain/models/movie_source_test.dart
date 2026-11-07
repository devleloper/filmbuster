import 'package:filmbuster/domain/models/movie_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/api_json.dart';

void main() {
  group('MovieSource.fromJson', () {
    test('reads kind, license and source page', () {
      final source = MovieSource.fromJson(movieSourceJson());

      expect(source.kind, SourceKind.direct);
      expect(source.license.spdxId, 'CC-BY-3.0');
      expect(source.sourcePageUrl!.host, 'durian.blender.org');
    });

    test('keeps the URL verbatim, including its query', () {
      const url = 'https://media.example.org/a.mp4?sig=abc%2Fdef&exp=1';

      final source = MovieSource.fromJson(
        movieSourceJson(url: url, kind: 'stream'),
      );

      expect(source.toPlayerSource().url, url);
    });
  });

  test('toPlayerSource labels the stream with quality and provider', () {
    final player = MovieSource.fromJson(movieSourceJson()).toPlayerSource();

    expect(player.label, '1080p · Open movies');
  });

  group('MovieSourceList.fromJson', () {
    test('drops sources of an unknown kind and keeps partial', () {
      final list = MovieSourceList.fromJson({
        'tmdbId': 1,
        'partial': true,
        'results': [
          movieSourceJson(id: 'future.a', kind: 'hologram'),
          movieSourceJson(),
        ],
      });

      expect(list.partial, isTrue);
      expect(list.results.map((s) => s.id), ['openmovies.sintel-1080p']);
    });

    test('accepts an empty list', () {
      final list = MovieSourceList.fromJson(const {
        'tmdbId': 1,
        'partial': false,
        'results': <Object>[],
      });

      expect(list.results, isEmpty);
    });
  });
}
