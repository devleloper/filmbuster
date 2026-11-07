import 'package:filmbuster/presentation/widgets/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/focus.dart';

void main() {
  testWidgets('taps and exposes an accessibility label', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      inApp(
        Center(
          child: AppIconButton(
            icon: Icons.arrow_back,
            semanticLabel: 'Back',
            onPressed: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(taps, 1);

    final semantics = tester.getSemantics(find.byType(AppIconButton));
    expect(semantics.label, 'Back');
  });

  testWidgets('activates on Enter for D-pad users', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      inApp(
        Center(
          child: AppIconButton(
            icon: Icons.play_arrow,
            semanticLabel: 'Play',
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    await pressTab(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('cannot be focused or tapped when disabled', (tester) async {
    await tester.pumpWidget(
      inApp(
        const Center(
          child: AppIconButton(
            icon: Icons.close,
            semanticLabel: 'Close',
            onPressed: null,
          ),
        ),
      ),
    );

    final focus = tester.widget<Focus>(
      find.descendant(
        of: find.byType(AppIconButton),
        matching: find.byType(Focus),
      ),
    );
    expect(focus.canRequestFocus, isFalse);
    expect(
      tester.getSemantics(find.byType(AppIconButton)),
      isSemantics(hasEnabledState: true, isEnabled: false, hasTapAction: false),
    );
  });
}
