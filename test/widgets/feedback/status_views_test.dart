import 'package:filmbuster/presentation/widgets/app_buttons.dart';
import 'package:filmbuster/presentation/widgets/feedback/app_loading_indicator.dart';
import 'package:filmbuster/presentation/widgets/feedback/status_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';
import '../../support/focus.dart';
import '../../support/test_view.dart';

void main() {
  testWidgets('LoadingStateView shows the custom indicator', (tester) async {
    await tester.pumpWidget(inApp(const Center(child: LoadingStateView())));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AppLoadingIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('ErrorStateView shows the message and retries', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      inApp(
        Center(
          child: ErrorStateView(
            message: 'Cannot connect to the server.',
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(find.text('Cannot connect to the server.'), findsOneWidget);
    expect(find.text('Go Back'), findsNothing);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('EmptyStateView shows its title, description and way forward', (
    tester,
  ) async {
    await tester.pumpWidget(
      inApp(
        Center(
          child: EmptyStateView(
            icon: Icons.movie_filter_outlined,
            title: 'Nothing to show yet',
            description: 'Try again in a moment.',
            primary: PrimaryButton(
              onPressed: () {},
              child: const Text('Reload'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nothing to show yet'), findsOneWidget);
    expect(find.text('Try again in a moment.'), findsOneWidget);
    expect(find.text('Reload'), findsOneWidget);
  });

  testWidgets('ErrorStateView reaches Retry, then Go Back, with Tab', (
    tester,
  ) async {
    var retries = 0;
    var backs = 0;
    await tester.pumpWidget(
      inApp(
        Center(
          child: ErrorStateView(
            message: 'Something went wrong.',
            onRetry: () => retries++,
            onBack: () => backs++,
          ),
        ),
      ),
    );

    await pressTab(tester);
    expect(focusIsIn(find.byType(PrimaryButton)), isTrue);
    await pressTab(tester);
    expect(focusIsIn(find.byType(SecondaryButton)), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect((retries, backs), (0, 1));
  });

  group('with reduced motion', () {
    testWidgets('stops repeating', (tester) async {
      reduceMotion(tester);
      await tester.pumpWidget(
        inApp(const Center(child: LoadingStateView(message: 'Loading'))),
      );
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
