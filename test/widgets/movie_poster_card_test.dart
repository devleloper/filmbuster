import 'package:filmbuster/domain/models/tmdb_movie.dart';
import 'package:filmbuster/presentation/widgets/movie_poster_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/test_view.dart';

const _dune = TmdbMovie(
  id: 1,
  title: 'Dune',
  voteAverage: 8.15,
  releaseDate: '2021-09-15',
);

Future<void> _pumpCard(
  WidgetTester tester, {
  TmdbMovie movie = _dune,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  inApp(
    Center(
      child: MoviePosterCard(movie: movie, onTap: onTap ?? () {}),
    ),
  ),
);

void main() {
  testWidgets('renders title, rating and year', (tester) async {
    await _pumpCard(tester);

    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('8.2'), findsOneWidget);
    expect(find.text('2021'), findsOneWidget);
  });

  testWidgets('leaves out the year of a malformed release date', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      movie: const TmdbMovie(
        id: 1,
        title: 'Dune',
        voteAverage: 8.15,
        releaseDate: 'soon',
      ),
    );

    expect(find.text('soon'), findsNothing);
    expect(find.text('8.2'), findsOneWidget);
  });

  testWidgets('shows the placeholder when there is no poster', (tester) async {
    await _pumpCard(tester, movie: const TmdbMovie(id: 1, title: 'No Art'));

    expect(find.text('No Poster Available'), findsOneWidget);
  });

  testWidgets('is one button labelled by its text', (tester) async {
    await _pumpCard(tester);

    expect(
      tester.getSemantics(find.byType(MoviePosterCard)),
      isSemantics(label: 'Dune\n8.2\n2021', isButton: true),
    );
  });

  testWidgets('a tap and Enter each open the movie once', (tester) async {
    var opened = 0;
    await _pumpCard(tester, onTap: () => opened++);

    await tester.tap(find.text('Dune'));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(opened, 2);
  });

  testWidgets('grows with the text size', (tester) async {
    Future<double> cardHeight(double textScale) async {
      useTextScale(tester, textScale);
      await _pumpCard(tester);
      return tester.getSize(find.byType(MoviePosterCard)).height;
    }

    final regular = await cardHeight(1);

    expect(await cardHeight(2), greaterThan(regular));
  });

  testWidgets('fits a two-line title when the ambient style sets a line '
      'height', (tester) async {
    const movie = TmdbMovie(
      id: 1,
      title: 'A title long enough to take two lines',
      voteAverage: 8.15,
      releaseDate: '2021-09-15',
    );
    await tester.pumpWidget(
      inApp(
        Center(
          child: DefaultTextStyle.merge(
            style: const TextStyle(height: 1.5),
            child: MoviePosterCard(movie: movie, onTap: () {}),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('heightFor matches the laid-out card', (tester) async {
    useTextScale(tester, 1.5);
    await _pumpCard(tester);

    final card = find.byType(MoviePosterCard);
    expect(
      MoviePosterCard.heightFor(tester.element(card)),
      tester.getSize(card).height,
    );
  });
}
