import 'package:filmbuster/domain/models/tmdb_movie.dart';
import 'package:filmbuster/presentation/features/home/widgets/hero_carousel.dart';
import 'package:filmbuster/presentation/widgets/focusable_lift_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../support/app.dart';
import '../../../support/mocks.dart';
import '../../../support/test_view.dart';
import '../../../support/text_layout.dart';

final _movies = Fixtures.movies(3);

final _oneAdvance = HeroCarousel.slideInterval + const Duration(seconds: 1);

Future<void> _pumpCarousel(
  WidgetTester tester, {
  List<TmdbMovie>? movies,
}) async {
  await tester.pumpWidget(
    inApp(HeroCarousel(movies: movies ?? _movies, onMovieTap: (_) {})),
  );
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
}

int _activeSlide(WidgetTester tester) => tester
    .widget<AnimatedSmoothIndicator>(find.byType(AnimatedSmoothIndicator))
    .activeIndex;

void main() {
  testWidgets('advances to the next slide on its own', (tester) async {
    await _pumpCarousel(tester);

    await tester.pump(_oneAdvance);
    await tester.pumpAndSettle();

    expect(_activeSlide(tester), 1);
  });

  testWidgets('shows the rating in bold', (tester) async {
    await _pumpCarousel(
      tester,
      movies: const [TmdbMovie(id: 1, title: 'Sintel', voteAverage: 7.2)],
    );

    expect(
      drawnStyleOf(tester, find.text('7.2').first).fontWeight,
      FontWeight.w700,
    );
  });

  testWidgets('advancing a slide rebuilds only the page indicator', (
    tester,
  ) async {
    await _pumpCarousel(tester);
    final mountedSlides = find.byType(FocusableLiftCard).evaluate().toSet();
    var slideRebuilds = 0;
    debugOnRebuildDirtyWidget = (element, _) {
      if (mountedSlides.contains(element)) slideRebuilds++;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    await tester.pump(_oneAdvance);
    await tester.pumpAndSettle();

    expect(_activeSlide(tester), 1);
    expect(slideRebuilds, 0);
  });

  testWidgets('slides keep their gap when the carousel is narrower than the '
      'screen', (tester) async {
    useViewSize(tester, const Size(1600, 900));
    await tester.pumpWidget(
      inApp(
        Row(
          children: [
            const SizedBox(width: 400),
            Expanded(
              child: HeroCarousel(movies: _movies, onMovieTap: (_) {}),
            ),
          ],
        ),
      ),
    );
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

    final slides = find.byType(FocusableLiftCard);
    final centres = [
      for (final slide in slides.evaluate())
        tester.getCenter(find.byWidget(slide.widget)).dx,
    ]..sort();
    final slideWidth = tester.getSize(slides.first).width;

    expect(centres[1] - centres[0], closeTo(slideWidth + 24, 1));
  });

  testWidgets('stays on the first slide when motion is reduced', (
    tester,
  ) async {
    reduceMotion(tester);
    await _pumpCarousel(tester);

    await tester.pump(_oneAdvance);
    await tester.pumpAndSettle();

    expect(_activeSlide(tester), 0);
    expect(find.bySemanticsLabel('Pause carousel'), findsNothing);
    expect(
      tester
          .widget<AnimatedSmoothIndicator>(find.byType(AnimatedSmoothIndicator))
          .duration,
      Duration.zero,
    );
  });

  testWidgets('stays on the first slide while a screen reader navigates', (
    tester,
  ) async {
    useAccessibilityFeatures(
      tester,
      const FakeAccessibilityFeatures(accessibleNavigation: true),
    );
    await _pumpCarousel(tester);

    await tester.pump(_oneAdvance);
    await tester.pumpAndSettle();

    expect(_activeSlide(tester), 0);
  });

  testWidgets('the pause button stops auto-advance until play is pressed', (
    tester,
  ) async {
    await _pumpCarousel(tester);

    await tester.tap(find.bySemanticsLabel('Pause carousel'));
    await tester.pump();
    await tester.pump(_oneAdvance);
    await tester.pumpAndSettle();
    expect(_activeSlide(tester), 0);

    await tester.tap(find.bySemanticsLabel('Play carousel'));
    await tester.pump();
    await tester.pump(_oneAdvance);
    await tester.pumpAndSettle();
    expect(_activeSlide(tester), 1);
    expect(find.bySemanticsLabel('Pause carousel'), findsOneWidget);
  });
}
