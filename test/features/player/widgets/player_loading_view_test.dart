import 'dart:io';

import 'package:filmbuster/presentation/features/player/widgets/player_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

import '../../../support/app.dart';
import '../../../support/test_view.dart';

Future<void> _pump(WidgetTester tester) =>
    tester.pumpWidget(inApp(const PlayerLoadingView()));

void main() {
  test(
    'bundled reel animation parses as a 2 s Lottie without images',
    () async {
      final bytes = File(PlayerLoadingView.animationAsset).readAsBytesSync();

      final composition = await LottieComposition.fromBytes(bytes);

      expect(composition.duration, const Duration(seconds: 2));
      expect(composition.images, isEmpty);
    },
  );

  testWidgets('uses the reel animation and animates by default', (
    tester,
  ) async {
    await _pump(tester);

    final lottie = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
    expect(
      (lottie.lottie as AssetLottie).assetName,
      PlayerLoadingView.animationAsset,
    );
    expect(lottie.animate, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows a still frame when the platform reduces motion', (
    tester,
  ) async {
    reduceMotion(tester);
    await _pump(tester);

    expect(
      tester.widget<LottieBuilder>(find.byType(LottieBuilder)).animate,
      isFalse,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
