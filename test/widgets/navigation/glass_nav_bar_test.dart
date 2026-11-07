import 'package:filmbuster/presentation/widgets/navigation/app_tab.dart';
import 'package:filmbuster/presentation/widgets/navigation/glass_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/focus.dart';

void main() {
  final layouts = {
    'bar': (ValueChanged<AppTab> onTap) =>
        GlassNavBar(currentTab: AppTab.home, onTap: onTap),
    'rail': (ValueChanged<AppTab> onTap) =>
        GlassNavBar.rail(currentTab: AppTab.home, onTap: onTap, expanded: true),
  };
  for (final MapEntry(key: layout, value: build) in layouts.entries) {
    testWidgets('labels its tabs and marks the active one ($layout)', (
      tester,
    ) async {
      final tapped = <AppTab>[];
      await tester.pumpWidget(inApp(Center(child: build(tapped.add))));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Home')),
        isSemantics(isButton: true, hasSelectedState: true, isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Search')),
        isSemantics(isButton: true, isSelected: false),
      );

      await pressTab(tester, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(tapped, [AppTab.search]);
    });

    testWidgets('pads its tabs evenly on every side ($layout)', (tester) async {
      await tester.pumpWidget(inApp(Center(child: build((_) {}))));

      final bar = tester.getRect(find.byType(GlassNavBar));
      final home = tester.getRect(find.bySemanticsLabel('Home'));
      expect(home.top - bar.top, home.left - bar.left);
    });
  }

  testWidgets('marks the active tab with more than colour', (tester) async {
    await tester.pumpWidget(
      inApp(
        Center(
          child: GlassNavBar(currentTab: AppTab.search, onTap: (_) {}),
        ),
      ),
    );

    final indicator = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.constraints == BoxConstraints.tight(const Size(16, 3)),
    );
    expect(indicator, findsOneWidget);
    expect(
      find.ancestor(of: indicator, matching: find.bySemanticsLabel('Search')),
      findsOneWidget,
    );
  });

  testWidgets('the rail is narrower while collapsed', (tester) async {
    Future<double> railWidth({required bool expanded}) async {
      await tester.pumpWidget(
        inApp(
          Align(
            alignment: Alignment.centerLeft,
            child: GlassNavBar.rail(
              currentTab: AppTab.home,
              onTap: (_) {},
              expanded: expanded,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(GlassNavBar)).width;
    }

    expect(await railWidth(expanded: true), GlassNavBar.railWidthExpanded);
    expect(await railWidth(expanded: false), GlassNavBar.railWidthCollapsed);
  });
}
