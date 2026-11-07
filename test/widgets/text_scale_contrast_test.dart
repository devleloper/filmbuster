import 'package:filmbuster/domain/models/tmdb_movie.dart';
import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/app_buttons.dart';
import 'package:filmbuster/presentation/widgets/app_header.dart';
import 'package:filmbuster/presentation/widgets/app_slider.dart';
import 'package:filmbuster/presentation/widgets/attribution/attribution_section.dart';
import 'package:filmbuster/presentation/widgets/attribution/credit_tile.dart';
import 'package:filmbuster/presentation/widgets/attribution/demo_badge.dart';
import 'package:filmbuster/presentation/widgets/attribution/license_credit.dart';
import 'package:filmbuster/presentation/widgets/attribution/tmdb_attribution.dart';
import 'package:filmbuster/presentation/widgets/feedback/status_views.dart';
import 'package:filmbuster/presentation/widgets/glass_sheet.dart';
import 'package:filmbuster/presentation/widgets/movie_poster_card.dart';
import 'package:filmbuster/presentation/widgets/movie_poster_reel.dart';
import 'package:filmbuster/presentation/widgets/navigation/app_tab.dart';
import 'package:filmbuster/presentation/widgets/navigation/glass_nav_bar.dart';
import 'package:filmbuster/presentation/widgets/no_poster_placeholder.dart';
import 'package:filmbuster/presentation/widgets/selectable_row.dart';
import 'package:filmbuster/presentation/widgets/text_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/contrast.dart';
import '../support/disk_assets.dart';
import '../support/poppins.dart';
import '../support/test_view.dart';

final _movies = [
  for (var i = 1; i <= 3; i++)
    TmdbMovie(
      id: i,
      title: 'An open movie with a long title $i',
      voteAverage: 7.5,
      releaseDate: '2008-04-10',
    ),
];

Widget _sheet({bool firstSelected = true}) => GlassSheet(
  title: 'Subtitles',
  child: ListView(
    padding: GlassSheet.listPadding,
    children: [
      for (final (index, (language, code)) in [
        ('English', 'en'),
        ('French', 'fr'),
        ('German', 'de'),
      ].indexed)
        SelectableRow(
          title: language,
          subtitle: 'Language: $code',
          isSelected: firstSelected && index == 0,
          onTap: () {},
        ),
    ],
  ),
);

Widget _errorView() => ErrorStateView(
  title: 'Something went wrong',
  message: 'Check your connection and try again.',
  onRetry: () {},
  onBack: () {},
);

Widget _posterCard() => MoviePosterCard(movie: _movies.first, onTap: () {});

Widget _reel({String? title}) =>
    MoviePosterReel(movies: _movies, title: title, onMovieTap: (_) {});

