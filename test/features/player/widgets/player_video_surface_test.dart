import 'package:filmbuster/presentation/features/player/models/seek_steps.dart';
import 'package:filmbuster/presentation/features/player/widgets/player_video_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';
import '../../../support/fake_playback_engine.dart';
import '../../../support/player_overlay_harness.dart';

void main() {
  testWidgets(
    'the video leaves the keys to the controls drawn over it',
    (tester) async {
      final relativeSeeks = <int>[];
      await tester.pumpWidget(
        inApp(
          Stack(
            fit: StackFit.expand,
            children: [
              PlayerVideoSurface(
                controller: SilentVideoController(),
                aspectRatio: null,
                fillsScreen: false,
              ),
              buildOverlay(
                commands: CallbackPlayerCommands(onSeekBy: relativeSeeks.add),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);

      expect(relativeSeeks, [arrowSeekSeconds]);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.macOS,
    }),
  );

  testWidgets(
    'a buffering video leaves the spinner to the controls drawn over it',
    (tester) async {
      await tester.pumpWidget(
        inApp(
          PlayerVideoSurface(
            controller: SilentVideoController(buffering: true),
            aspectRatio: null,
            fillsScreen: false,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.macOS,
    }),
  );
}
