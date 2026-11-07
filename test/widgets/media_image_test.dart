import 'package:cached_network_image/cached_network_image.dart';
import 'package:filmbuster/presentation/theme/app_colors.dart';
import 'package:filmbuster/presentation/widgets/media_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _bundledBackdrop = 'asset:assets/demo/images/sintel-backdrop.webp';
const _dim = AppColors.scrimSoft;
const _standIn = Key('stand-in');

Future<void> _pumpImage(
  WidgetTester tester,
  MediaImage image, {
  double devicePixelRatio = 3,
}) => tester.pumpWidget(
  MediaQuery(
    data: MediaQueryData(devicePixelRatio: devicePixelRatio),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: image),
    ),
  ),
);

CachedNetworkImage _networkImage(WidgetTester tester) =>
    tester.widget(find.byType(CachedNetworkImage));

void main() {
  group('a network poster', () {
    for (final (ratio, width, decodeWidth, size) in [
      (3.0, 130.0, 390, 'w500'),
      (2.625, 130.0, 342, 'w342'),
      (2.0, 130.0, 260, 'w342'),
      (3.0, 90.0, 270, 'w342'),
      (2.0, 60.0, 120, 'w185'),
    ]) {
      testWidgets(
        'is decoded $decodeWidth px wide from $size when $width dp wide '
        'at ${ratio}x',
        (tester) async {
          await _pumpImage(
            tester,
            MediaImage(path: '/poster.jpg', width: width, height: width * 1.5),
            devicePixelRatio: ratio,
          );

          final image = _networkImage(tester);
          expect(image.memCacheWidth, decodeWidth);
          expect(image.memCacheHeight, isNull);
          expect(image.imageUrl, 'https://image.tmdb.org/t/p/$size/poster.jpg');
        },
      );
    }

    testWidgets('is never requested larger than w500', (tester) async {
      await _pumpImage(
        tester,
        const MediaImage(path: '/poster.jpg', width: 213, height: 320),
        devicePixelRatio: 3,
      );

      final image = _networkImage(tester);
      expect(image.imageUrl, contains('/w500/'));
    });
  });

  testWidgets('a bundled poster is decoded at its display width', (
    tester,
  ) async {
    await _pumpImage(
      tester,
      const MediaImage(
        path: 'asset:assets/demo/images/sintel-poster.webp',
        width: 130,
        height: 195,
      ),
      devicePixelRatio: 3,
    );

    final provider = tester.widget<Image>(find.byType(Image)).image;
    expect(provider, isA<ResizeImage>());
    expect((provider as ResizeImage).width, 390);
    expect(provider.height, isNull);
  });

  group('a network backdrop', () {
    testWidgets('is requested in the backdrop size', (tester) async {
      await _pumpImage(
        tester,
        const MediaImage.backdrop(path: '/still.jpg', width: 200, height: 120),
      );

      final image = _networkImage(tester);
      expect(image.imageUrl, 'https://image.tmdb.org/t/p/w780/still.jpg');
    });

    testWidgets('is decoded at its display width', (tester) async {
      await _pumpImage(
        tester,
        const MediaImage.backdrop(path: '/still.jpg', width: 200, height: 120),
      );

      final image = _networkImage(tester);
      expect(image.memCacheWidth, 600);
    });
  });

  testWidgets('a bundled backdrop renders from the app bundle', (tester) async {
    await _pumpImage(
      tester,
      const MediaImage.backdrop(path: _bundledBackdrop, width: 200),
    );

    expect(find.byType(CachedNetworkImage), findsNothing);
    final provider = tester.widget<Image>(find.byType(Image)).image;
    expect(
      (provider as ResizeImage).imageProvider,
      const AssetImage('assets/demo/images/sintel-backdrop.webp'),
    );
  });

  group('a colour blend', () {
    testWidgets('tints a network image', (tester) async {
      await _pumpImage(
        tester,
        const MediaImage.backdrop(
          path: '/backdrop.jpg',
          width: 200,
          color: _dim,
          colorBlendMode: BlendMode.modulate,
        ),
      );

      final image = _networkImage(tester);
      expect(image.color, _dim);
      expect(image.colorBlendMode, BlendMode.modulate);
    });

    testWidgets('tints a bundled image', (tester) async {
      await _pumpImage(
        tester,
        const MediaImage.backdrop(
          path: _bundledBackdrop,
          width: 200,
          color: _dim,
          colorBlendMode: BlendMode.modulate,
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.color, _dim);
      expect(image.colorBlendMode, BlendMode.modulate);
    });
  });

  group('a stand-in fills the image box', () {
    testWidgets('when there is no image', (tester) async {
      await _pumpImage(
        tester,
        const MediaImage(
          path: null,
          width: 120,
          height: 180,
          fallback: SizedBox(key: _standIn),
        ),
      );

      expect(tester.getSize(find.byKey(_standIn)), const Size(120, 180));
    });

    testWidgets('when a bundled image fails to load', (tester) async {
      await _pumpImage(
        tester,
        const MediaImage(
          path: 'asset:assets/demo/images/missing.webp',
          width: 120,
          height: 180,
          fallback: SizedBox(key: _standIn),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(_standIn)), const Size(120, 180));
    });

    testWidgets('while a network image loads', (tester) async {
      await _pumpImage(
        tester,
        const MediaImage(
          path: '/poster.jpg',
          width: 120,
          height: 180,
          placeholder: SizedBox(key: _standIn),
        ),
      );

      expect(tester.getSize(find.byKey(_standIn)), const Size(120, 180));
    });
  });
}
