import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether the primary focus sits inside the single widget [finder] finds.
bool focusIsIn(Finder finder) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  final target = finder.evaluate().single;
  var inside = false;
  focused.visitAncestorElements((element) {
    inside = element == target;
    return !inside;
  });
  return inside;
}

/// Uses [strategy] to decide whether focus rings show, for the rest of the
/// test.
void useHighlightStrategy(FocusHighlightStrategy strategy) {
  FocusManager.instance.highlightStrategy = strategy;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

/// Shows focus rings as during keyboard or D-pad navigation for the rest of
/// the test.
void useKeyboardHighlight() =>
    useHighlightStrategy(FocusHighlightStrategy.alwaysTraditional);

Future<void> pressTab(WidgetTester tester, [int times = 1]) async {
  for (var i = 0; i < times; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  }
  await tester.pump();
}
