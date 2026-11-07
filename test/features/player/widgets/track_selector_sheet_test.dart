import 'package:filmbuster/presentation/features/player/models/player_tracks.dart';
import 'package:filmbuster/presentation/features/player/widgets/track_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app.dart';

const _tracks = [
  MediaTrack(id: '1', title: 'English', language: 'en'),
  MediaTrack(id: '2', language: 'de'),
];

Future<void> _open(WidgetTester tester, TrackSelectorSheet sheet) async {
  await tester.pumpWidget(
    inApp(
      Builder(
        builder: (context) => Center(
          child: GestureDetector(
            onTap: () => showTrackSelector(context, sheet),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('picking a track reports its id and closes the sheet', (
    tester,
  ) async {
    final picked = <String>[];
    await _open(
      tester,
      TrackSelectorSheet(
        title: 'Audio',
        tracks: _tracks,
        selectedId: '1',
        onSelected: picked.add,
      ),
    );

    await tester.tap(find.text('Track 2'));
    await tester.pumpAndSettle();

    expect(picked, ['2']);
    expect(find.byType(TrackSelectorSheet), findsNothing);
  });

  testWidgets('untitled tracks are numbered and show their language', (
    tester,
  ) async {
    await _open(
      tester,
      TrackSelectorSheet(
        title: 'Audio',
        tracks: _tracks,
        selectedId: null,
        onSelected: (_) {},
      ),
    );

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Track 2'), findsOneWidget);
    expect(find.text('Language: de'), findsOneWidget);
  });

  testWidgets('the Off row turns subtitles off and closes the sheet', (
    tester,
  ) async {
    var turnedOff = false;
    await _open(
      tester,
      TrackSelectorSheet(
        title: 'Subtitles',
        tracks: _tracks,
        selectedId: '2',
        onSelected: (_) {},
        onOffSelected: () => turnedOff = true,
      ),
    );

    await tester.tap(find.text('None (Off)'));
    await tester.pumpAndSettle();

    expect(turnedOff, isTrue);
    expect(find.byType(TrackSelectorSheet), findsNothing);
  });

  testWidgets('without tracks or an Off row, the sheet says so', (
    tester,
  ) async {
    await _open(
      tester,
      TrackSelectorSheet(
        title: 'Audio',
        tracks: const [],
        selectedId: null,
        emptyLabel: 'No audio tracks available',
        onSelected: (_) {},
      ),
    );

    expect(find.text('No audio tracks available'), findsOneWidget);
  });
}
