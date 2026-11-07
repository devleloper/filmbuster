import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/adaptive/adaptive_scaffold.dart';
import 'package:filmbuster/presentation/widgets/navigation/app_tab.dart';
import 'package:filmbuster/presentation/widgets/navigation/glass_nav_bar.dart';
import 'package:filmbuster/presentation/widgets/navigation/gradient_bottom_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_view.dart';

const _poster = Key('first-poster');
const _background = Key('background');

Widget _homeLikeBody() => Scaffold(
  backgroundColor: AppColors.transparent,
  body: DecoratedBox(
    key: _background,
    decoration: AppGradients.screenBackgroundDecoration,
    child: SafeArea(
      child: SizedBox(
        height: 300,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          children: [
            const SizedBox(key: _poster, width: 170, height: 255),
            for (var i = 0; i < 6; i++) const SizedBox(width: 170, height: 255),
          ],
        ),
      ),
    ),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  required bool leanback,
  Widget? body,
  AppTab currentTab = AppTab.home,
  Map<AppTab, FocusNode> railFocusNodes = const {},
}) {
  useViewSize(tester, size);
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: AdaptiveScaffold(
        leanback: leanback,
        body: body ?? _homeLikeBody(),
        currentTab: currentTab,
        onTap: (_) {},
        railFocusNodes: railFocusNodes,
      ),
    ),
  );
}

void main() {
  const sizes = {
    'iPad Air 13 portrait': Size(1024, 1366),
    'iPad Air 13 landscape': Size(1366, 1024),
  };

  for (final MapEntry(key: name, value: size) in sizes.entries) {
    testWidgets('content starts right of the leanback rail while the '
        'background runs under it ($name)', (tester) async {
      await _pump(tester, size, leanback: true);
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(GlassNavBar));
      final poster = tester.getRect(find.byKey(_poster));
      expect(
        poster.left,
        greaterThanOrEqualTo(rail.right),
        reason: 'first poster $poster starts under the rail $rail',
      );
      expect(
        poster.left,
        AdaptiveScaffold.leanbackContentInset + AppSpacing.xl,
      );
      expect(tester.getRect(find.byKey(_background)).left, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('touch layout keeps the body edge to edge', (tester) async {
    await _pump(tester, const Size(390, 844), leanback: false);
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(_poster)).left, AppSpacing.xl);
  });

  testWidgets('touch layout reports the bottom bar to the body as bottom '
      'padding', (tester) async {
    const screen = Size(390, 844);
    const homeIndicator = 34.0;
    tester.view.padding = const FakeViewPadding(bottom: homeIndicator);
    addTearDown(tester.view.resetPadding);
    late EdgeInsets bodyPadding;
    await _pump(
      tester,
      screen,
      leanback: false,
      body: Builder(
        builder: (context) {
          bodyPadding = MediaQuery.paddingOf(context);
          return const SizedBox.expand();
        },
      ),
    );

    final bar = tester.getRect(find.byType(GlassNavBar));
    expect(bodyPadding.bottom, screen.height - bar.top);
    expect(bar.bottom, lessThan(screen.height - homeIndicator));
  });

  testWidgets('leanback layout reports the dark lower half of the bottom fade '
      'to the body as bottom padding', (tester) async {
    const screen = Size(1280, 800);
    late EdgeInsets bodyPadding;
    await _pump(
      tester,
      screen,
      leanback: true,
      body: Builder(
        builder: (context) {
          bodyPadding = MediaQuery.paddingOf(context);
          return const SizedBox.expand();
        },
      ),
    );

    final fade = tester.getRect(find.byType(GradientBottomFade));
    expect(bodyPadding.bottom, screen.height - fade.center.dy);
  });

  testWidgets('the touch bar is as tall as GlassNavBar.barHeight', (
    tester,
  ) async {
    await _pump(tester, const Size(390, 844), leanback: false);

    expect(
      tester.getSize(find.byType(GlassNavBar)).height,
      GlassNavBar.barHeight,
    );
  });

  testWidgets('the touch bottom bar keeps its phone width on a wide screen', (
    tester,
  ) async {
    Future<Rect> barAt(double width) async {
      await _pump(
        tester,
        Size(width, 1024),
        leanback: false,
        body: const SizedBox.expand(),
      );
      return tester.getRect(find.byType(GlassNavBar));
    }

    final phone = await barAt(390);
    final tablet = await barAt(1366);

    expect(tablet.width, phone.width);
    expect(tablet.center.dx, moreOrLessEquals(1366 / 2));
  });

  testWidgets(
    'the touch bottom bar is not rebuilt while the keyboard slides in',
    (tester) async {
      var barBuilds = 0;
      debugOnRebuildDirtyWidget = (element, _) {
        if (element.widget is GlassNavBar) barBuilds++;
      };
      addTearDown(() => debugOnRebuildDirtyWidget = null);
      await _pump(
        tester,
        const Size(390, 844),
        leanback: false,
        body: const SizedBox.expand(),
      );
      barBuilds = 0;

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

      expect(barBuilds, 0);
    },
  );

  group('leanback rail', () {
    Future<List<FocusNode>> pumpLeanback(
      WidgetTester tester, {
      AppTab currentTab = AppTab.home,
    }) async {
      final nodes = [
        for (final label in ['home', 'search', 'a', 'b', 'c'])
          FocusNode(debugLabel: label),
      ];
      addTearDown(() {
        for (final node in nodes) {
          node.dispose();
        }
      });
      await _pump(
        tester,
        const Size(1366, 1024),
        leanback: true,
        currentTab: currentTab,
        railFocusNodes: {AppTab.home: nodes[0], AppTab.search: nodes[1]},
        body: SafeArea(
          child: Row(
            children: [
              for (final node in nodes.skip(2))
                Focus(
                  focusNode: node,
                  child: const SizedBox.square(dimension: 100),
                ),
            ],
          ),
        ),
      );
      return nodes;
    }

    testWidgets('Left moves to the previous item in the content', (
      tester,
    ) async {
      final nodes = await pumpLeanback(tester);
      nodes[4].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(nodes[3].hasPrimaryFocus, isTrue);
    });

    for (final tab in AppTab.values) {
      testWidgets(
        'Left from the first item focuses ${tab.label}, the current tab',
        (tester) async {
          final nodes = await pumpLeanback(tester, currentTab: tab);
          nodes[2].requestFocus();
          await tester.pump();

          await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
          await tester.pump();

          expect(nodes[tab.index].hasPrimaryFocus, isTrue);
        },
      );
    }

    testWidgets('Down and Up move between Home and Search', (tester) async {
      final nodes = await pumpLeanback(tester);
      nodes[0].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(nodes[1].hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(nodes[0].hasPrimaryFocus, isTrue);
    });
  });

  group('with reduced motion', () {
    testWidgets('the leanback rail expands instantly', (tester) async {
      final home = FocusNode();
      addTearDown(home.dispose);
      reduceMotion(tester);
      await _pump(
        tester,
        const Size(1366, 1024),
        leanback: true,
        railFocusNodes: {AppTab.home: home},
        body: const SizedBox.expand(),
      );

      home.requestFocus();
      await tester.pump();
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(
        tester.getSize(find.byType(GlassNavBar)).width,
        GlassNavBar.railWidthExpanded,
      );
    });
  });
}
