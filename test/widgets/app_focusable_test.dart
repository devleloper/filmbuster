import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/app_focusable.dart';
import 'package:filmbuster/presentation/widgets/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/contrast.dart';
import '../support/focus.dart';

void main() {
  group('focus ring', () {
    Widget iconButton({FocusNode? focusNode}) => AppIconButton(
      icon: Icons.play_arrow,
      semanticLabel: 'Play',
      focusNode: focusNode,
      onPressed: () {},
    );

    testWidgets('draws a black halo, then the yellow ring, around the '
        'focused control', (tester) async {
      useKeyboardHighlight();
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        inApp(Center(child: iconButton(focusNode: node))),
      );
      expect(
        find.byType(AppIconButton),
        isNot(paints..rrect(color: AppFocus.ringColor)),
      );

      node.requestFocus();
      await tester.pump();

      expect(
        find.byType(AppIconButton),
        paints
          ..rrect(color: AppFocus.haloColor)
          ..rrect(color: AppFocus.ringColor),
      );
    });

    testWidgets('stays hidden while the user navigates by touch', (
      tester,
    ) async {
      useHighlightStrategy(FocusHighlightStrategy.alwaysTouch);
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        inApp(Center(child: iconButton(focusNode: node))),
      );

      node.requestFocus();
      await tester.pump();

      expect(node.hasFocus, isTrue);
      expect(
        find.byType(AppIconButton),
        isNot(paints..rrect(color: AppFocus.ringColor)),
      );
    });

    test('keeps 3:1 against the background and 9:1 between its colours', () {
      expect(
        contrastRatio(AppFocus.ringColor, AppColors.background),
        greaterThanOrEqualTo(3),
      );
      expect(
        contrastRatio(AppFocus.ringColor, AppFocus.haloColor),
        greaterThanOrEqualTo(9),
      );
    });
  });

  group('a held activation key', () {
    const keys = [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.select,
    ];
    for (final key in keys) {
      testWidgets('activates the control once and its repeats reach no '
          'screen shortcut (${key.debugName})', (tester) async {
        var presses = 0;
        var screenShortcuts = 0;
        await tester.pumpWidget(
          inApp(
            Shortcuts(
              shortcuts: {SingleActivator(key): const _ScreenIntent()},
              child: Actions(
                actions: {
                  _ScreenIntent: CallbackAction<_ScreenIntent>(
                    onInvoke: (_) => screenShortcuts++,
                  ),
                },
                child: Center(
                  child: AppFocusable(
                    onPressed: () => presses++,
                    autofocus: true,
                    semanticLabel: 'Play',
                    child: const SizedBox.square(dimension: 48),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.sendKeyDownEvent(key);
        await tester.sendKeyRepeatEvent(key);
        await tester.sendKeyRepeatEvent(key);
        await tester.sendKeyUpEvent(key);

        expect(presses, 1);
        expect(screenShortcuts, 0);
      });
    }
  });
}

class _ScreenIntent extends Intent {
  const _ScreenIntent();
}
