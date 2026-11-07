import 'package:filmbuster/presentation/widgets/feedback/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app.dart';

void main() {
  Widget screenWithButton(void Function(BuildContext context) onPressed) =>
      inApp(
        Center(
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: () => onPressed(context),
              child: const Text('Fail'),
            ),
          ),
        ),
      );

  testWidgets('shows the message with an error icon', (tester) async {
    await tester.pumpWidget(
      screenWithButton(
        (context) => showErrorSnackBar(context, 'Playback failed'),
      ),
    );

    await tester.tap(find.text('Fail'));
    await tester.pump();

    expect(find.text('Playback failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('a new error replaces the one on screen', (tester) async {
    var count = 0;
    await tester.pumpWidget(
      screenWithButton(
        (context) => showErrorSnackBar(context, 'Error ${++count}'),
      ),
    );

    await tester.tap(find.text('Fail'));
    await tester.pump();
    await tester.tap(find.text('Fail'));
    await tester.pumpAndSettle();

    expect(find.text('Error 1'), findsNothing);
    expect(find.text('Error 2'), findsOneWidget);
  });
}
