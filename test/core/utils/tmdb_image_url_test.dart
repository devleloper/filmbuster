import 'package:filmbuster/core/utils/tmdb_image_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TmdbImageUrl bundled paths', () {
    const path = 'asset:assets/demo/images/sintel-poster.webp';

    test('recognises the asset: prefix', () {
      expect(TmdbImageUrl.isBundled(path), isTrue);
      expect(TmdbImageUrl.isBundled('/abc.jpg'), isFalse);
      expect(TmdbImageUrl.isBundled(null), isFalse);
    });

    test('maps a bundled path to its asset key', () {
      expect(
        TmdbImageUrl.bundledAsset(path),
        'assets/demo/images/sintel-poster.webp',
      );
      expect(TmdbImageUrl.bundledAsset('/abc.jpg'), isNull);
    });

    test('never builds a network URL for a bundled path', () {
      expect(TmdbImageUrl.build(path, size: TmdbImageSize.w500), isNull);
      expect(TmdbImageUrl.backdrop(path), isNull);
    });
  });

  group('TmdbImageUrl', () {
    test('builds a sized TMDB URL from a path', () {
      expect(
        TmdbImageUrl.build('/abc.jpg', size: TmdbImageSize.w500),
        'https://image.tmdb.org/t/p/w500/abc.jpg',
      );
      expect(
        TmdbImageUrl.backdrop('/b.jpg'),
        'https://image.tmdb.org/t/p/w780/b.jpg',
      );
    });

    test('returns null for a missing or empty path', () {
      expect(TmdbImageUrl.build(null, size: TmdbImageSize.w500), isNull);
      expect(TmdbImageUrl.build('', size: TmdbImageSize.w500), isNull);
    });
  });

  group('TmdbImageUrl.posterSizeFor', () {
    test('picks the smallest poster at least as wide as the image', () {
      expect(TmdbImageUrl.posterSizeFor(120), TmdbImageSize.w185);
      expect(TmdbImageUrl.posterSizeFor(185), TmdbImageSize.w185);
      expect(TmdbImageUrl.posterSizeFor(186), TmdbImageSize.w342);
      expect(TmdbImageUrl.posterSizeFor(342), TmdbImageSize.w342);
      expect(TmdbImageUrl.posterSizeFor(390), TmdbImageSize.w500);
    });

    test('never picks a poster wider than w500', () {
      expect(TmdbImageUrl.posterSizeFor(640), TmdbImageSize.w500);
      expect(TmdbImageUrl.posterSizeFor(2000), TmdbImageSize.w500);
    });
  });
}
