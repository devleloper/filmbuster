import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/core/licenses/content_credits.dart';
import 'package:filmbuster/domain/models/tmdb_movie_details.dart';
import 'package:filmbuster/domain/models/tmdb_trailer.dart';
import 'package:filmbuster/presentation/features/detail/bloc/detail_cubit.dart';
import 'package:filmbuster/presentation/features/detail/widgets/detail_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/api_json.dart';
import '../../../support/app.dart';
import '../../../support/disk_assets.dart';
import '../../../support/mocks.dart';
import '../../../support/recording_url_launcher.dart';

void main() {
  final source = Fixtures.source();
  final trailer = TmdbTrailer.fromJson(trailerJson());
  late RecordingUrlLauncher launcher;

  setUp(() => launcher = useRecordingUrlLauncher());

  Future<void> pump(
    WidgetTester tester, {
    required SourcesStatus sources,
    TmdbMovieDetails detail = Fixtures.movieDetails,
    VoidCallback? onPlay,
    VoidCallback? onRetry,
  }) async {
    await tester.pumpWidget(
      inApp(
        DetailContent(
          detail: detail,
          sources: sources,
          onBack: () {},
          onPlay: onPlay ?? () {},
          onRetrySources: onRetry ?? () {},
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Play and the license credit show for a playable source', (
    tester,
  ) async {
    var played = 0;
    await pump(
      tester,
      sources: SourcesLoaded(playable: [source]),
      onPlay: () => played++,
    );

    expect(find.text('Play'), findsOneWidget);
    expect(find.text('CC BY 3.0'), findsOneWidget);
    expect(find.text('Sources unavailable.'), findsNothing);

    await tester.tap(find.text('Play'));
    expect(played, 1);

    await tester.tap(find.text('studio.example.org'));
    await tester.pump();
    expect(launcher.launched, [source.sourcePageUrl]);
  });

  testWidgets('nothing is offered while sources load or when there are none', (
    tester,
  ) async {
    await pump(tester, sources: const SourcesLoading());
    expect(find.text('Play'), findsNothing);
    expect(find.text('Sources unavailable.'), findsNothing);

    await pump(tester, sources: const SourcesLoaded());
    expect(find.text('Play'), findsNothing);
    expect(find.text('Sources unavailable.'), findsNothing);
  });

  testWidgets('a failure or an empty partial answer offers Retry', (
    tester,
  ) async {
    var retried = 0;
    await pump(
      tester,
      sources: const SourcesFailed(NetworkFailure(message: 'offline')),
      onRetry: () => retried++,
    );
    expect(find.text('Play'), findsNothing);
    expect(find.text('Sources unavailable.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, 1);

    await pump(tester, sources: const SourcesLoaded(partial: true));
    expect(find.text('Sources unavailable.'), findsOneWidget);
  });

  testWidgets('Trailer opens the first trailer outside the app', (
    tester,
  ) async {
    await pump(
      tester,
      sources: const SourcesLoaded(),
      detail: TmdbMovieDetails(id: 1, title: 'Dune', trailers: [trailer]),
    );

    final link = find.text('Trailer');
    expect(link, findsOneWidget);
    await tester.tap(link);
    await tester.pump();
    expect(launcher.launched, [trailer.url]);
  });

  for (final title in ['Dune', 'The Matrix']) {
    testWidgets('Trailer is announced as "$title trailer", one article', (
      tester,
    ) async {
      await pump(
        tester,
        sources: const SourcesLoaded(),
        detail: TmdbMovieDetails(id: 1, title: title, trailers: [trailer]),
      );

      expect(find.semantics.byLabel('$title trailer'), findsOne);
      expect(find.semantics.byLabel(RegExp('Watch the')), findsNothing);
    });
  }

  testWidgets('no Trailer without trailers', (tester) async {
    await pump(tester, sources: const SourcesLoaded());
    expect(find.text('Trailer'), findsNothing);
  });

  testWidgets('every catalogue film credits its licensor, license and edits', (
    tester,
  ) async {
    final catalog = bundledCatalogContents();
    expect(catalog.ordered, isNotEmpty);
    for (final detail in catalog.ordered) {
      final movie = catalog.openMovies[detail.id]!;
      await pump(
        tester,
        detail: detail,
        sources: SourcesLoaded(playable: catalog.sources[detail.id]!),
      );

      expect(find.text(movie.attribution), findsOneWidget, reason: movie.title);
      expect(
        find.text(movie.license.name),
        findsOneWidget,
        reason: movie.title,
      );
      expect(find.text(derivedImagesNote), findsOneWidget, reason: movie.title);
    }
  });

  testWidgets('TMDB images carry no edits note', (tester) async {
    await pump(tester, sources: SourcesLoaded(playable: [source]));

    expect(find.text(derivedImagesNote), findsNothing);
  });
}
