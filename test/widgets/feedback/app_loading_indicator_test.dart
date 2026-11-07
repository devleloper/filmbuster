import 'package:filmbuster/presentation/widgets/feedback/app_loading_indicator.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/test_view.dart';

void main() {
  testWidgets('AppLoadingIndicator spins while motion is not reduced', (
    tester,
  ) async {
    await tester.pumpWidget(inApp(const Center(child: AppLoadingIndicator())));
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('AppLoadingIndicator is announced as loading', (tester) async {
    await tester.pumpWidget(inApp(const Center(child: AppLoadingIndicator())));

    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('the small indicator is smaller than the default one', (
    tester,
  ) async {
    Future<Size> sizeOf(AppLoadingIndicator indicator) async {
      await tester.pumpWidget(inApp(Center(child: indicator)));
      return tester.getSize(find.byType(AppLoadingIndicator));
    }

    final regular = await sizeOf(const AppLoadingIndicator());
    final small = await sizeOf(const AppLoadingIndicator.small());

    expect(small.width, lessThan(regular.width));
  });

  testWidgets('AppProgressRing paints without animating', (tester) async {
    await tester.pumpWidget(
      inApp(const Center(child: AppProgressRing(value: 0.4))),
    );
    await tester.pump();

    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  group('with reduced motion', () {
    testWidgets('AppLoadingIndicator stops repeating', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(
        inApp(const Center(child: AppLoadingIndicator())),
      );
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
