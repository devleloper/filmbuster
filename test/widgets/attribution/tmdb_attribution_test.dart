import 'dart:io';

import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/attribution/tmdb_attribution.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/disk_assets.dart';

Widget _attribution() => inApp(
  DefaultAssetBundle(
    bundle: DiskAssetBundle(),
    child: const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: TmdbAttribution(logoHeight: 12),
    ),
  ),
);

void main() {
  testWidgets('shows the exact notice and keeps the logo out of semantics', (
    tester,
  ) async {
    await tester.pumpWidget(_attribution());

    expect(
      find.text(
        'This product uses TMDB and the TMDB APIs but is not endorsed, '
        'certified, or otherwise approved by TMDB.',
      ),
      findsOneWidget,
    );
    final logo = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(logo.excludeFromSemantics, isTrue);
    expect(logo.height, 12);
    expect(logo.width, closeTo(12 * 273.42 / 35.52, 0.01));
  });

  testWidgets('the logo asset renders the TMDB gradient, not black', (
    tester,
  ) async {
    final svg = File(TmdbAttribution.logoAsset).readAsStringSync();
    final pixels = await tester.runAsync(() async {
      final info = await vg.loadPicture(SvgStringLoader(svg), null);
      final image = await info.picture.toImage(274, 36);
      info.picture.dispose();
      final data = await image.toByteData();
      image.dispose();
      return data!;
    });

    Color at(int x, int y) {
      final i = (y * 274 + x) * 4;
      return Color.fromARGB(
        pixels!.getUint8(i + 3),
        pixels.getUint8(i),
        pixels.getUint8(i + 1),
        pixels.getUint8(i + 2),
      );
    }

    // Inside the "T" stem: green end of the gradient (#90CEA1).
    final left = at(14, 20);
    // Inside the rounded rectangle: blue end (#00B3E5).
    final right = at(224, 6);
    expect(left.a, 1.0);
    expect(right.a, 1.0);
    expect(left.g, greaterThan(0.6));
    expect(right.b, greaterThan(0.75));
    expect(right.r, lessThan(0.3));
  });
}
