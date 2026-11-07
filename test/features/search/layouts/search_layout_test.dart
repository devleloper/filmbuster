import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/presentation/features/search/bloc/search_cubit.dart';
import 'package:filmbuster/presentation/features/search/layouts/search_layout.dart';
import 'package:filmbuster/presentation/features/search/widgets/search_result_card.dart';
import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/mocks.dart';
import '../../../support/opacity.dart';
import '../../../support/poppins.dart';
import '../../../support/test_view.dart';
import '../../../support/text_layout.dart';

final _results = Fixtures.movies(3);

void main() {
  late MockMovieRepository movies;

  setUpAll(loadPoppins);
  setUp(() => movies = MockMovieRepository());

  Future<SearchCubit> pumpSearch(WidgetTester tester) async {
    useViewSize(tester, referencePhone);
    final cubit = SearchCubit(movies);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: BlocProvider.value(value: cubit, child: const SearchLayout()),
      ),
    );
    return cubit;
  }

  testWidgets('the heading is 26 pt on a phone', (tester) async {
    await pumpSearch(tester);

    expect(drawnStyleOf(tester, find.text('Search')).fontSize, 26);
  });

  testWidgets('with reduced motion the results appear at once', (tester) async {
    reduceMotion(tester);
    when(() => movies.search('dune')).thenAnswer((_) async => _results);
    final cubit = await pumpSearch(tester);

    await cubit.search('dune');
    await tester.pump();

    final cards = find.byType(SearchResultCard);
    expect(cards, findsNWidgets(3));
    for (final card in cards.evaluate()) {
      expect(paintedOpacityOf(tester, find.byWidget(card.widget)), 1);
    }
  });

  testWidgets('results scrolled into view show at once, without an entrance', (
    tester,
  ) async {
    when(
      () => movies.search('open'),
    ).thenAnswer((_) async => Fixtures.movies(20));
    final cubit = await pumpSearch(tester);
    await cubit.search('open');
    await tester.pumpAndSettle();

    final list = tester.state<ScrollableState>(
      find
          .ancestor(
            of: find.byType(SearchResultCard).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    list.position.jumpTo(list.position.maxScrollExtent);
    await tester.pump();

    final cards = find.byType(SearchResultCard).hitTestable();
    expect(cards, findsWidgets);
    for (final card in cards.evaluate()) {
      expect(paintedOpacityOf(tester, find.byWidget(card.widget)), 1);
    }
  });

  testWidgets('Retry repeats a search that failed', (tester) async {
    when(() => movies.search('dune')).thenThrow(const NetworkFailure());
    final cubit = await pumpSearch(tester);
    await cubit.search('dune');
    await tester.pump();

    when(() => movies.search('dune')).thenAnswer((_) async => _results);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchResultCard), findsNWidgets(3));
  });

  testWidgets('no results name the query and suggest what to try', (
    tester,
  ) async {
    when(() => movies.search(any())).thenAnswer((_) async => []);
    final cubit = await pumpSearch(tester);
    await cubit.search('xyz');
    await tester.pump();

    expect(find.text('No results for “xyz”'), findsOneWidget);
    expect(
      find.text('Check the spelling or try another title.'),
      findsOneWidget,
    );
  });

  testWidgets('a media change the results do not use leaves them as they are', (
    tester,
  ) async {
    when(() => movies.search(any())).thenAnswer((_) async => _results);
    final cubit = await pumpSearch(tester);
    await cubit.search('movie');
    await tester.pumpAndSettle();
    final card = tester.widget(find.byType(SearchResultCard).first);

    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();

    expect(tester.widget(find.byType(SearchResultCard).first), same(card));
  });
}
