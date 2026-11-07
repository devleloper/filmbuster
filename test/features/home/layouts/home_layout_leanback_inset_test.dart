import 'package:filmbuster/presentation/features/home/bloc/home_cubit.dart';
import 'package:filmbuster/presentation/features/home/layouts/home_layout.dart';
import 'package:filmbuster/presentation/features/splash/widgets/splash_logo_animated.dart';
import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/adaptive/adaptive_scaffold.dart';
import 'package:filmbuster/presentation/widgets/app_logo.dart';
import 'package:filmbuster/presentation/widgets/movie_poster_card.dart';
import 'package:filmbuster/presentation/widgets/navigation/app_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';
import '../../../support/mocks.dart';
import '../../../support/poppins.dart';
import '../../../support/test_view.dart';

const _sizes = {'portrait': Size(1024, 1366), 'landscape': Size(1366, 1024)};

/// A device driven by a remote control, which always gets leanback.
Widget _directional(BuildContext context, Widget? child) => MediaQuery(
  data: MediaQuery.of(
    context,
  ).copyWith(navigationMode: NavigationMode.directional),
  child: child!,
);

final _movies = Fixtures.movies(8);

const _rail = AdaptiveScaffold.leanbackContentInset;

Future<void> _pumpHome(WidgetTester tester, Size size) async {
  useViewSize(tester, size);
  final repository = MockMovieRepository();
  repository.stubCatalogues(_movies);
  final cubit = HomeCubit(repository);
  addTearDown(cubit.close);

  await tester.pumpWidget(
    afterSplash(
      AdaptiveScaffold(
        leanback: true,
        currentTab: AppTab.home,
        onTap: (_) {},
        body: BlocProvider.value(
          value: cubit,
          child: const HomeLayout(isDemo: true, refresh: HomeRefresh.button),
        ),
      ),
      builder: _directional,
    ),
  );
  await cubit.load();
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(loadPoppins);

  for (final MapEntry(key: name, value: size) in _sizes.entries) {
    testWidgets('Home content starts right of the leanback rail ($name)', (
      tester,
    ) async {
      await _pumpHome(tester, size);
      expect(tester.takeException(), isNull);

      final posters = find.byType(MoviePosterCard);
      expect(posters, findsWidgets);
      for (final poster in posters.evaluate()) {
        expect(
          tester.getRect(find.byWidget(poster.widget)).left,
          greaterThanOrEqualTo(_rail),
        );
      }
      expect(tester.getRect(find.byType(AppLogo)).left, greaterThan(_rail));
      expect(
        tester.getRect(find.byIcon(Icons.info_outline_rounded)).right,
        lessThanOrEqualTo(size.width),
      );
      await unmountApp(tester);
    });

    testWidgets('splash leaves the logo where the header draws it ($name)', (
      tester,
    ) async {
      await _pumpHome(tester, size);
      final header = tester.getRect(find.byType(AppLogo)).topLeft;
      await unmountApp(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: _directional,
          home: SplashLogoAnimated(onAnimationComplete: () {}),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(tester.getRect(find.byType(SvgPicture)).topLeft, header);
    });
  }
}
