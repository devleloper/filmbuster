import 'package:cached_network_image/cached_network_image.dart';
import 'package:filmbuster/presentation/features/player/widgets/player_seek_bar.dart';
import 'package:filmbuster/presentation/widgets/app_slider.dart';
import 'package:filmbuster/presentation/widgets/media_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';
import '../../../support/player_overlay_harness.dart';

// The drag preview is the bar's only image.
final _preview = find.byType(MediaImage);

Future<void> _pump(
  WidgetTester tester,
  double scale, {
  String? artworkPath,
}) async {
  await tester.pumpWidget(
    inApp(
      Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PlayerSeekBar(
            status: samplePlayback,
            onSeek: (_) {},
            artworkPath: artworkPath,
            scaleFactor: scale,
          ),
        ),
      ),
    ),
  );
}

void main() {
  // Phone portrait, phone landscape and tablet scale factors.
  for (final scale in [1.0, 1.15, 1.5]) {
    testWidgets('the drag preview clears the thumb at scale $scale', (
      tester,
    ) async {
      await _pump(tester, scale);
      final slider = tester.getRect(find.byType(AppSlider));
      final thumbRadius = tester
          .widget<AppSlider>(find.byType(AppSlider))
          .thumbRadius;

      final gesture = await tester.startGesture(slider.center);
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();

      expect(
        slider.center.dy - tester.getRect(_preview).bottom,
        greaterThan(thumbRadius),
      );

      await gesture.up();
      await tester.pump();
      expect(_preview, findsNothing);
    });
  }

  testWidgets('holding an arrow on the focused bar shows the preview', (
    tester,
  ) async {
    await _pump(tester, 1);
    await focusSeekBar(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_preview, findsOneWidget);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_preview, findsNothing);
  });

  testWidgets('the preview dims the poster without an opacity layer', (
    tester,
  ) async {
    await _pump(tester, 1, artworkPath: '/sintel-backdrop.jpg');
    final slider = tester.getRect(find.byType(AppSlider));
    final gesture = await tester.startGesture(slider.center);
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();

    expect(
      find.descendant(of: _preview, matching: find.byType(Opacity)),
      findsNothing,
    );
    final poster = tester.widget<CachedNetworkImage>(
      find.descendant(of: _preview, matching: find.byType(CachedNetworkImage)),
    );
    expect(poster.colorBlendMode, BlendMode.modulate);
    expect(poster.memCacheWidth, isNotNull);

    await gesture.up();
    await tester.pump();
  });
}
