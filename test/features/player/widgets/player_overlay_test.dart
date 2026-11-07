import 'package:filmbuster/presentation/features/player/models/playback_status.dart';
import 'package:filmbuster/presentation/features/player/models/seek_steps.dart';
import 'package:filmbuster/presentation/features/player/widgets/overlay/player_bottom_controls.dart';
import 'package:filmbuster/presentation/features/player/widgets/overlay/player_center_control.dart';
import 'package:filmbuster/presentation/features/player/widgets/overlay/repeat_seek_controller.dart';
import 'package:filmbuster/presentation/features/player/widgets/player_commands.dart';
import 'package:filmbuster/presentation/features/player/widgets/player_overlay.dart';
import 'package:filmbuster/presentation/features/player/widgets/seek_indicator.dart';
import 'package:filmbuster/presentation/features/player/widgets/video_gesture_control_layer.dart';
import 'package:filmbuster/presentation/widgets/app_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';
import '../../../support/focus.dart';
import '../../../support/player_overlay_harness.dart';
import '../../../support/poppins.dart';
import '../../../support/test_view.dart';

SemanticsFinder get _showControlsButton =>
    find.semantics.byLabel('Show player controls');

Future<void> _pumpPlayer(
  WidgetTester tester, {
  PlayerCommands? commands,
  PlaybackStatus status = samplePlayback,
  bool landscape = true,
  bool screenReader = false,
}) async {
  usePhoneView(tester, landscape: landscape);
  if (screenReader) {
    useAccessibilityFeatures(
      tester,
      const FakeAccessibilityFeatures(accessibleNavigation: true),
    );
  }

  await tester.pumpWidget(
    inApp(
      VideoGestureControlLayer(
        child: buildOverlay(status: status, commands: commands),
      ),
    ),
  );
  await waitForControls(tester);
}

/// Pumps [buildOverlay] in the app's theme and lets it take the focus.
Future<void> _pumpOverlay(
  WidgetTester tester, {
  PlayerCommands? commands,
  bool fillsScreen = false,
}) async {
  await tester.pumpWidget(
    inApp(buildOverlay(commands: commands, fillsScreen: fillsScreen)),
  );
  await tester.pump();
}

Future<void> _tapCentre(WidgetTester tester) async {
  await tester.tapAt(tester.getRect(find.byType(PlayerOverlay)).center);
  await tester.pump();
  await waitForControls(tester);
}

const _buttons = [
  'Back',
  'Fullscreen',
  'Back 10 sec',
  'Forward 10 sec',
  'Subtitles',
  'Audio',
];

