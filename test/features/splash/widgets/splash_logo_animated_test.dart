import 'package:filmbuster/presentation/features/splash/widgets/splash_logo_animated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_view.dart';

void main() {
  Future<void> pumpLogo(WidgetTester tester, VoidCallback onComplete) =>
      tester.pumpWidget(
        MaterialApp(home: SplashLogoAnimated(onAnimationComplete: onComplete)),
      );

  testWidgets('the logo moves into the header before handing over', (
    tester,
  ) async {
    var completed = false;
    await pumpLogo(tester, () => completed = true);

    await tester.pump(SplashLogoAnimated.duration ~/ 2);
    expect(completed, isFalse);

    await tester.pump(SplashLogoAnimated.duration);
    expect(completed, isTrue);
  });

  testWidgets('with reduced motion the logo hands over after one frame', (
    tester,
  ) async {
    reduceMotion(tester);
    var completed = false;

    await pumpLogo(tester, () => completed = true);

    expect(completed, isTrue);
  });
}
