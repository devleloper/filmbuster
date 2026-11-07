import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/data/local/bundled_catalog.dart';
import 'package:filmbuster/data/local/demo_movie_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/disk_assets.dart';

void main() {
  late BundledCatalog catalog;
  late DemoMovieRepository movies;

  setUp(() {
    catalog = bundledCatalogFromDisk();
    movies = DemoMovieRepository(catalog);
  });

  test('popular is the curated order', () async {
    final order = (await catalog.load()).order;
    expect((await movies.getPopular()).map((m) => m.id), order);
  });

  test('top rated is newest first, trending oldest first', () async {
    final top = (await movies.getTopRated()).map((m) => m.releaseYear!);
    final trending = (await movies.getTrending()).map((m) => m.releaseYear!);
    expect(top.toList(), [...top]..sort((a, b) => b.compareTo(a)));
    expect(trending.toList(), [...trending]..sort());
  });

  test('details list the other titles as similar', () async {
    final detail = await movies.getDetails(45745);
    expect(detail.title, 'Sintel');
    expect(detail.crew.single.job, 'Director');
    expect(detail.similar.map((m) => m.id), isNot(contains(45745)));
    expect(detail.similar, hasLength((await catalog.load()).order.length - 1));
    expect(detail.trailers, isEmpty);
  });

  test('an unknown id is NotFoundFailure', () async {
    await expectLater(movies.getDetails(1), throwsA(isA<NotFoundFailure>()));
  });

  test('search matches substrings case-insensitively', () async {
    final results = await movies.search('STEEL');
    expect(results.map((m) => m.title), ['Tears of Steel']);
  });

  test('search tolerates typos and word order', () async {
    expect((await movies.search('sintle')).map((m) => m.id), [45745]);
    expect((await movies.search('bunny big buck')).map((m) => m.id), [10378]);
  });

  test('an empty query finds nothing', () async {
    expect(await movies.search('   '), isEmpty);
  });

  test('a query matching no title finds nothing', () async {
    expect(await movies.search('zzzz'), isEmpty);
  });
}
