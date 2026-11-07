import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/focusable_lift_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/focus.dart';
import '../support/test_view.dart';

void main() {
  testWidgets('is a button labelled by its text that lifts under focus '
      'and activates once on Enter', (tester) async {
    useKeyboardHighlight();
    var taps = 0;
    await tester.pumpWidget(
      inApp(
        Center(
          child: FocusableLiftCard(
            onTap: () => taps++,
            child: const SizedBox(
              width: 120,
              height: 180,
              child: Text('The Matrix'),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(FocusableLiftCard)),
      isSemantics(label: 'The Matrix', isButton: true),
    );

    await pressTab(tester);
    final scale = tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byType(FocusableLiftCard),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(scale.scale, AppFocus.liftScale);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  group('with reduced motion', () {
    testWidgets('a focused FocusableLiftCard lifts instantly', (tester) async {
      useKeyboardHighlight();
      final node = FocusNode();
      addTearDown(node.dispose);
      reduceMotion(tester);
      await tester.pumpWidget(
        inApp(
          Center(
            child: FocusableLiftCard(
              focusNode: node,
              onTap: () {},
              child: const SizedBox.square(dimension: 100),
            ),
          ),
        ),
      );

      node.requestFocus();
      await tester.pump();
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
