import 'dart:async';

import 'package:filmbuster/domain/models/tmdb_movie.dart';
import 'package:filmbuster/presentation/features/home/bloc/home_cubit.dart';
import 'package:filmbuster/presentation/features/home/layouts/home_layout.dart';
import 'package:filmbuster/presentation/widgets/feedback/status_views.dart';
import 'package:filmbuster/presentation/widgets/movie_poster_reel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/app.dart';
import '../../../support/mocks.dart';
import '../../../support/opacity.dart';
import '../../../support/test_view.dart';

final _movies = Fixtures.movies(3);

void main() {
  late MockMovieRepository repository;

  setUp(() {
    repository = MockMovieRepository();
    repository.stubCatalogues(_movies);
  });

  Future<HomeCubit> pumpLayout(
    WidgetTester tester, {
    HomeRefresh refresh = HomeRefresh.pull,
    Duration settle = const Duration(seconds: 1),
  }) async {
    final cubit = HomeCubit(repository);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      afterSplash(
        BlocProvider.value(
          value: cubit,
          child: HomeLayout(refresh: refresh),
        ),
      ),
    );
    await cubit.load();
    await tester.pump(settle);
    return cubit;
  }

  testWidgets('with reduced motion the rails appear at once', (tester) async {
    reduceMotion(tester);

    await pumpLayout(tester, settle: Duration.zero);

    final rails = find.byType(MoviePosterReel);
    expect(rails, findsWidgets);
    for (final rail in rails.evaluate()) {
      expect(paintedOpacityOf(tester, find.byWidget(rail.widget)), 1);
    }
    await unmountApp(tester);
  });

  testWidgets('touch reloads by pulling the list, without a Reload button', (
    tester,
  ) async {
    await pumpLayout(tester, refresh: HomeRefresh.pull);

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Reload'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('leanback reloads with a Reload button in the header', (
    tester,
  ) async {
    await pumpLayout(tester, refresh: HomeRefresh.button);
    expect(find.byType(RefreshIndicator), findsNothing);
    final reloaded = Completer<List<TmdbMovie>>();
    when(repository.getPopular).thenAnswer((_) => reloaded.future);

    await tester.tap(find.bySemanticsLabel('Reload'));
    await tester.pump();
    expect(find.byType(LoadingStateView), findsOneWidget);

    reloaded.complete(_movies);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MoviePosterReel), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets('an empty catalogue explains itself and offers Reload', (
    tester,
  ) async {
    repository.stubCatalogues(const []);
    await pumpLayout(tester);

    expect(find.text('Nothing to show yet'), findsOneWidget);

    when(repository.getPopular).thenAnswer((_) async => _movies);
    await tester.tap(find.text('Reload'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Nothing to show yet'), findsNothing);
    expect(find.byType(MoviePosterReel), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets('a media change the rails do not use leaves them as they are', (
    tester,
  ) async {
    await pumpLayout(tester);
    final rail = tester.widget(find.byType(MoviePosterReel).first);

    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();

    expect(tester.widget(find.byType(MoviePosterReel).first), same(rail));
    await unmountApp(tester);
  });
}
