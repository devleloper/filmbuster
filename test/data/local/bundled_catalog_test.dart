import 'dart:convert';
import 'dart:io';

import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/core/utils/tmdb_image_url.dart';
import 'package:filmbuster/data/local/bundled_catalog.dart';
import 'package:filmbuster/data/local/catalog_contents.dart';
import 'package:filmbuster/domain/models/movie_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/disk_assets.dart';

Map<String, dynamic> _firstMovie(Map<String, dynamic> json) =>
    (json['movies'] as List).first as Map<String, dynamic>;

Map<String, dynamic> _openMovie(Map<String, dynamic> json) =>
    _firstMovie(json)['openMovie'] as Map<String, dynamic>;

String _validJson({Map<String, dynamic> Function(Map<String, dynamic>)? edit}) {
  final json = <String, dynamic>{
    'schemaVersion': 1,
    'order': [45745],
    'people': [
      {'id': 3, 'name': 'Colin Levy', 'knownForDepartment': 'Directing'},
    ],
    'movies': [
      {
        'id': 45745,
        'title': 'Sintel',
        'releaseDate': '2010-09-30',
        'credits': {
          'cast': <Object>[],
          'crew': [
            {'id': 3, 'name': 'Colin Levy', 'job': 'Director'},
          ],
        },
        'openMovie': {
          'slug': 'sintel',
          'year': 2010,
          'license': {
            'spdxId': 'CC-BY-3.0',
            'name': 'CC BY 3.0',
            'url': 'https://creativecommons.org/licenses/by/3.0/',
          },
          'attribution': '(c) copyright 2010 Blender Foundation',
          'sourcePageUrl': 'https://durian.blender.org/about/',
          'streams': [
            {
              'url': 'https://example.org/sintel.mp4',
              'mimeType': 'video/mp4',
              'codecs': 'avc1.640028,mp4a.40',
              'quality': '720p',
            },
          ],
        },
      },
    ],
  };
  return jsonEncode(edit == null ? json : edit(json));
}

BundledCatalog _catalogOf(String raw) => BundledCatalog((_) async => raw);

/// The sources of [directive] in the Content-Security-Policy that
/// `vercel.json` sends with the web build.
List<String> _webPolicy(String directive) {
  final config =
      jsonDecode(File('vercel.json').readAsStringSync())
          as Map<String, dynamic>;
  final policy = [
    for (final rule in (config['headers'] as List).cast<Map<String, dynamic>>())
      for (final header
          in (rule['headers'] as List).cast<Map<String, dynamic>>())
        if (header['key'] == 'Content-Security-Policy')
          header['value'] as String,
  ].single;
  final tokens = policy
      .split(';')
      .map((part) => part.trim().split(RegExp(r'\s+')))
      .firstWhere((tokens) => tokens.first == directive);
  return tokens.skip(1).toList();
}

