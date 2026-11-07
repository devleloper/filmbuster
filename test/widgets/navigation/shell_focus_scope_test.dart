import 'package:filmbuster/presentation/widgets/navigation/app_tab.dart';
import 'package:filmbuster/presentation/widgets/navigation/shell_focus_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget shell(AppTab currentTab, FocusNode home, FocusNode search) {
    return MaterialApp(
      home: ShellFocusScope(
        currentTab: currentTab,
        entries: {AppTab.home: home},
        child: Builder(
          builder: (context) {
            ShellFocusScope.registerEntry(context, AppTab.search, search);
            return Column(
              children: [
                Focus(focusNode: home, child: const Text('Home')),
                Focus(focusNode: search, child: const Text('Search')),
              ],
            );
          },
        ),
      ),
    );
  }

  testWidgets('focuses the entry node of the tab the user opens', (
    tester,
  ) async {
    final home = FocusNode();
    final search = FocusNode();
    addTearDown(home.dispose);
    addTearDown(search.dispose);
    await tester.pumpWidget(shell(AppTab.home, home, search));

    await tester.pumpWidget(shell(AppTab.search, home, search));
    await tester.pump();
    expect(search.hasPrimaryFocus, isTrue);

    await tester.pumpWidget(shell(AppTab.home, home, search));
    await tester.pump();
    expect(home.hasPrimaryFocus, isTrue);
  });

  testWidgets('leaves focus alone while the tab stays the same', (
    tester,
  ) async {
    final home = FocusNode();
    final search = FocusNode();
    addTearDown(home.dispose);
    addTearDown(search.dispose);
    await tester.pumpWidget(shell(AppTab.home, home, search));
    search.requestFocus();
    await tester.pump();

    await tester.pumpWidget(shell(AppTab.home, home, search));
    await tester.pump();

    expect(search.hasPrimaryFocus, isTrue);
  });
}
