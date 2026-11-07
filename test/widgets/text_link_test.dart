import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/text_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/focus.dart';
import '../support/tap_area.dart';
import '../support/test_view.dart';

Widget _stretched(Widget link) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [const Text('Licenses'), AppSpacing.vGapMd, link],
);

Widget _startAligned(Widget link) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [const Text('Play'), link, AppSpacing.vGapMd],
);

Widget _wrapped(List<Widget> links) =>
    Wrap(spacing: AppSpacing.xs, children: links);

void main() {
  testWidgets('taps and exposes link semantics', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      inApp(
        Center(
          child: TextLink(
            label: 'Source',
            semanticLabel: 'Big Buck Bunny source',
            semanticHint: 'Opens in browser',
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Source'));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.byType(TextLink)),
      isSemantics(
        label: 'Big Buck Bunny source',
        hint: 'Opens in browser',
        isLink: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('has a 48 dp target', (tester) async {
    await tester.pumpWidget(
      inApp(
        Center(
          child: TextLink(label: 'X', onTap: () {}),
        ),
      ),
    );

    final size = tester.getSize(find.byType(TextLink));
    expect(size.height, greaterThanOrEqualTo(kMinInteractiveDimension));
    expect(size.width, greaterThanOrEqualTo(kMinInteractiveDimension));
  });

  testWidgets('grows its icon with the system text size', (tester) async {
    useTextScale(tester, 2);
    await tester.pumpWidget(
      inApp(
        Center(
          child: TextLink(
            label: 'Source',
            style: AppTextStyles.labelMedium.copyWith(fontSize: 12),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byIcon(Icons.open_in_new_rounded)).height, 24);
  });

  testWidgets('shows the focus ring on focus and activates on Enter', (
    tester,
  ) async {
    useKeyboardHighlight();
    var taps = 0;
    await tester.pumpWidget(
      inApp(
        Center(
          child: TextLink(label: 'Source', onTap: () => taps++),
        ),
      ),
    );
    final link = find.byType(TextLink);
    expect(link, isNot(paints..rrect(color: AppFocus.ringColor)));

    await pressTab(tester);
    expect(
      link,
      paints
        ..rrect(color: AppFocus.haloColor)
        ..rrect(color: AppFocus.ringColor),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(taps, 2);
  });

  testWidgets('is inert and unfocusable when disabled', (tester) async {
    await tester.pumpWidget(
      inApp(const Center(child: TextLink(label: 'Source', onTap: null))),
    );

    await pressTab(tester);
    expect(focusIsIn(find.byType(TextLink)), isFalse);
    expect(
      tester.getSemantics(find.byType(TextLink)),
      isSemantics(isLink: true, hasEnabledState: true, isEnabled: false),
    );
  });

  testWidgets('shows the focus ring at once with reduced motion', (
    tester,
  ) async {
    useKeyboardHighlight();
    reduceMotion(tester);
    await tester.pumpWidget(
      inApp(
        Center(
          child: TextLink(label: 'Source', onTap: () {}),
        ),
      ),
    );

    await pressTab(tester);
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(
      find.byType(TextLink),
      paints
        ..rrect(color: AppFocus.haloColor)
        ..rrect(color: AppFocus.ringColor),
    );
  });

  for (final textScale in [1.0, 2.0]) {
    group('at text x$textScale, TextLink takes taps across its whole '
        'accessibility node', () {
      testWidgets('in a stretched column', (tester) async {
        var taps = 0;
        await pumpInPhoneList(
          tester,
          _stretched(
            TextLink(
              label: 'Open-source licenses',
              icon: Icons.chevron_right_rounded,
              onTap: () => taps++,
            ),
          ),
          textScale: textScale,
        );

        await expectWholeNodeTappable(
          tester,
          'Open-source licenses',
          () => taps,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('in a start-aligned column', (tester) async {
        var taps = 0;
        await pumpInPhoneList(
          tester,
          _startAligned(
            TextLink(
              label: 'Trailer',
              icon: Icons.smart_display_rounded,
              semanticLabel: 'Watch The Matrix trailer',
              onTap: () => taps++,
            ),
          ),
          textScale: textScale,
        );

        await expectWholeNodeTappable(
          tester,
          'Watch The Matrix trailer',
          () => taps,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('next to another link', (tester) async {
        var source = 0;
        var license = 0;
        await pumpInPhoneList(
          tester,
          _wrapped([
            TextLink(
              label: 'Source',
              semanticLabel: 'Sintel project page',
              onTap: () => source++,
            ),
            TextLink(
              label: 'License',
              semanticLabel: 'Sintel license, CC BY 3.0',
              onTap: () => license++,
            ),
          ]),
          textScale: textScale,
        );

        await expectWholeNodeTappable(
          tester,
          'Sintel project page',
          () => source,
        );
        expect(license, 0, reason: 'neighbour link must not steal taps');
        await expectWholeNodeTappable(
          tester,
          'Sintel license, CC BY 3.0',
          () => license,
        );
        expect(source, 5);
      });
    });
  }
}
