import 'package:filmbuster/core/utils/responsive.dart';
import 'package:filmbuster/presentation/features/search/widgets/search_bar.dart';
import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';
import '../../../support/test_view.dart';
import '../../../support/text_layout.dart';

void main() {
  testWidgets('the submit button is named by its visible text', (tester) async {
    final submitted = <String>[];
    await tester.pumpWidget(inApp(AppSearchBar(onSubmit: submitted.add)));

    await tester.enterText(find.byType(TextField), 'dune');
    await tester.tap(find.bySemanticsLabel('Go'));

    expect(submitted, ['dune']);
  });

  testWidgets('Go grows on a wide screen like the rest of the bar', (
    tester,
  ) async {
    useViewSize(tester, const Size(1280, 800));

    await tester.pumpWidget(inApp(AppSearchBar(onSubmit: (_) {})));

    expect(
      drawnStyleOf(tester, find.text('Go')).fontSize,
      AppTextStyles.labelMedium.fontSize! *
          ResponsiveBreakpoint.xlarge.scaleFactor,
    );
  });
}
