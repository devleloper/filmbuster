import 'package:filmbuster/presentation/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/app.dart';

GoRouter _router() => GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Text('Home page'),
              routes: [
                GoRoute(
                  path: 'detail',
                  builder: (context, state) => const Text('Detail page'),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const Text('Search page'),
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  late GoRouter router;

  setUp(() => router = _router());
  tearDown(() => router.dispose());

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.bySemanticsLabel(label));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the current tab again returns to its first screen', (
    tester,
  ) async {
    await pumpRouterApp(tester, router, splashComplete: true);
    router.go('/detail');
    await tester.pumpAndSettle();
    expect(find.text('Detail page'), findsOneWidget);

    await tapTab(tester, 'Home');

    expect(find.text('Home page'), findsOneWidget);
    expect(find.text('Detail page'), findsNothing);
  });

  testWidgets('switching tabs keeps the other tab where it was', (
    tester,
  ) async {
    await pumpRouterApp(tester, router, splashComplete: true);
    router.go('/detail');
    await tester.pumpAndSettle();

    await tapTab(tester, 'Search');
    expect(find.text('Search page'), findsOneWidget);
    await tapTab(tester, 'Home');

    expect(find.text('Detail page'), findsOneWidget);
  });
}
