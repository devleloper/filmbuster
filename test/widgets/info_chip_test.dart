import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/info_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/test_view.dart';

TextStyle _labelStyle(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!;

BorderRadius _radius(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(InfoChip),
      matching: find.byType(Container),
    ),
  );
  return (container.decoration! as BoxDecoration).borderRadius! as BorderRadius;
}

void main() {
  testWidgets('shows its label in secondary caption text', (tester) async {
    useViewSize(tester, referencePhone);
    await tester.pumpWidget(inApp(const Center(child: InfoChip('Animation'))));

    final style = _labelStyle(tester, 'Animation');
    expect(style.color, AppColors.textSecondary);
    expect(style.fontSize, AppTextStyles.caption.fontSize);
    expect(_radius(tester), AppRadius.mdAll);
  });

  testWidgets('grows its text and corners on a wide screen', (tester) async {
    useViewSize(tester, const Size(1366, 1024));
    await tester.pumpWidget(inApp(const Center(child: InfoChip('Animation'))));

    final style = _labelStyle(tester, 'Animation');
    expect(style.fontSize, greaterThan(AppTextStyles.caption.fontSize!));
    expect(_radius(tester).topLeft.x, greaterThan(AppRadius.md));
  });
}
