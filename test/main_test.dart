import 'package:filmbuster/core/app_ready/app_ready_notifier.dart';
import 'package:filmbuster/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app.dart';

void main() {
  testWidgets('arrow keys move the caret inside a text field', (tester) async {
    final text = TextEditingController(text: 'dune');
    addTearDown(text.dispose);
    final ready = AppReadyNotifier();
    addTearDown(ready.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              Scaffold(body: TextField(controller: text, autofocus: true)),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      FilmbusterApp(appReadyNotifier: ready, router: router),
    );
    await tester.pump();
    text.selection = const TextSelection.collapsed(offset: 4);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);

    expect(text.selection.baseOffset, 3);
    await unmountApp(tester);
  });
}