void main() {
  setUpAll(loadPoppins);

  group('at text scale 2.0 on a 320 dp phone', () {
    final cases = <String, Widget Function()>{
      'GlassSheet with option rows': _sheet,
      'MoviePosterReel': () => _reel(title: 'Open'),
      'ErrorStateView': _errorView,
      'EmptyStateView': () => const EmptyStateView(
        icon: Icons.search_off,
        title: 'No results',
        description: 'Try another title.',
      ),
      'NoPosterPlaceholder': () =>
          const NoPosterPlaceholder(width: 140, height: 200),
      'PrimaryButton': () =>
          PrimaryButton(onPressed: () {}, child: const Text('Go')),
      'GlassNavBar': () => GlassNavBar(currentTab: AppTab.home, onTap: (_) {}),
      'GlassNavBar rail': () => GlassNavBar.rail(
        currentTab: AppTab.home,
        onTap: (_) {},
        expanded: true,
      ),
      'AppHeader with a long title': () => AppHeader(
        title: 'A remarkably long screen title that has to wrap',
        onBack: () {},
      ),
      'AttributionSection': () => SingleChildScrollView(
        child: AttributionSection(
          title: 'Open movies',
          description: 'Films that play in demo mode.',
          children: [TextLink(label: 'Source', onTap: () {})],
        ),
      ),
      'CreditTile': () => SingleChildScrollView(
        child: CreditTile(
          title: 'Big Buck Bunny',
          subtitle: '2008 · CC BY 3.0',
          details: const [
            '(c) copyright 2008, Blender Foundation / www.bigbuckbunny.org',
            'Poster cropped and resized.',
          ],
          links: [
            TextLink(label: 'Source', onTap: () {}),
            TextLink(label: 'License', onTap: () {}),
          ],
        ),
      ),
      'LicenseCredit': () => LicenseCredit(
        licenseName: 'CC BY 3.0',
        author: 'Blender Foundation',
        sourceLabel: 'Source',
        onLicenseTap: () {},
        onSourceTap: () {},
        linkHint: 'Opens in browser',
      ),
      'TmdbAttribution': () => DefaultAssetBundle(
        bundle: DiskAssetBundle(),
        child: const SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: TmdbAttribution(logoHeight: 12),
        ),
      ),
      'DemoBadge': () => const DemoBadge(
        label: 'Demo catalog',
        semanticLabel: 'Demo catalog: open movies only',
      ),
    };
    for (final MapEntry(key: name, value: build) in cases.entries) {
      testWidgets('$name lays out without overflow', (tester) async {
        await expectFitsCompactPhoneAtDoubleText(
          tester,
          inApp(Center(child: build())),
        );
      });
    }

    testWidgets('ErrorStateView keeps both buttons on screen', (tester) async {
      await expectFitsCompactPhoneAtDoubleText(
        tester,
        inApp(Center(child: _errorView())),
      );

      expect(find.text('Retry').hitTestable(), findsOneWidget);
      expect(find.text('Go Back').hitTestable(), findsOneWidget);
    });

    testWidgets('a poster title is not cut through its glyphs', (tester) async {
      await expectFitsCompactPhoneAtDoubleText(
        tester,
        inApp(Center(child: _reel())),
      );

      final title = tester.renderObject<RenderParagraph>(
        find.text(_movies.first.title),
      );
      expect(
        title.size.height,
        greaterThanOrEqualTo(
          title.getMinIntrinsicHeight(title.size.width) - 0.5,
        ),
      );
    });

    testWidgets('a poster reel grows with the text', (tester) async {
      useViewSize(tester, compactPhone);
      Future<double> reelHeight(double scale) async {
        useTextScale(tester, scale);
        await tester.pumpWidget(inApp(Center(child: _reel())));
        return tester.getSize(find.byType(MoviePosterReel)).height;
      }

      final regular = await reelHeight(1);
      expect(await reelHeight(2), greaterThan(regular));
    });
  });

  group('text contrast', () {
    final cases = <String, Widget Function()>{
      'NoPosterPlaceholder': () =>
          const NoPosterPlaceholder(width: 140, height: 200),
      'MoviePosterCard': _posterCard,
      'ErrorStateView': _errorView,
      'GlassSheet with selected and unselected rows': _sheet,
      'PrimaryButton and SecondaryButton': () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(onPressed: () {}, child: const Text('Retry')),
          SecondaryButton(onPressed: () {}, child: const Text('Go Back')),
        ],
      ),
    };
    for (final MapEntry(key: name, value: build) in cases.entries) {
      testWidgets('$name meets WCAG text contrast', (tester) async {
        useViewSize(tester, compactPhone);
        await tester.pumpWidget(inApp(Center(child: build())));

        await expectLater(tester, meetsGuideline(textContrastGuideline));
      });
    }
  });

  group('tap targets', () {
    final cases = <String, Widget Function()>{
      'PrimaryButton with the search bar padding': () => PrimaryButton(
        onPressed: () {},
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: const Text('Go'),
      ),
      'GlassNavBar': () => GlassNavBar(currentTab: AppTab.home, onTap: (_) {}),
      'SelectableRow': () => SizedBox(
        width: 320,
        child: SelectableRow(title: 'English', isSelected: true, onTap: () {}),
      ),
      'AppSlider': () => SizedBox(
        width: 300,
        child: AppSlider(
          value: 0.5,
          semanticLabel: 'Volume',
          onChanged: (_) {},
        ),
      ),
    };
    for (final MapEntry(key: name, value: build) in cases.entries) {
      testWidgets('$name meets the Android and iOS minimums', (tester) async {
        await tester.pumpWidget(inApp(Center(child: build())));

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      });
    }

    testWidgets('GlassNavBar labels every tab', (tester) async {
      await tester.pumpWidget(
        inApp(
          Center(
            child: GlassNavBar(currentTab: AppTab.home, onTap: (_) {}),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });

  testWidgets('an unselected radio dot keeps 3:1 on the sheet', (tester) async {
    await tester.pumpWidget(
      inApp(
        Center(
          child: SelectableRow(
            title: 'French',
            isSelected: false,
            onTap: () {},
          ),
        ),
      ),
    );

    final dot = tester.widget<Container>(
      find.descendant(
        of: find.byType(SelectableRow),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              (widget.decoration as BoxDecoration?)?.shape == BoxShape.circle,
        ),
      ),
    );
    final border = (dot.decoration! as BoxDecoration).border! as Border;
    final sheet = Color.alphaBlend(AppColors.glassSheet, AppColors.background);
    expect(contrastRatio(border.top.color, sheet), greaterThanOrEqualTo(3));
  });

  group('no text below 12 pt', () {
    final cases = <String, Widget Function()>{
      'MoviePosterCard': _posterCard,
      'NoPosterPlaceholder': () =>
          const NoPosterPlaceholder(width: 140, height: 200),
    };
    for (final MapEntry(key: name, value: build) in cases.entries) {
      testWidgets(name, (tester) async {
        useViewSize(tester, compactPhone);
        await tester.pumpWidget(inApp(Center(child: build())));

        final sizes = [
          for (final paragraph in tester.renderObjectList<RenderParagraph>(
            find.descendant(
              of: find.byType(Scaffold),
              matching: find.byType(RichText),
            ),
          ))
            paragraph.text.style?.fontSize ?? 14,
        ];
        expect(sizes, everyElement(greaterThanOrEqualTo(12)));
      });
    }
  });
}
