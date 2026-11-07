import 'package:filmbuster/domain/models/player_source.dart';
import 'package:filmbuster/presentation/features/player/models/player_tracks.dart';
import 'package:filmbuster/presentation/features/player/widgets/overlay/player_bottom_controls.dart';
import 'package:filmbuster/presentation/features/player/widgets/overlay/player_overlay_data.dart';
import 'package:filmbuster/presentation/features/player/widgets/player_commands.dart';
import 'package:filmbuster/presentation/widgets/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/app.dart';
import '../../../../support/player_overlay_harness.dart';
import '../../../../support/poppins.dart';
import '../../../../support/test_view.dart';

const _sources = [
  PlayerSource(url: 'https://example.org/movie-1080.mp4', label: '1080p'),
  PlayerSource(url: 'https://example.org/movie-720.mp4', label: '720p'),
];

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required double textScale,
  bool switching = false,
  PlayerTracks tracks = PlayerTracks.empty,
  PlayerCommands? commands,
}) async {
  useViewSize(tester, size);
  useTextScale(tester, textScale);

  await tester.pumpWidget(
    inApp(
      Align(
        alignment: Alignment.bottomCenter,
        child: PlayerBottomControls(
          data: PlayerOverlayData(
            status: samplePlayback,
            currentSource: _sources.first,
            sources: _sources,
            isSwitchingQuality: switching,
            tracks: tracks,
          ),
          commands: commands ?? CallbackPlayerCommands(),
          onSeekDragChanged: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}

final _timeTexts = find.byWidgetPredicate(
  (w) => w is Text && RegExp(r'\d\d:\d\d').hasMatch(w.data ?? ''),
);

void _expectNoOverlap(WidgetTester tester) {
  expect(tester.takeException(), isNull);

  final times = _timeTexts.evaluate().toList();
  expect(times, isNotEmpty);
  final buttons = find.byType(AppIconButton).evaluate().toList();
  expect(
    buttons,
    hasLength(6),
    reason: '3 transport + quality, subtitles, audio',
  );

  for (final time in times) {
    final timeRect = tester.getRect(find.byWidget(time.widget));
    final paragraph = time.renderObject! as RenderParagraph;
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: '"${(time.widget as Text).data}" is cut',
    );
    for (final button in buttons) {
      final buttonRect = tester.getRect(find.byWidget(button.widget));
      expect(
        timeRect.overlaps(buttonRect),
        isFalse,
        reason: 'time $timeRect overlaps button $buttonRect',
      );
    }
  }

  // The trailing group never needs its horizontal scroll fallback.
  final scrollable = tester.state<ScrollableState>(
    find.descendant(
      of: find.byType(PlayerBottomControls),
      matching: find.byType(Scrollable),
    ),
  );
  expect(scrollable.position.maxScrollExtent, 0);
}

void main() {
  setUpAll(loadPoppins);

  const portraitSizes = {
    'iPhone 18 Pro': referencePhone,
    'iPhone 18 Pro Max': Size(440, 956),
    'compact Android': Size(360, 800),
  };

  for (final MapEntry(key: device, value: size) in portraitSizes.entries) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('$device portrait, text scale $scale: the time stays clear '
          'of the buttons', (tester) async {
        await _pump(tester, size: size, textScale: scale);

        _expectNoOverlap(tester);
        // Portrait: elapsed and total sit on their own line.
        expect(find.text('00:36'), findsOneWidget);
        expect(find.text('09:56'), findsOneWidget);
      });
    }
  }

  testWidgets('the time stays clear of the buttons while the source switches', (
    tester,
  ) async {
    await _pump(tester, size: referencePhone, textScale: 1.3, switching: true);

    _expectNoOverlap(tester);
  });

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('phone landscape, text scale $scale: the time stays in the '
        'button row', (tester) async {
      await _pump(tester, size: const Size(874, 402), textScale: scale);

      _expectNoOverlap(tester);
      expect(find.text('00:36 / 09:56'), findsOneWidget);
    });
  }

  testWidgets('screen readers hear the time as one label', (tester) async {
    await _pump(tester, size: referencePhone, textScale: 1.3);

    expect(find.bySemanticsLabel('Elapsed 00:36 of 09:56'), findsOneWidget);
  });

  group('track sheets', () {
    const subtitles = PlayerTracks(
      subtitles: [MediaTrack(id: '3', title: 'English')],
    );

    Future<List<String?>> openSubtitles(WidgetTester tester) async {
      final picked = <String?>[];
      await _pump(
        tester,
        size: const Size(874, 402),
        textScale: 1,
        tracks: subtitles,
        commands: CallbackPlayerCommands(onSubtitleTrack: picked.add),
      );
      await tester.tap(playerButton('Subtitles'));
      await tester.pumpAndSettle();
      return picked;
    }

    testWidgets('the subtitles button offers the tracks and sends the choice', (
      tester,
    ) async {
      final picked = await openSubtitles(tester);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(picked, ['3']);
    });

    testWidgets('the subtitles sheet can turn subtitles off', (tester) async {
      final picked = await openSubtitles(tester);

      await tester.tap(find.text('None (Off)'));
      await tester.pumpAndSettle();

      expect(picked, [null]);
    });
  });
}
