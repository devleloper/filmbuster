import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/person_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/contrast.dart';

const _portrait = Size(120, 180);
const _iconSize = 48.0;

final _placeholder = find.byType(PersonPlaceholder);
final _silhouette = find.byIcon(Icons.person);

Future<void> _pumpWithinPortrait(WidgetTester tester) => tester.pumpWidget(
  inApp(
    Center(
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(_portrait),
        child: const PersonPlaceholder(iconSize: _iconSize),
      ),
    ),
  ),
);

void main() {
  testWidgets('fills the space it is given', (tester) async {
    await _pumpWithinPortrait(tester);

    expect(tester.getSize(_placeholder), _portrait);
  });

  testWidgets('centres a silhouette of the requested size', (tester) async {
    await _pumpWithinPortrait(tester);

    expect(tester.getSize(_silhouette), const Size.square(_iconSize));
    expect(tester.getCenter(_silhouette), tester.getCenter(_placeholder));
  });

  testWidgets('keeps the silhouette at 3:1 against its surface', (
    tester,
  ) async {
    await _pumpWithinPortrait(tester);

    final surface = tester.widget<ColoredBox>(
      find.descendant(of: _placeholder, matching: find.byType(ColoredBox)),
    );
    final silhouette = tester.widget<Icon>(_silhouette);
    final surfaceOnScreen = Color.alphaBlend(
      surface.color,
      AppColors.background,
    );
    expect(
      contrastRatio(silhouette.color!, surfaceOnScreen),
      greaterThanOrEqualTo(3),
    );
  });
}
