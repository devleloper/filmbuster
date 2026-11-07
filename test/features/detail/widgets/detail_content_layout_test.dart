import 'package:filmbuster/domain/models/tmdb_credit_person.dart';
import 'package:filmbuster/domain/models/tmdb_movie_details.dart';
import 'package:filmbuster/presentation/features/detail/bloc/detail_cubit.dart';
import 'package:filmbuster/presentation/features/detail/widgets/detail_content.dart';
import 'package:filmbuster/presentation/features/detail/widgets/detail_cover.dart';
import 'package:filmbuster/presentation/features/detail/widgets/persons_reel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';
import '../../../support/poppins.dart';
import '../../../support/test_view.dart';

const _detail = TmdbMovieDetails(
  id: 1,
  title: 'Sintel',
  overview:
      'A lonely young woman, Sintel, helps and befriends a dragon, whom she '
      'calls Scales. But when he is kidnapped by an adult dragon, Sintel '
      'decides to embark on a dangerous quest to find her lost friend.',
  cast: [TmdbCreditPerson(id: 2, name: 'Halina Reijn', character: 'Sintel')],
);

Future<void> _pumpDetail(WidgetTester tester, {required Size size}) async {
  useViewSize(tester, size);
  await tester.pumpWidget(
    inApp(
      DetailContent(
        detail: _detail,
        sources: const SourcesLoaded(),
        onBack: () {},
        onPlay: () {},
        onRetrySources: () {},
      ),
    ),
  );
}

void main() {
  setUpAll(loadPoppins);

  testWidgets('scrolling fades the title in without rebuilding the page', (
    tester,
  ) async {
    await _pumpDetail(tester, size: const Size(402, 400));
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(scroll.maxScrollExtent, greaterThanOrEqualTo(200));
    final cover = tester.widget<DetailCover>(find.byType(DetailCover));
    final persons = tester.widget<PersonsReel>(find.byType(PersonsReel));

    for (var offset = 10.0; offset <= 200; offset += 10) {
      scroll.jumpTo(offset);
      await tester.pump();
    }

    expect(
      tester.widget(find.byType(DetailCover)),
      same(cover),
      reason: 'the cover was rebuilt while scrolling',
    );
    expect(
      tester.widget(find.byType(PersonsReel)),
      same(persons),
      reason: 'the cast reel was rebuilt while scrolling',
    );
    final title = tester.widget<Opacity>(
      find.widgetWithText(Opacity, 'Sintel'),
    );
    expect(title.opacity, greaterThan(0));
  });

  testWidgets('the overview keeps a readable line length on wide screens', (
    tester,
  ) async {
    await _pumpDetail(tester, size: const Size(1366, 1024));

    expect(
      tester.getSize(find.text(_detail.overview!)).width,
      lessThanOrEqualTo(720),
    );
  });
}
