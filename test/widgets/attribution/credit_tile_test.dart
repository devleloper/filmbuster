import 'package:filmbuster/presentation/widgets/attribution/credit_tile.dart';
import 'package:filmbuster/presentation/widgets/text_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/focus.dart';

void main() {
  Widget tile() => CreditTile(
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
  );

  testWidgets('reads its text as one node and keeps links separate', (
    tester,
  ) async {
    await tester.pumpWidget(inApp(Center(child: tile())));

    final text = tester.getSemantics(find.text('Big Buck Bunny'));
    expect(text.label, contains('Big Buck Bunny'));
    expect(text.label, contains('www.bigbuckbunny.org'));
    expect(find.bySemanticsLabel('Source'), findsOneWidget);
  });

  testWidgets('keyboard traversal reaches every link in order', (tester) async {
    await tester.pumpWidget(inApp(Center(child: tile())));

    List<String> focused() => [
      for (final label in ['Source', 'License'])
        if (focusIsIn(find.widgetWithText(TextLink, label))) label,
    ];

    await pressTab(tester);
    expect(focused(), ['Source']);
    await pressTab(tester);
    expect(focused(), ['License']);
  });
}