void main() {
  group('bundled catalog.json', () {
    late String text;
    late Map<String, dynamic> raw;

    setUpAll(() {
      text = File(BundledCatalog.assetKey).readAsStringSync();
      raw = jsonDecode(text) as Map<String, dynamic>;
    });

    test('parses with at least 6 titles in curated order', () async {
      final catalog = await bundledCatalogFromDisk().load();
      expect(catalog.order.length, greaterThanOrEqualTo(6));
      expect(catalog.ordered.map((m) => m.id), catalog.order);
    });

    test('every entry is licensed, attributed, https and MP4', () {
      const allowedSpdx = {'CC-BY-2.5', 'CC-BY-3.0', 'CC-BY-4.0'};
      for (final movie in raw['movies'] as List<dynamic>) {
        final open = (movie as Map<String, dynamic>)['openMovie'] as Map;
        final license = open['license'] as Map;
        expect(allowedSpdx, contains(license['spdxId']), reason: '$movie');
        expect((open['attribution'] as String).trim(), isNotEmpty);
        expect(open['sourcePageUrl'] as String, startsWith('https://'));
        final streams = open['streams'] as List<dynamic>;
        expect(streams, isNotEmpty);
        for (final stream in streams.cast<Map<String, dynamic>>()) {
          expect(stream['url'] as String, startsWith('https://'));
          expect(stream['mimeType'], 'video/mp4');
        }
      }
    });

    test('every movie offers several qualities, best first', () {
      for (final MapEntry(key: id, value: sources)
          in bundledCatalogContents().sources.entries) {
        final labels = [for (final source in sources) source.quality];
        expect(labels, everyElement(matches(r'^\d+p$')), reason: '$id');
        final heights = [
          for (final label in labels) int.parse(label.replaceFirst('p', '')),
        ];
        expect(heights.length, greaterThan(1), reason: '$id');
        expect(heights, [...heights]..sort((a, b) => b - a), reason: '$id');
      }
    });

    test('every stream host is allowed by the web media-src policy', () {
      final mediaSrc = _webPolicy('media-src');
      for (final sources in bundledCatalogContents().sources.values) {
        for (final source in sources) {
          expect(
            mediaSrc,
            contains(source.url.origin),
            reason: '${source.url}',
          );
        }
      }
    });

    test('NOTICE credits every film with its catalogue attribution', () {
      final notice = File('NOTICE').readAsStringSync();
      for (final movie in bundledCatalogContents().openMovies.values) {
        expect(notice, contains(movie.attribution), reason: movie.title);
      }
    });

    test('every referenced image exists within the size budget', () {
      var total = 0;
      for (final movie
          in (raw['movies'] as List).cast<Map<String, dynamic>>()) {
        for (final (field, budget) in [
          ('posterPath', 60 * 1024),
          ('backdropPath', 120 * 1024),
        ]) {
          final key = TmdbImageUrl.bundledAsset(movie[field] as String?);
          expect(key, isNotNull, reason: '${movie['title']} $field');
          final file = File(key!);
          expect(file.existsSync(), isTrue, reason: key);
          final size = file.lengthSync();
          expect(size, lessThanOrEqualTo(budget), reason: key);
          total += size;
        }
      }
      expect(total, lessThanOrEqualTo(5 * 1024 * 1024));
    });

    test('contains no private network addresses', () {
      expect(
        RegExp(
          r'\b(10|127|192\.168|172\.(1[6-9]|2\d|3[01]))\.\d',
        ).hasMatch(text.toLowerCase()),
        isFalse,
      );
    });

    test('serves sources as direct bundled sources', () async {
      final catalog = bundledCatalogFromDisk();
      final list = await catalog.getSources(45745);
      expect(list.partial, isFalse);
      expect(list.results, isNotEmpty);
      final source = list.results.first;
      expect(source.kind, SourceKind.direct);
      expect(source.providerName, CatalogContents.providerName);
      expect(
        source.id,
        matches(RegExp(r'^[a-z][a-z0-9]{1,23}\.[A-Za-z0-9_-]{1,64}$')),
      );
      expect(source.license.spdxId, 'CC-BY-3.0');
    });
  });

  group('BundledCatalog', () {
    test('memoises the parsed catalogue', () async {
      var reads = 0;
      final catalog = BundledCatalog((_) async {
        reads++;
        return _validJson();
      });
      await catalog.load();
      await catalog.getAll();
      await catalog.getSources(45745);
      expect(reads, 1);
    });

    test('maps an entry to an OpenMovie', () async {
      final movie = await _catalogOf(_validJson()).findByTmdbId(45745);
      expect(movie, isNotNull);
      expect(movie!.title, 'Sintel');
      expect(movie.year, 2010);
      expect(movie.directedBy, 'Colin Levy');
      expect(movie.license.name, 'CC BY 3.0');
      expect(movie.sourceUrl.host, 'durian.blender.org');
    });

    test('an unknown movie has no open movie and no sources', () async {
      final catalog = _catalogOf(_validJson());
      expect(await catalog.findByTmdbId(1), isNull);
      final list = await catalog.getSources(1);
      expect(list.results, isEmpty);
      expect(list.partial, isFalse);
    });

    test('invalid JSON is a ParsingFailure', () async {
      await expectLater(
        _catalogOf('{not json').load(),
        throwsA(isA<ParsingFailure>()),
      );
    });

    test('a non-object root is a ParsingFailure', () async {
      await expectLater(
        _catalogOf('[]').load(),
        throwsA(isA<ParsingFailure>()),
      );
    });

    final damaged =
        <String, Map<String, dynamic> Function(Map<String, dynamic>)>{
          'unsupported schemaVersion': (j) => j..['schemaVersion'] = 2,
          'missing movies': (j) => j..remove('movies'),
          'order not covering every movie': (j) => j..['order'] = <int>[],
          'unknown credited person': (j) => j..['people'] = <Object>[],
          'http stream': (j) {
            ((_openMovie(j)['streams'] as List).first as Map)['url'] =
                'http://example.org/a.mp4';
            return j;
          },
          'no streams': (j) {
            _openMovie(j)['streams'] = <Object>[];
            return j;
          },
          'empty attribution': (j) {
            _openMovie(j)['attribution'] = ' ';
            return j;
          },
          'missing license': (j) {
            _openMovie(j).remove('license');
            return j;
          },
          'a movie without a director': (j) {
            (_firstMovie(j)['credits'] as Map)['crew'] = <Object>[];
            return j;
          },
        };
    for (final MapEntry(:key, :value) in damaged.entries) {
      test('$key is a ParsingFailure', () {
        expect(
          _catalogOf(_validJson(edit: value)).load(),
          throwsA(isA<ParsingFailure>()),
        );
      });
    }

    test('an unreadable asset fails and the next call retries', () async {
      var calls = 0;
      final catalog = BundledCatalog((_) async {
        calls++;
        if (calls == 1) throw StateError('asset missing');
        return _validJson();
      });
      await expectLater(catalog.load(), throwsA(isA<UnknownFailure>()));
      final all = await catalog.getAll();
      expect(all.single.tmdbId, 45745);
      expect(calls, 2);
    });
  });
}
