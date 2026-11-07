import 'package:filmbuster/presentation/widgets/selectable_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/focus.dart';
import '../support/test_view.dart';

void main() {
  testWidgets('announces a checked option and reacts to taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      inApp(
        Center(
          child: SelectableRow(
            title: '1080p',
            subtitle: 'WEB-DL',
            isSelected: true,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(find.text('1080p'), findsOneWidget);
    expect(find.text('WEB-DL'), findsOneWidget);

    await tester.tap(find.text('1080p'));
    expect(taps, 1);

    expect(
      tester.getSemantics(find.bySemanticsLabel('1080p\nWEB-DL')),
      isSemantics(
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
  });

  Widget rows({required List<VoidCallback> onTaps}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (index, (title, code)) in [
        ('Off', null),
        ('English', 'en'),
        ('French', 'fr'),
      ].indexed)
        SelectableRow(
          title: title,
          subtitle: code == null ? null : 'Language: $code',
          isSelected: index == 1,
          autofocus: index == 1,
          onTap: onTaps[index],
        ),
    ],
  );

  testWidgets('starts focused on the selected option and moves with the '
      'arrows', (tester) async {
    final taps = [0, 0, 0];
    await tester.pumpWidget(
      inApp(
        Center(
          child: rows(
            onTaps: [() => taps[0]++, () => taps[1]++, () => taps[2]++],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(focusIsIn(find.widgetWithText(SelectableRow, 'English')), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(focusIsIn(find.widgetWithText(SelectableRow, 'French')), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, [0, 0, 1]);
  });

  testWidgets('is announced as a checked option of a single-choice group', (
    tester,
  ) async {
    await tester.pumpWidget(
      inApp(Center(child: rows(onTaps: [() {}, () {}, () {}]))),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('English\nLanguage: en')),
      isSemantics(
        label: 'English\nLanguage: en',
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
        isFocusable: true,
        hasTapAction: true,
        isButton: false,
        hasToggledState: false,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('French\nLanguage: fr')),
      isSemantics(hasCheckedState: true, isChecked: false),
    );
  });

  group('with reduced motion', () {
    testWidgets('a SelectableRow changes selection instantly', (tester) async {
      reduceMotion(tester);
      Widget row(bool selected) => inApp(
        Center(
          child: SelectableRow(
            title: 'English',
            isSelected: selected,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpWidget(row(false));

      await tester.pumpWidget(row(true));
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
