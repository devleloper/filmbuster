import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/glass_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';

void main() {
  testWidgets('GlassSheet shows its title above the content on the frosted '
      'surface', (tester) async {
    await tester.pumpWidget(
      inApp(
        const Center(
          child: GlassSheet(title: 'Quality', child: Text('Auto')),
        ),
      ),
    );

    final surface = find.byType(GlassSheetSurface);
    expect(
      find.descendant(of: surface, matching: find.text('Quality')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('Quality')).dy,
      lessThan(tester.getTopLeft(find.text('Auto')).dy),
    );
  });

  testWidgets('GlassSheetSurface blurs what lies behind and pads its child', (
    tester,
  ) async {
    const child = Key('child');
    await tester.pumpWidget(
      inApp(
        const Center(
          child: GlassSheetSurface(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: SizedBox(key: child, width: 100, height: 50),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    final inset =
        tester.getTopLeft(find.byKey(child)) -
        tester.getTopLeft(find.byType(GlassSheetSurface));
    expect(inset.dx, greaterThanOrEqualTo(AppSpacing.xxl));
    expect(inset.dy, greaterThanOrEqualTo(AppSpacing.xxl));
  });
}
