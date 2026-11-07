import 'package:filmbuster/domain/models/tmdb_movie.dart';
import 'package:filmbuster/presentation/widgets/movie_poster_card.dart';
import 'package:filmbuster/presentation/widgets/movie_poster_reel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/mocks.dart';
import '../support/opacity.dart';
import '../support/test_view.dart';

final _manyMovies = Fixtures.movies(20);

/// Pumps the reel on an iPhone Pro sized view.
Future<void> _pumpReel(WidgetTester tester) async {
  useViewSize(tester, referencePhone, pixelRatio: 3);
  await tester.pumpWidget(
    inApp(
      MoviePosterReel(movies: _manyMovies, onMovieTap: (_) {}, staggered: true),
    ),
  );
}

ScrollPosition _reelPosition(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable)).position;

Future<void> _flingToEnd(WidgetTester tester) async {
  final position = _reelPosition(tester);
  while (position.extentAfter > 0) {
    await tester.fling(find.byType(ListView), const Offset(-600, 0), 2000);
    await tester.pumpAndSettle();
  }
}

int _mountedCards() =>
    find.byType(MoviePosterCard, skipOffstage: false).evaluate().length;

double _firstCardOpacity(WidgetTester tester) =>
    paintedOpacityOf(tester, find.byType(MoviePosterCard).first);

void main() {
  group('with a few movies', () {
    final movies = Fixtures.movies(3);

    testWidgets('reports the tapped movie', (tester) async {
      TmdbMovie? opened;
      await tester.pumpWidget(
        inApp(
          Center(
            child: MoviePosterReel(
              movies: movies,
              onMovieTap: (m) => opened = m,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open movie 2'));

      expect(opened, movies[1]);
    });

    testWidgets('renders nothing without movies', (tester) async {
      await tester.pumpWidget(
        inApp(
          Center(
            child: MoviePosterReel(
              movies: const [],
              title: 'Popular',
              onMovieTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Popular'), findsNothing);
    });
  });

  group('scrolling a long reel', () {
    testWidgets('keeps only the cards near the viewport mounted', (
      tester,
    ) async {
      await _pumpReel(tester);
      await tester.pumpAndSettle();

      await _flingToEnd(tester);

      expect(_mountedCards(), lessThanOrEqualTo(8));
    });

    testWidgets('the first cards fade in one after another', (tester) async {
      await _pumpReel(tester);
      await tester.pump();

      expect(_firstCardOpacity(tester), lessThan(1));
      await tester.pumpAndSettle();
      expect(_firstCardOpacity(tester), 1);
    });

    testWidgets('cards scrolled back into view do not enter again', (
      tester,
    ) async {
      await _pumpReel(tester);
      await tester.pumpAndSettle();
      await _flingToEnd(tester);

      _reelPosition(tester).jumpTo(0);
      await tester.pump();

      expect(_firstCardOpacity(tester), 1);
    });

    testWidgets('cards appear without an entrance when motion is reduced', (
      tester,
    ) async {
      reduceMotion(tester);

      await _pumpReel(tester);
      await tester.pump();

      expect(_firstCardOpacity(tester), 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
