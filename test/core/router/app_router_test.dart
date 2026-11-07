import 'dart:async';

import 'package:filmbuster/core/di/injector.dart';
import 'package:filmbuster/core/router/app_router.dart';
import 'package:filmbuster/core/router/app_routes.dart';
import 'package:filmbuster/core/router/route_args.dart';
import 'package:filmbuster/domain/models/player_source.dart';
import 'package:filmbuster/presentation/features/about/view/about_screen.dart';
import 'package:filmbuster/presentation/features/detail/view/detail_screen.dart';
import 'package:filmbuster/presentation/features/home/layouts/home_layout.dart';
import 'package:filmbuster/presentation/features/person/view/person_screen.dart';
import 'package:filmbuster/presentation/features/player/services/playback_engine.dart';
import 'package:filmbuster/presentation/features/player/view/player_screen.dart';
import 'package:filmbuster/presentation/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/app.dart';
import '../../support/fake_playback_engine.dart';

const _bigBuckBunny = 10378;
const _director = 1;

/// A source the player rejects at once, so no playback starts.
const _emptySource = PlayerRouteArgs(
  source: PlayerSource(url: '', label: ''),
);

void main() {
  useDemoDependencies();

  late GoRouter router;

  setUp(() => router = buildRouter());
  tearDown(() => router.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    await pumpASecond(tester);
  }

  Future<void> open(
    WidgetTester tester,
    String location, {
    Object? extra,
  }) async {
    unawaited(router.push(location, extra: extra));
    await pumpASecond(tester);
  }

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('/player without PlayerRouteArgs redirects to home', (
    tester,
  ) async {
    await pumpApp(tester);

    router.go(AppRoutes.player);
    await tester.pump();
    await tester.pump();

    expect(location(), AppRoutes.home);
    await unmountApp(tester);
  });

  testWidgets('/player with a foreign extra redirects to home', (tester) async {
    await pumpApp(tester);

    router.go(AppRoutes.player, extra: 'not-args');
    await tester.pump();
    await tester.pump();

    expect(location(), AppRoutes.home);
    await unmountApp(tester);
  });

  testWidgets('Escape in the search bar leaves Search for Home', (
    tester,
  ) async {
    await pumpApp(tester);
    router.go(AppRoutes.search);
    await tester.pump();
    await tester.tap(find.byType(EditableText));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(location(), AppRoutes.home);
    await unmountApp(tester);
  });

  group('a screen opened from a tab covers the tab bar:', () {
    final screens = {
      'Detail': (AppRoutes.detail(_bigBuckBunny), DetailScreen),
      'Person': (AppRoutes.person(_director), PersonScreen),
      'About': (AppRoutes.about, AboutScreen),
    };
    for (final MapEntry(key: name, value: (path, screen)) in screens.entries) {
      testWidgets(name, (tester) async {
        await pumpApp(tester);

        await open(tester, path);

        expect(find.byType(screen), findsOneWidget);
        expect(find.byType(MainScreen), findsNothing);
        await unmountApp(tester);
      });
    }

    testWidgets('Player', (tester) async {
      getIt
        ..unregister<PlaybackEngine>()
        ..registerFactory<PlaybackEngine>(FakePlaybackEngine.new);
      await pumpApp(tester);

      await open(tester, AppRoutes.player, extra: _emptySource);

      expect(find.byType(PlayerScreen), findsOneWidget);
      expect(find.byType(MainScreen), findsNothing);
      await unmountApp(tester);
    });
  });

  testWidgets('closing Detail returns to Home where the user left it', (
    tester,
  ) async {
    await pumpApp(tester);
    final homeList = find
        .descendant(
          of: find.byType(HomeLayout),
          matching: find.byType(Scrollable),
        )
        .first;
    tester.state<ScrollableState>(homeList).position.jumpTo(100);
    await tester.pump();

    await open(tester, AppRoutes.detail(_bigBuckBunny));
    router.pop();
    await pumpASecond(tester);

    expect(location(), AppRoutes.home);
    expect(tester.state<ScrollableState>(homeList).position.pixels, 100);
    await unmountApp(tester);
  });
}
