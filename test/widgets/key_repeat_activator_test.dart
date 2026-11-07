import 'package:filmbuster/presentation/widgets/key_repeat_activator.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KeyRepeatActivator', () {
    late int invocations;

    Future<void> pumpEnterRepeatShortcut(WidgetTester tester) async {
      invocations = 0;
      await tester.pumpWidget(
        Shortcuts(
          shortcuts: const {
            KeyRepeatActivator(LogicalKeyboardKey.enter): _RepeatIntent(),
          },
          child: Actions(
            actions: {
              _RepeatIntent: CallbackAction<_RepeatIntent>(
                onInvoke: (_) => invocations++,
              ),
            },
            child: const Focus(autofocus: true, child: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('invokes its intent for each repeat of a held key, not for '
        'the press or the release', (tester) async {
      await pumpEnterRepeatShortcut(tester);

      final pressHandled = await tester.sendKeyDownEvent(
        LogicalKeyboardKey.enter,
      );
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      final releaseHandled = await tester.sendKeyUpEvent(
        LogicalKeyboardKey.enter,
      );

      expect(invocations, 2);
      expect(pressHandled, isFalse);
      expect(releaseHandled, isFalse);
    });

    testWidgets('ignores the repeats of another key', (tester) async {
      await pumpEnterRepeatShortcut(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      final repeatHandled = await tester.sendKeyRepeatEvent(
        LogicalKeyboardKey.space,
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);

      expect(invocations, 0);
      expect(repeatHandled, isFalse);
    });
  });
}

class _RepeatIntent extends Intent {
  const _RepeatIntent();
}