void _expectLabelledButtons() {
  for (final label in _buttons) {
    final buttons = find.semantics.byLabel(label);
    expect(buttons, findsOne, reason: label);
    expect(
      buttons.evaluate().single,
      isSemantics(
        label: label,
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
      reason: label,
    );
  }
  // The centre button and the one in the bottom row.
  expect(find.semantics.byLabel('Pause'), findsExactly(2));
}

void main() {
  group('fill', () {
    testWidgets('a fitted video offers fullscreen, which fills the screen', (
      tester,
    ) async {
      final fills = <bool>[];
      await _pumpOverlay(
        tester,
        commands: CallbackPlayerCommands(onFillsScreen: fills.add),
      );
      await waitForControls(tester);

      expect(find.semantics.byLabel('Fullscreen'), findsOne);
      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pump();

      expect(fills, [true]);
    });

    testWidgets('a video filled by a pinch offers to exit fullscreen, which '
        'fits it back', (tester) async {
      final fills = <bool>[];
      await _pumpOverlay(
        tester,
        commands: CallbackPlayerCommands(onFillsScreen: fills.add),
        fillsScreen: true,
      );
      await waitForControls(tester);

      expect(find.semantics.byLabel('Exit fullscreen'), findsOne);
      await tester.tap(find.byIcon(Icons.fullscreen_exit));
      await tester.pump();

      expect(fills, [false]);
    });
  });

  group('bottom panel tap zone', () {
    setUpAll(loadPoppins);

    // The bottom panel's height differs with each of these.
    const sizes = {
      'phone portrait': referencePhone,
      'phone landscape': Size(874, 402),
      'tablet landscape': Size(1366, 1024),
    };

    for (final MapEntry(key: name, value: size) in sizes.entries) {
      for (final inside in [true, false]) {
        final where = inside ? '1 dp inside' : '1 dp above';
        final outcome = inside ? 'keeps the controls' : 'hides the controls';

        testWidgets('$name: a tap $where the bottom panel $outcome', (
          tester,
        ) async {
          useViewSize(tester, size);
          await _pumpOverlay(tester);
          await waitForControls(tester);
          expect(_showControlsButton, findsNothing);

          final panel = tester.getRect(find.byType(PlayerBottomControls));
          expect(panel.bottom, size.height);
          await tester.tapAt(
            Offset(size.width / 2, inside ? panel.top + 1 : panel.top - 1),
          );
          await tester.pump();

          expect(_showControlsButton, inside ? findsNothing : findsOne);
        });
      }
    }
  });

  group('hidden controls', () {
    for (final playing in [false, true]) {
      final state = playing ? 'playing' : 'paused';

      testWidgets('tapping the centre of hidden controls only shows them '
          '($state)', (tester) async {
        var toggles = 0;
        await _pumpPlayer(
          tester,
          landscape: false,
          status: samplePlayback.copyWith(playing: playing),
          commands: CallbackPlayerCommands(onPlayPause: () => toggles++),
        );
        // The status stays the same, so only the tap can bring the controls
        // back.
        await waitForAutoHide(tester);
        expect(find.semantics.byLabel('Back'), findsNothing);

        await _tapCentre(tester);

        expect(toggles, 0);
        expect(find.semantics.byLabel('Back'), findsOne);
        expect(_showControlsButton, findsNothing);

        await _tapCentre(tester);

        expect(toggles, 1);
      });
    }

    testWidgets('a pointer tap on hidden controls still reaches the surface', (
      tester,
    ) async {
      await _pumpPlayer(tester);
      await waitForAutoHide(tester);
      expect(find.semantics.byLabel('Back'), findsNothing);

      // Empty video area between the top bar and the centre button.
      final area = tester.getRect(find.byType(PlayerOverlay));
      await tester.tapAt(Offset(area.center.dx, area.top + area.height * 0.3));
      await tester.pump();
      await waitForControls(tester);

      expect(find.semantics.byLabel('Back'), findsOne);
    });
  });

  group('gestures other than a tap', () {
    // A finger that rests this long has already been reported as pressed.
    const restingTime = Duration(milliseconds: 150);

    testWidgets('a pinch that starts with a resting finger leaves the '
        'controls alone', (tester) async {
      await _pumpPlayer(tester);
      final area = tester.getRect(find.byType(PlayerOverlay));
      final videoArea = Offset(area.center.dx, area.top + area.height * 0.3);

      final resting = await tester.startGesture(
        videoArea - const Offset(20, 0),
      );
      await tester.pump(restingTime);
      final spreading = await tester.startGesture(
        videoArea + const Offset(20, 0),
      );
      await spreading.moveBy(const Offset(100, 0));
      await resting.up();
      await spreading.up();
      await waitForControls(tester);

      expect(_showControlsButton, findsNothing);
    });

    testWidgets('a slow volume drag leaves the controls alone', (tester) async {
      await _pumpPlayer(tester);
      final area = tester.getRect(find.byType(PlayerOverlay));

      final drag = await tester.startGesture(
        Offset(area.right - 20, area.top + area.height * 0.3),
      );
      await tester.pump(restingTime);
      await drag.moveBy(const Offset(0, -100));
      await drag.up();
      await waitForControls(tester);

      expect(_showControlsButton, findsNothing);
      // Lets the volume indicator fade out.
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('keyboard', () {
    for (final key in [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.select,
      LogicalKeyboardKey.gameButtonA,
    ]) {
      testWidgets('${key.keyLabel} on the focused seek bar toggles playback', (
        tester,
      ) async {
        var toggles = 0;
        await _pumpOverlay(
          tester,
          commands: CallbackPlayerCommands(onPlayPause: () => toggles++),
        );
        await focusSeekBar(tester);

        await tester.sendKeyEvent(key);
        await tester.pump();

        expect(toggles, 1);
      });
    }

    testWidgets('a held arrow on the focused seek bar seeks once, on release', (
      tester,
    ) async {
      final seeks = <Duration>[];
      await _pumpOverlay(
        tester,
        commands: CallbackPlayerCommands(onSeekTo: seeks.add),
      );
      await focusSeekBar(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(seeks, isEmpty);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      // 36 s of 596 s, plus two steps of 2 % each.
      expect(seeks, [const Duration(seconds: 60)]);
    });

    testWidgets('with the overlay focused, arrows seek in 2 s steps', (
      tester,
    ) async {
      final relativeSeeks = <int>[];
      await _pumpOverlay(
        tester,
        commands: CallbackPlayerCommands(onSeekBy: relativeSeeks.add),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);

      expect(relativeSeeks, [-2, 2]);
    });

    testWidgets('a held arrow keeps seeking until it is released', (
      tester,
    ) async {
      final relativeSeeks = <int>[];
      await _pumpOverlay(
        tester,
        commands: CallbackPlayerCommands(onSeekBy: relativeSeeks.add),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(RepeatSeekController.interval * 3);
      expect(relativeSeeks, List.filled(4, arrowSeekSeconds));

      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(seconds: 1));
      expect(relativeSeeks, hasLength(4));
    });

    testWidgets('with the controls hidden, arrows seek', (tester) async {
      final relativeSeeks = <int>[];
      await _pumpOverlay(
        tester,
        commands: CallbackPlayerCommands(onSeekBy: relativeSeeks.add),
      );
      await waitForAutoHide(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);

      expect(relativeSeeks, [-2]);
    });

    testWidgets('the skip badge names the 2 s an arrow moved', (tester) async {
      await _pumpOverlay(tester);
      await waitForAutoHide(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(SeekIndicator),
          matching: find.text('2 s'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('on a focused button, Left and Right move between the buttons '
        'without seeking', (tester) async {
      final relativeSeeks = <int>[];
      await _pumpOverlay(
        tester,
        commands: CallbackPlayerCommands(onSeekBy: relativeSeeks.add),
      );
      await focusPlayerButton(tester, 'Pause');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusIsIn(playerButton('Forward 10 sec')), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusIsIn(playerButton('Pause')), isTrue);

      expect(relativeSeeks, isEmpty);
    });

    testWidgets('on a focused button, Up moves to the seek bar', (
      tester,
    ) async {
      await _pumpOverlay(tester);
      await focusPlayerButton(tester, 'Back 10 sec');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(focusIsIn(find.byType(AppSlider)), isTrue);
      expect(find.byType(PlayerBottomControls), findsOneWidget);
    });

    testWidgets('Up with the controls hidden shows them and focuses the '
        'centre button', (tester) async {
      await _pumpOverlay(tester);
      await waitForAutoHide(tester);
      expect(find.byType(PlayerCenterControl), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(focusIsIn(find.byType(PlayerCenterControl)), isTrue);
    });

    testWidgets('controls that hide with a button focused leave the keys to '
        'the player', (tester) async {
      final relativeSeeks = <int>[];
      await _pumpOverlay(
        tester,
        commands: CallbackPlayerCommands(onSeekBy: relativeSeeks.add),
      );
      await focusPlayerButton(tester, 'Forward 10 sec');
      await waitForAutoHide(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(relativeSeeks, [-2]);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusIsIn(find.byType(PlayerCenterControl)), isTrue);
    });
  });

  group('semantics', () {
    for (final (orientation, landscape) in [
      ('landscape', true),
      ('portrait', false),
    ]) {
      testWidgets(
        'visible controls are labelled 48 dp buttons ($orientation)',
        (tester) async {
          await _pumpPlayer(tester, landscape: landscape);

          _expectLabelledButtons();
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        },
      );
    }

    testWidgets('the seek bar is an adjustable slider valued '
        '"mm:ss of mm:ss"', (tester) async {
      final seeks = <int>[];
      await _pumpPlayer(
        tester,
        commands: CallbackPlayerCommands(onSeekBy: seeks.add),
      );

      final seek = find.semantics.byLabel('Seek');
      final node = seek.evaluate().single;
      expect(
        node,
        isSemantics(
          label: 'Seek',
          isSlider: true,
          value: '00:36 of 09:56',
          increasedValue: '00:46 of 09:56',
          decreasedValue: '00:26 of 09:56',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      expect(node.rect.height, greaterThanOrEqualTo(48));

      tester.semantics.increase(seek);
      tester.semantics.decrease(seek);
      expect(seeks, [10, -10]);

      await tester.pumpAndSettle();
    });

    testWidgets('hidden controls leave a labelled button that shows them', (
      tester,
    ) async {
      await _pumpPlayer(tester);
      await waitForAutoHide(tester);

      expect(find.semantics.byLabel('Back'), findsNothing);
      expect(
        _showControlsButton.evaluate().single,
        isSemantics(
          label: 'Show player controls',
          isButton: true,
          hasTapAction: true,
        ),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      tester.semantics.tap(_showControlsButton);
      await tester.pump();
      await waitForControls(tester);

      expect(_showControlsButton, findsNothing);
      _expectLabelledButtons();
    });

    testWidgets('controls stay up while a screen reader is on', (tester) async {
      await _pumpPlayer(tester, screenReader: true);
      await waitForAutoHide(tester);

      expect(_showControlsButton, findsNothing);
      _expectLabelledButtons();
    });
  });
}
