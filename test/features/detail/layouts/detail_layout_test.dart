import 'package:filmbuster/presentation/features/detail/view/detail_screen.dart';
import 'package:filmbuster/presentation/widgets/feedback/status_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';
import '../../../support/test_view.dart';

/// Sets up a notched iPhone and returns its status bar height in dp.
double _useNotchedPhone(WidgetTester tester) {
  const pixelRatio = 3.0;
  const statusBarPixels = 177.0;
  useViewSize(tester, referencePhone, pixelRatio: pixelRatio);
  tester.view.padding = const FakeViewPadding(top: statusBarPixels);
  return statusBarPixels / pixelRatio;
}

void main() {
  useDemoDependencies();

  testWidgets('Back stays below the status bar while loading and on failure', (
    tester,
  ) async {
    final statusBar = _useNotchedPhone(tester);
    final back = find.byIcon(Icons.arrow_back);

    await tester.pumpWidget(afterSplash(const DetailScreen(id: 1)));
    expect(tester.getRect(back).top, greaterThanOrEqualTo(statusBar));

    await tester.pump();
    expect(find.byType(ErrorStateView), findsOneWidget);
    expect(tester.getRect(back).top, greaterThanOrEqualTo(statusBar));

    await unmountApp(tester);
  });
}
