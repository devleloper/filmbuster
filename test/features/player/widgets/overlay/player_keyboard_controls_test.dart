import 'package:filmbuster/presentation/features/player/widgets/overlay/player_keyboard_controls.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/app.dart';

Future<void> _pumpControls(
  WidgetTester tester, {
  required VoidCallback onPlayPause,
}) async {
  final focusNode = FocusNode();
  addTearDown(focusNode.dispose);

  await tester.pumpWidget(
    inApp(
      PlayerKeyboardControls(
        focusNode: focusNode,
        onPlayPause: onPlayPause,
        onBack: () {},
        onSeekStep: (_) {},
        onShowControls: () {},
        child: const SizedBox.expand(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final (name, key) in [
    ('Space', LogicalKeyboardKey.space),
    ('Enter', LogicalKeyboardKey.enter),
    ('Select', LogicalKeyboardKey.select),
    ('gamepad A', LogicalKeyboardKey.gameButtonA),
  ]) {
    testWidgets(
      'holding $name toggles playback once and consumes the repeats',
      (tester) async {
        var toggles = 0;
        await _pumpControls(tester, onPlayPause: () => toggles++);

        await tester.sendKeyDownEvent(key);
        for (var i = 0; i < 3; i++) {
          expect(await tester.sendKeyRepeatEvent(key), isTrue);
        }
        await tester.sendKeyUpEvent(key);
        await tester.pump();

        expect(toggles, 1);
      },
    );
  }
}
