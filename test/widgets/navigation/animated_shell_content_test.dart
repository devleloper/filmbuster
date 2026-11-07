import 'package:filmbuster/presentation/widgets/navigation/animated_shell_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/test_view.dart';

void main() {
  late FocusNode homeField;
  late FocusNode searchField;

  setUp(() {
    homeField = FocusNode(debugLabel: 'home');
    searchField = FocusNode(debugLabel: 'search');
  });

  tearDown(() {
    homeField.dispose();
    searchField.dispose();
  });

  Widget shell(int currentIndex) => inApp(
    AnimatedShellContent(
      currentIndex: currentIndex,
      children: [
        Focus(focusNode: homeField, child: const Text('Home')),
        Focus(focusNode: searchField, child: const Text('Search')),
      ],
    ),
  );

  testWidgets('a hidden branch takes no focus', (tester) async {
    await tester.pumpWidget(shell(0));

    searchField.requestFocus();
    await tester.pump();

    expect(searchField.hasFocus, isFalse);
  });

  testWidgets('switching away from a tab takes focus out of it', (
    tester,
  ) async {
    await tester.pumpWidget(shell(0));
    homeField.requestFocus();
    await tester.pump();
    expect(homeField.hasFocus, isTrue);

    await tester.pumpWidget(shell(1));
    await tester.pumpAndSettle();

    expect(homeField.hasFocus, isFalse);
  });

  group('with reduced motion', () {
    testWidgets('switching tabs is instant', (tester) async {
      reduceMotion(tester);
      Widget shell(int currentIndex) => inApp(
        Center(
          child: SizedBox.expand(
            child: AnimatedShellContent(
              currentIndex: currentIndex,
              children: const [Text('Home'), Text('Search')],
            ),
          ),
        ),
      );
      await tester.pumpWidget(shell(0));

      await tester.pumpWidget(shell(1));
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
