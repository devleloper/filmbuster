import 'package:filmbuster/domain/models/tmdb_credit_person.dart';
import 'package:filmbuster/presentation/features/detail/widgets/persons_reel.dart';
import 'package:filmbuster/presentation/widgets/focusable_lift_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';
import '../../../support/poppins.dart';
import '../../../support/test_view.dart';
import '../../../support/text_layout.dart';

const _director = TmdbCreditPerson(
  id: 1,
  name: 'Sacha Goedegebure',
  job: 'Director',
  department: 'Directing',
);

const _actor = TmdbCreditPerson(id: 2, name: 'Bunny', character: 'Big Buck');

Future<void> _pump(WidgetTester tester, {required double textScale}) async {
  useViewSize(tester, referencePhone);
  useTextScale(tester, textScale);

  await tester.pumpWidget(
    inApp(
      const SingleChildScrollView(
        child: PersonsReel(cast: [_actor], crew: [_director]),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(loadPoppins);

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('text scale $scale: name breaks between words, never inside', (
      tester,
    ) async {
      await _pump(tester, textScale: scale);

      expect(tester.takeException(), isNull);
      expect(find.text('Sacha'), findsOneWidget);
      expect(find.text('Goedegebure'), findsOneWidget);
      expect(find.text('Bunny'), findsOneWidget);
      expect(find.text('Director'), findsOneWidget);

      final surname = tester.renderObject<RenderParagraph>(
        find.text('Goedegebure'),
      );
      // Larger text may ellipsize the surname, but always on its own line.
      expectOneLine(surname, textScale: scale);
    });
  }

  testWidgets('is titled Cast & crew', (tester) async {
    await _pump(tester, textScale: 1);

    expect(find.text('Cast & crew'), findsOneWidget);
  });

  testWidgets('at text scale 1.0 the surname fits whole', (tester) async {
    await _pump(tester, textScale: 1);

    final surname = tester.renderObject<RenderParagraph>(
      find.text('Goedegebure'),
    );
    expect(surname.didExceedMaxLines, isFalse);
  });

  testWidgets('shows twelve actors, then key crew not already shown', (
    tester,
  ) async {
    // Wide enough that the list builds every card.
    useViewSize(tester, const Size(4000, 600));
    final cast = [
      for (var id = 1; id <= 13; id++)
        TmdbCreditPerson(id: id, name: 'Actor$id', character: 'Role $id'),
    ];
    const crew = [
      TmdbCreditPerson(
        id: 1,
        name: 'Actor1',
        job: 'Director',
        department: 'Directing',
      ),
      TmdbCreditPerson(
        id: 20,
        name: 'Mixer',
        job: 'Sound Mixer',
        department: 'Sound',
      ),
    ];

    await tester.pumpWidget(inApp(PersonsReel(cast: cast, crew: crew)));

    expect(find.byType(FocusableLiftCard), findsNWidgets(12));
    expect(find.text('Actor1'), findsOneWidget);
    expect(find.text('Actor13'), findsNothing);
    expect(find.text('Director'), findsNothing);
    expect(find.text('Mixer'), findsNothing);
  });

  testWidgets('the name is read as one label', (tester) async {
    await _pump(tester, textScale: 1);

    expect(
      find.bySemanticsLabel(RegExp(r'^Sacha Goedegebure\b')),
      findsOneWidget,
    );
  });
}
