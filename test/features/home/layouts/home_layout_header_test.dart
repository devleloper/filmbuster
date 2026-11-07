import 'package:filmbuster/core/utils/responsive.dart';
import 'package:filmbuster/presentation/features/home/bloc/home_cubit.dart';
import 'package:filmbuster/presentation/features/home/layouts/home_layout.dart';
import 'package:filmbuster/presentation/theme/header_logo_layout.dart';
import 'package:filmbuster/presentation/widgets/app_icon_button.dart';
import 'package:filmbuster/presentation/widgets/app_logo.dart';
import 'package:filmbuster/presentation/widgets/attribution/demo_badge.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';
import '../../../support/mocks.dart';
import '../../../support/poppins.dart';
import '../../../support/test_view.dart';
import '../../../support/text_layout.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required double textScale,
  bool isDemo = true,
}) async {
  useViewSize(tester, Size(width, 874));
  useTextScale(tester, textScale);

  // Never loaded: the header is all this test looks at.
  final cubit = HomeCubit(MockMovieRepository());
  addTearDown(cubit.close);

  await tester.pumpWidget(
    afterSplash(
      BlocProvider.value(
        value: cubit,
        child: HomeLayout(isDemo: isDemo, refresh: HomeRefresh.pull),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(loadPoppins);

  for (final width in [360.0, 402.0, 440.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('${width.toInt()} dp, text scale $scale: badge on one line, '
          'About on screen', (tester) async {
        await _pump(tester, width: width, textScale: scale);

        expect(tester.takeException(), isNull);

        final badgeText = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.byType(DemoBadge),
            matching: find.text('Demo catalog'),
          ),
        );
        expect(badgeText.didExceedMaxLines, isFalse);
        expectOneLine(badgeText, textScale: scale);

        final about = tester.getRect(find.byType(AppIconButton));
        expect(about.right, lessThanOrEqualTo(width));
        expect(about.width, greaterThanOrEqualTo(48));
        expect(about.height, greaterThanOrEqualTo(48));

        final logo = tester.getRect(find.byType(AppLogo));
        final badge = tester.getRect(find.byType(DemoBadge));
        expect(logo.overlaps(badge), isFalse);
        expect(badge.overlaps(about), isFalse);
        expect(badge.right, lessThanOrEqualTo(width));
      });
    }
  }

  testWidgets('402 dp at text scale 1.0: logo and badge share one line', (
    tester,
  ) async {
    await _pump(tester, width: 402, textScale: 1);

    final logo = tester.getRect(find.byType(AppLogo));
    final badge = tester.getRect(find.byType(DemoBadge));
    expect(badge.top, logo.top);
    expect(badge.left, greaterThan(logo.right));
    expect(find.text('Demo catalog'), findsOneWidget);
  });

  // The splash animation ends with the logo at HeaderLogoLayout and then
  // hands it to the header; any other position makes the logo jump on every
  // cold start.
  for (final isDemo in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('logo sits where the splash leaves it '
          '(${isDemo ? 'demo' : 'live'}, text scale $scale)', (tester) async {
        await _pump(tester, width: 402, textScale: scale, isDemo: isDemo);

        final layout = ResponsiveLayout.of(
          tester.element(find.byType(HomeLayout)),
        );
        expect(
          tester.getRect(find.byType(AppLogo)).topLeft,
          Offset(layout.horizontalPadding, HeaderLogoLayout.top),
        );
      });
    }
  }
}
