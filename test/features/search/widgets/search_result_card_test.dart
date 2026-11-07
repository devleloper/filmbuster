import 'package:cached_network_image/cached_network_image.dart';
import 'package:filmbuster/domain/models/tmdb_movie.dart';
import 'package:filmbuster/presentation/features/search/widgets/search_result_card.dart';
import 'package:filmbuster/presentation/widgets/no_poster_placeholder.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';
import '../../../support/test_view.dart';
import '../../../support/text_layout.dart';

Future<void> _pumpCard(WidgetTester tester, {required String poster}) async {
  useViewSize(tester, referencePhone, pixelRatio: 3);
  await tester.pumpWidget(
    inApp(
      SearchResultCard(
        movie: TmdbMovie(
          id: 1,
          title: 'Sintel',
          posterPath: poster,
          releaseDate: '2010-09-30',
          voteAverage: 7.2,
          overview: 'A lonely young woman searches for her baby dragon.',
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('decodes the poster at its display size from w342', (
    tester,
  ) async {
    await _pumpCard(tester, poster: '/sintel.jpg');

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, 270);
    expect(image.imageUrl, 'https://image.tmdb.org/t/p/w342/sintel.jpg');
  });

  testWidgets('sets the title in bold', (tester) async {
    await _pumpCard(tester, poster: '/sintel.jpg');

    expect(
      drawnStyleOf(tester, find.text('Sintel')).fontWeight,
      FontWeight.w700,
    );
  });

  testWidgets('announces the title once, not again for the poster', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      poster: 'asset:assets/demo/images/sintel-poster.webp',
    );

    expect(find.bySemanticsLabel(RegExp('Sintel')), findsOneWidget);
  });

  testWidgets('a poster that fails to load gives way to the placeholder', (
    tester,
  ) async {
    await _pumpCard(tester, poster: '/missing.jpg');

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    final shownOnError = image.errorWidget!(
      tester.element(find.byType(CachedNetworkImage)),
      image.imageUrl,
      Exception('404'),
    );
    await tester.pumpWidget(inApp(shownOnError));

    expect(find.byType(NoPosterPlaceholder), findsOneWidget);
  });
}
