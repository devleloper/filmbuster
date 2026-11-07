import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:filmbuster/presentation/widgets/rating_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app.dart';
import '../support/test_view.dart';

void main() {
  testWidgets('shows the rating to one decimal after a yellow star', (
    tester,
  ) async {
    await tester.pumpWidget(
      inApp(
        const Center(
          child: RatingLabel(rating: 7.25, style: AppTextStyles.labelMedium),
        ),
      ),
    );

    expect(find.text('7.3'), findsOneWidget);
    final star = tester.widget<Icon>(find.byIcon(Icons.star));
    expect(star.color, AppColors.primaryYellow);
  });

  testWidgets('sizes the star to the font size of its style', (tester) async {
    await tester.pumpWidget(
      inApp(
        Center(
          child: RatingLabel(
            rating: 8,
            style: AppTextStyles.caption.copyWith(fontSize: 18),
          ),
        ),
      ),
    );

    expect(tester.widget<Icon>(find.byIcon(Icons.star)).size, 18);
  });

  testWidgets('grows the star with the system text size', (tester) async {
    useTextScale(tester, 2);
    await tester.pumpWidget(
      inApp(
        Center(
          child: RatingLabel(
            rating: 8,
            style: AppTextStyles.caption.copyWith(fontSize: 12),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byIcon(Icons.star)).height, 24);
  });
}
