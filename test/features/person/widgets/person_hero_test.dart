import 'package:filmbuster/domain/models/tmdb_person_details.dart';
import 'package:filmbuster/presentation/features/person/widgets/person_hero.dart';
import 'package:filmbuster/presentation/widgets/media_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';
import '../../../support/test_view.dart';

const _withoutPortrait = PersonHero(
  person: TmdbPersonDetails(id: 1, name: 'Sacha Goedegebure'),
);

void main() {
  testWidgets(
    'a person without a portrait shows a person silhouette, not a poster '
    'placeholder',
    (tester) async {
      await tester.pumpWidget(inApp(_withoutPortrait));

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.text('No Poster Available'), findsNothing);
    },
  );

  testWidgets('a person without a portrait keeps the portrait size', (
    tester,
  ) async {
    useViewSize(tester, referencePhone);
    await tester.pumpWidget(inApp(_withoutPortrait));

    expect(tester.getSize(find.byType(MediaImage)), PersonHero.avatarSize);
  });
}
