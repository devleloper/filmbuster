import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The narrowest phone the layout supports, for text-scale checks.
const compactPhone = Size(320, 640);

/// The iPhone the layout is designed on.
const referencePhone = Size(402, 874);

/// Sets the test view to [size] logical pixels for the rest of the test.
void useViewSize(WidgetTester tester, Size size, {double pixelRatio = 1}) {
  tester.view.physicalSize = size * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);
}

/// A 1080 x 2400 px Android phone at 2.625 device pixels per dp.
void usePhoneView(WidgetTester tester, {bool landscape = false}) {
  const pixelRatio = 2.625;
  final pixels = landscape ? const Size(2400, 1080) : const Size(1080, 2400);
  useViewSize(tester, pixels / pixelRatio, pixelRatio: pixelRatio);
}

/// Sets the platform text scale for the rest of the test.
void useTextScale(WidgetTester tester, double scale) {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Sets the platform accessibility features for the rest of the test.
void useAccessibilityFeatures(
  WidgetTester tester,
  FakeAccessibilityFeatures features,
) {
  tester.platformDispatcher.accessibilityFeaturesTestValue = features;
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Pumps [app] on the narrowest phone at double text size and expects no
/// overflow.
Future<void> expectFitsCompactPhoneAtDoubleText(
  WidgetTester tester,
  Widget app,
) async {
  useViewSize(tester, compactPhone);
  useTextScale(tester, 2);
  await tester.pumpWidget(app);
  expect(tester.takeException(), isNull);
}

void reduceMotion(WidgetTester tester) => useAccessibilityFeatures(
  tester,
  const FakeAccessibilityFeatures(disableAnimations: true),
);
