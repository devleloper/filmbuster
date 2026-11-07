import 'package:filmbuster/presentation/widgets/attribution/demo_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/poppins.dart';

void main() {
  group('in Poppins', () {
    setUpAll(loadPoppins);

    testWidgets('a squeezed badge stays on one line and keeps its full label', (
      tester,
    ) async {
      await tester.pumpWidget(
        inApp(
          const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 60,
              child: DemoBadge(
                label: 'Demo catalog',
                semanticLabel: 'Demo catalog: open movies only',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Demo catalog'),
      );
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(paragraph.maxLines, 1);
      expect(
        find.bySemanticsLabel('Demo catalog: open movies only'),
        findsOneWidget,
      );
    });
  });
}
