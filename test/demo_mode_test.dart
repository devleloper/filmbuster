import 'package:filmbuster/core/router/app_router.dart';
import 'package:filmbuster/core/router/app_routes.dart';
import 'package:filmbuster/core/router/route_args.dart';
import 'package:filmbuster/core/utils/tmdb_image_url.dart';
import 'package:filmbuster/presentation/features/about/view/about_screen.dart';
import 'package:filmbuster/presentation/features/detail/view/detail_screen.dart';
import 'package:filmbuster/presentation/features/search/widgets/search_result_card.dart';
import 'package:filmbuster/presentation/widgets/attribution/tmdb_attribution.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app.dart';
import 'support/disk_assets.dart';
import 'support/test_view.dart';

void main() {
  useDemoDependencies();

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    GoRouter? router,
    bool splashComplete = false,
  }) async {
    router ??= buildRouter();
    addTearDown(router.dispose);
    await pumpRouterApp(tester, router, splashComplete: splashComplete);
    await pumpASecond(tester);
    return router;
  }

  testWidgets('Home shows the demo badge and catalogue rails', (tester) async {
    await pumpApp(tester);

    expect(find.text('Demo catalog'), findsOneWidget);
    expect(find.text('Open movies'), findsOneWidget);
    expect(find.text('Sintel'), findsWidgets);

    await unmountApp(tester);
  });

  testWidgets('Search finds a catalogue title', (tester) async {
    final router = await pumpApp(tester);
    router.go(AppRoutes.search);
    await pumpASecond(tester);

    await tester.enterText(find.byType(EditableText), 'tears steel');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await pumpASecond(tester);

    Finder result(String title) => find.descendant(
      of: find.byType(SearchResultCard),
      matching: find.text(title),
    );
    expect(result('Tears of Steel'), findsOneWidget);
    expect(find.byType(SearchResultCard), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('Detail shows Play with credit and opens the player', (
    tester,
  ) async {
    PlayerRouteArgs? opened;
    await pumpApp(
      tester,
      router: _detailOnly(45745, onPlayer: (args) => opened = args),
    );

    expect(find.text('Sintel'), findsWidgets);
    expect(find.text('CC BY 3.0'), findsOneWidget);
    expect(find.text('Trailer'), findsNothing);
    final play = find.text('Play');
    expect(play, findsOneWidget);

    await tester.ensureVisible(play);
    await tester.tap(play);
    await pumpASecond(tester);

    final sources = bundledCatalogContents().sources[45745]!;
    final source = sources.first;
    expect(find.text('player'), findsOneWidget);
    expect(opened, isNotNull);
    expect(opened!.source.url, source.url.toString());
    expect(opened!.source.label, '${source.quality} · Open movies');
    expect(opened!.sources.map((s) => s.url), [
      for (final s in sources) s.url.toString(),
    ]);
    expect(opened!.movieTitle, 'Sintel');
    expect(opened!.artworkPath, startsWith(TmdbImageUrl.bundledPrefix));

    await unmountApp(tester);
  });

  testWidgets('Home opens About with TMDB notice, credits and licenses', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.bySemanticsLabel('About and credits'));
    await pumpASecond(tester);

    expect(find.text(TmdbAttribution.notice), findsOneWidget);
    final catalog = bundledCatalogContents();
    final list = find.byType(Scrollable).last;
    for (final movie in catalog.openMovies.values) {
      await tester.scrollUntilVisible(
        find.text(movie.attribution),
        200,
        scrollable: list,
      );
      expect(find.text(movie.attribution), findsOneWidget);
    }

    final licenses = find.text('Open-source licenses');
    await tester.scrollUntilVisible(licenses, 200, scrollable: list);
    await tester.tap(licenses);
    await pumpASecond(tester);
    expect(find.byType(LicensePage), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('Home keeps About reachable on a phone at 200 % text', (
    tester,
  ) async {
    useViewSize(tester, const Size(360, 800));
    useTextScale(tester, 2);

    await pumpApp(tester, splashComplete: true);
    expect(tester.takeException(), isNull);

    final about = find.bySemanticsLabel('About and credits');
    expect(tester.getRect(about).right, lessThanOrEqualTo(360));
    await tester.tap(about);
    await pumpASecond(tester);
    expect(find.byType(AboutScreen), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('an unknown movie shows the error view, not Play', (
    tester,
  ) async {
    await pumpApp(tester, router: _detailOnly(1));

    expect(find.text('Movie not found.'), findsOneWidget);
    expect(find.text('Play'), findsNothing);

    await unmountApp(tester);
  });
}

/// Detail for movie [id] alone; Play hands its arguments to [onPlayer].
GoRouter _detailOnly(int id, {ValueSetter<PlayerRouteArgs?>? onPlayer}) =>
    GoRouter(
      initialLocation: AppRoutes.detail(id),
      routes: [
        GoRoute(
          path: AppRoutes.detailPattern,
          builder: (_, state) =>
              DetailScreen(id: int.parse(state.pathParameters['id']!)),
        ),
        if (onPlayer != null)
          GoRoute(
            path: AppRoutes.player,
            builder: (_, state) {
              onPlayer(state.extra as PlayerRouteArgs?);
              return const Text('player');
            },
          ),
      ],
    );
