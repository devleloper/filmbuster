import 'package:filmbuster/presentation/widgets/app_buttons.dart';
import 'package:filmbuster/presentation/widgets/app_icon_button.dart';
import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/focus.dart';
import '../support/test_view.dart';

void main() {
  testWidgets('invokes onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      inApp(
        Center(
          child: PrimaryButton(
            onPressed: () => taps++,
            child: const Text('Watch'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Watch'));
    expect(taps, 1);
  });

  testWidgets('is inert and dimmed when disabled', (tester) async {
    await tester.pumpWidget(
      inApp(const Center(child: PrimaryButton(child: Text('Watch')))),
    );

    expect(
      tester.getSemantics(find.byType(PrimaryButton)),
      isSemantics(hasEnabledState: true, isEnabled: false, hasTapAction: false),
    );
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Watch'), matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, lessThan(1));
  });

  testWidgets('takes focus and activates on Enter, Space, Select and '
      'numpad Enter', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      inApp(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconButton(
                icon: Icons.arrow_back,
                semanticLabel: 'Back',
                onPressed: () {},
              ),
              PrimaryButton(
                onPressed: () => taps++,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );

    await pressTab(tester, 2);
    expect(focusIsIn(find.byType(PrimaryButton)), isTrue);

    for (final key in [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.select,
      LogicalKeyboardKey.numpadEnter,
    ]) {
      await tester.sendKeyEvent(key);
    }
    expect(taps, 4);
  });

  testWidgets('is skipped by traversal and announced as disabled without '
      'onPressed', (tester) async {
    await tester.pumpWidget(
      inApp(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconButton(
                icon: Icons.arrow_back,
                semanticLabel: 'Back',
                onPressed: () {},
              ),
              const PrimaryButton(child: Text('Retry')),
            ],
          ),
        ),
      ),
    );

    await pressTab(tester, 2);
    expect(focusIsIn(find.byType(PrimaryButton)), isFalse);
    expect(
      tester.getSemantics(find.byType(PrimaryButton)),
      isSemantics(
        label: 'Retry',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        isFocusable: false,
        hasTapAction: false,
      ),
    );
  });

  testWidgets('uses semanticLabel instead of its text when given', (
    tester,
  ) async {
    await tester.pumpWidget(
      inApp(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                semanticLabel: 'Play The Matrix',
                onPressed: () {},
                child: const Text('Play'),
              ),
              SecondaryButton(onPressed: () {}, child: const Text('Back')),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(PrimaryButton)),
      isSemantics(
        label: 'Play The Matrix',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.byType(SecondaryButton)),
      isSemantics(label: 'Back', isButton: true),
    );
  });

  testWidgets('keeps a 48 dp target with a small padding', (tester) async {
    await tester.pumpWidget(
      inApp(
        Center(
          child: PrimaryButton(
            onPressed: () {},
            padding: EdgeInsets.zero,
            child: const Text('Go'),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(PrimaryButton));
    expect(size.width, greaterThanOrEqualTo(kMinInteractiveDimension));
    expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));
  });

  group('with reduced motion', () {
    testWidgets('a pressed button shrinks instantly', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(
        inApp(
          Center(
            child: PrimaryButton(onPressed: () {}, child: const Text('Go')),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PrimaryButton)),
      );
      await tester.pump(kPressTimeout);
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);
      await gesture.up();
    });
  });
}
