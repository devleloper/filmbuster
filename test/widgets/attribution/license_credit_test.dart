import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/attribution/license_credit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/poppins.dart';
import '../../support/test_view.dart';

const _widths = [360.0, 402.0];
const _scales = [1.0, 2.0];

const _bbbAuthor =
    '(c) copyright 2008, Blender Foundation / www.bigbuckbunny.org';

Widget _credit({
  String author = 'Blender Foundation',
  String source = 'Source',
  String? sourceSemanticLabel,
  VoidCallback? onLicense,
  VoidCallback? onSource,
}) => LicenseCredit(
  licenseName: 'CC BY 3.0',
  author: author,
  sourceLabel: source,
  onLicenseTap: onLicense ?? () {},
  onSourceTap: onSource ?? () {},
  sourceSemanticLabel: sourceSemanticLabel,
  linkHint: 'Opens in browser',
);

/// [credit] at the top left of a page with the compact layout's gutter.
Widget _onPage(
  Widget credit, {
  TextDirection textDirection = TextDirection.ltr,
}) => inApp(
  Directionality(
    textDirection: textDirection,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Align(alignment: Alignment.topLeft, child: credit),
    ),
  ),
);

RenderWrap _wrapOf(WidgetTester tester) => tester.renderObject<RenderWrap>(
  find.descendant(
    of: find.byType(LicenseCredit),
    matching: find.byWidgetPredicate((w) => w is Wrap),
  ),
);

List<Rect> _segmentRects(RenderWrap wrap) => wrap
    .getChildrenAsList()
    .map((c) => (c.parentData! as WrapParentData).offset & c.size)
    .toList();

/// Centers of the circles the wrap paints itself (the separators).
List<Offset> _dotCenters(RenderWrap wrap) {
  final canvas = TestRecordingCanvas();
  wrap.paint(TestRecordingPaintingContext(canvas), Offset.zero);
  return [
    for (final call in canvas.invocations)
      if (call.invocation.memberName == #drawCircle)
        call.invocation.positionalArguments.first as Offset,
  ];
}

bool _sameLine(Rect a, Rect b) => a.top < b.bottom && b.top < a.bottom;

void main() {
  testWidgets('routes each link to its own callback', (tester) async {
    var license = 0;
    var source = 0;
    await tester.pumpWidget(
      inApp(
        Center(
          child: _credit(onLicense: () => license++, onSource: () => source++),
        ),
      ),
    );

    await tester.tap(find.text('CC BY 3.0'));
    await tester.tap(find.text('Source'));
    expect((license, source), (1, 1));
    expect(find.text('Blender Foundation'), findsOneWidget);
  });

  testWidgets('exposes two links and hides separators', (tester) async {
    await tester.pumpWidget(
      inApp(
        Center(child: _credit(sourceSemanticLabel: 'Big Buck Bunny source')),
      ),
    );

    expect(find.bySemanticsLabel('Big Buck Bunny source'), findsOneWidget);
    expect(find.bySemanticsLabel('CC BY 3.0'), findsOneWidget);
    expect(find.bySemanticsLabel('·'), findsNothing);
  });

  group('wraps by segment', () {
    setUpAll(loadPoppins);

    for (final width in _widths) {
      for (final scale in _scales) {
        for (final author in ['Blender Foundation', _bbbAuthor]) {
          testWidgets('leaves no dot at a line end at ${width.toInt()} dp, '
              'text x$scale, ${author.length}-character author', (
            tester,
          ) async {
            useViewSize(tester, Size(width, 800));
            useTextScale(tester, scale);
            await tester.pumpWidget(
              _onPage(_credit(author: author, source: 'peach.blender.org')),
            );

            expect(tester.takeException(), isNull);
            expect(find.text('·'), findsNothing);

            final wrap = _wrapOf(tester);
            final rects = _segmentRects(wrap);
            final dots = _dotCenters(wrap);
            final pairs = [
              for (var i = 0; i + 1 < rects.length; i++)
                if (_sameLine(rects[i], rects[i + 1])) (rects[i], rects[i + 1]),
            ];

            expect(dots, hasLength(pairs.length));
            for (final (i, (a, b)) in pairs.indexed) {
              final dot = dots[i];
              expect(dot.dx, greaterThan(a.right));
              expect(dot.dx, lessThan(b.left));
              expect(dot.dy, greaterThan(a.top));
              expect(dot.dy, lessThan(a.bottom));
            }
            for (final r in rects) {
              expect(r.right, lessThanOrEqualTo(wrap.size.width + 0.5));
            }
          });
        }
      }
    }

    testWidgets('a short credit fits one line with two dots at 360 dp', (
      tester,
    ) async {
      useViewSize(tester, const Size(360, 800));
      await tester.pumpWidget(_onPage(_credit()));

      final wrap = _wrapOf(tester);
      final rects = _segmentRects(wrap);
      expect(_sameLine(rects[0], rects[1]), isTrue);
      expect(_sameLine(rects[1], rects[2]), isTrue);
      expect(_dotCenters(wrap), hasLength(2));
    });

    testWidgets('a long credit at 360 dp and text x2.0 has no dot at all', (
      tester,
    ) async {
      useViewSize(tester, const Size(360, 800));
      useTextScale(tester, 2.0);
      await tester.pumpWidget(
        _onPage(_credit(author: _bbbAuthor, source: 'peach.blender.org')),
      );

      final wrap = _wrapOf(tester);
      final rects = _segmentRects(wrap);
      expect(_sameLine(rects[0], rects[1]), isFalse);
      expect(_sameLine(rects[1], rects[2]), isFalse);
      expect(_dotCenters(wrap), isEmpty);
    });

    testWidgets('dots sit between segments in right-to-left text', (
      tester,
    ) async {
      useViewSize(tester, const Size(360, 800));
      await tester.pumpWidget(
        _onPage(_credit(), textDirection: TextDirection.rtl),
      );

      final wrap = _wrapOf(tester);
      final rects = _segmentRects(wrap);
      final dots = _dotCenters(wrap);
      expect(dots, hasLength(2));
      expect(dots[0].dx, lessThan(rects[0].left));
      expect(dots[0].dx, greaterThan(rects[1].right));
      expect(dots[1].dx, lessThan(rects[1].left));
      expect(dots[1].dx, greaterThan(rects[2].right));
    });

    testWidgets('separators stay out of the semantics tree', (tester) async {
      useTextScale(tester, 2.0);
      await tester.pumpWidget(
        _onPage(_credit(author: _bbbAuthor, source: 'peach.blender.org')),
      );

      expect(find.bySemanticsLabel('·'), findsNothing);
      expect(find.bySemanticsLabel('CC BY 3.0'), findsOneWidget);
      expect(find.bySemanticsLabel('peach.blender.org'), findsOneWidget);
    });
  });
}
