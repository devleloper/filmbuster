import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The opacity [finder]'s widget is painted with: the product of every fade
/// above it.
double paintedOpacityOf(WidgetTester tester, Finder finder) {
  var opacity = 1.0;
  final fades = find.ancestor(
    of: finder,
    matching: find.byType(FadeTransition),
  );
  for (final fade in tester.widgetList<FadeTransition>(fades)) {
    opacity *= fade.opacity.value;
  }
  final layers = find.ancestor(of: finder, matching: find.byType(Opacity));
  for (final layer in tester.widgetList<Opacity>(layers)) {
    opacity *= layer.opacity;
  }
  return opacity;
}
