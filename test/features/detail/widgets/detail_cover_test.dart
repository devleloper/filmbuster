import 'package:filmbuster/presentation/features/detail/widgets/detail_cover.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';
import '../../../support/test_view.dart';
import '../../../support/text_layout.dart';

void main() {
  for (final (screen, size) in [
    ('a phone', referencePhone),
    ('a desktop', const Size(1280, 800)),
  ]) {
    testWidgets('$screen shows the title at 24 pt', (tester) async {
      useViewSize(tester, size);

      await tester.pumpWidget(
        inApp(const SizedBox(height: 260, child: DetailCover(title: 'Sintel'))),
      );

      expect(drawnStyleOf(tester, find.text('Sintel')).fontSize, 24);
    });
  }
}
