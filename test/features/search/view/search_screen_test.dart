import 'package:filmbuster/core/router/app_router.dart';
import 'package:filmbuster/core/router/app_routes.dart';
import 'package:filmbuster/presentation/features/search/widgets/search_result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../support/app.dart';

void main() {
  useDemoDependencies();

  Future<GoRouter> searchForSintel(WidgetTester tester) async {
    final router = buildRouter();
    addTearDown(router.dispose);
    await pumpRouterApp(tester, router);
    router.go(AppRoutes.search);
    await pumpASecond(tester);
    await tester.enterText(find.byType(EditableText), 'sintel');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await pumpASecond(tester);
    return router;
  }

  testWidgets('opening Search puts the cursor in the search bar', (
    tester,
  ) async {
    final router = buildRouter();
    addTearDown(router.dispose);
    await pumpRouterApp(tester, router);
    await pumpASecond(tester);

    router.go(AppRoutes.search);
    await pumpASecond(tester);

    final searchBar = tester.widget<EditableText>(find.byType(EditableText));
    expect(searchBar.focusNode.hasPrimaryFocus, isTrue);
    await unmountApp(tester);
  });

  testWidgets('coming back on touch leaves the keyboard down', (tester) async {
    final router = await searchForSintel(tester);
    FocusManager.instance.primaryFocus?.unfocus();

    await tester.tap(find.byType(SearchResultCard).first);
    await pumpASecond(tester);
    router.pop();
    await pumpASecond(tester);

    expect(tester.testTextInput.isVisible, isFalse);
    await unmountApp(tester);
  });

  testWidgets(
    'coming back with a keyboard returns focus to the opened result',
    (tester) async {
      final router = await searchForSintel(tester);
      await tester.tap(find.byType(EditableText));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      final openedResult = FocusManager.instance.primaryFocus;

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpASecond(tester);
      router.pop();
      await pumpASecond(tester);

      expect(FocusManager.instance.primaryFocus, same(openedResult));
      await unmountApp(tester);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}
