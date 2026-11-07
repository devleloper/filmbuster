import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app.dart';
import 'test_view.dart';

Future<void> pumpInPhoneList(
  WidgetTester tester,
  Widget child, {
  double textScale = 1,
}) {
  usePhoneView(tester);
  useTextScale(tester, textScale);
  return tester.pumpWidget(
    inApp(
      ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [child]),
    ),
  );
}

/// Taps the centre and the four corners of the node labelled
/// [semanticLabel], where accessibility services and UI automation tap, and
/// expects each tap to activate the control.
Future<void> expectWholeNodeTappable(
  WidgetTester tester,
  String semanticLabel,
  int Function() taps,
) async {
  final node = tester.getSemantics(find.bySemanticsLabel(semanticLabel));
  final bounds = _semanticBounds(tester, node);

  expect(bounds.width, greaterThanOrEqualTo(kMinInteractiveDimension));
  expect(bounds.height, greaterThanOrEqualTo(kMinInteractiveDimension));

  // The pointer target and the accessibility node are the same rectangle.
  final semanticsWidget = find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.label == semanticLabel,
  );
  expect(tester.getRect(semanticsWidget), bounds);

  final inner = bounds.deflate(1);
  final points = <Offset>[
    bounds.center,
    inner.topLeft,
    inner.topRight,
    inner.bottomLeft,
    inner.bottomRight,
  ];
  for (final (i, point) in points.indexed) {
    await tester.tapAt(point);
    await tester.pump();
    expect(taps(), i + 1, reason: 'tap at $point inside $bounds');
  }
}

/// The node's bounds in logical pixels, as accessibility services see them:
/// the node rect mapped through every ancestor transform (the root one
/// includes the device pixel ratio), then divided by the ratio.
Rect _semanticBounds(WidgetTester tester, SemanticsNode node) {
  var rect = node.rect;
  for (SemanticsNode? n = node; n != null; n = n.parent) {
    final transform = n.transform;
    if (transform != null) rect = MatrixUtils.transformRect(transform, rect);
  }
  final dpr = tester.view.devicePixelRatio;
  return Rect.fromLTRB(
    rect.left / dpr,
    rect.top / dpr,
    rect.right / dpr,
    rect.bottom / dpr,
  );
}
