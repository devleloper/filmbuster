import 'package:filmbuster/presentation/features/player/models/playback_status.dart';
import 'package:filmbuster/presentation/features/player/services/stall_watchdog.dart';
import 'package:flutter_test/flutter_test.dart';

const _timeout = Duration(milliseconds: 20);
const _pastTimeout = Duration(milliseconds: 60);

const _buffering = PlaybackStatus(buffering: true);
const _flowing = PlaybackStatus(playing: true);

void main() {
  late int stalls;
  late StallWatchdog watchdog;

  setUp(() {
    stalls = 0;
    watchdog = StallWatchdog(timeout: _timeout, onStall: () => stalls++);
    addTearDown(watchdog.cancel);
  });

  testWidgets('reports buffering that outlasts the timeout', (tester) async {
    watchdog.observe(_buffering, seeking: false);

    await tester.pump(_pastTimeout);

    expect(stalls, 1);
  });

  testWidgets('keeps one watch through repeated buffering statuses', (
    tester,
  ) async {
    watchdog
      ..observe(_buffering, seeking: false)
      ..observe(_buffering, seeking: false);

    await tester.pump(_pastTimeout);

    expect(stalls, 1);
  });

  testWidgets('playback that flows again calls the watch off', (tester) async {
    watchdog
      ..observe(_buffering, seeking: false)
      ..observe(_flowing, seeking: false);

    await tester.pump(_pastTimeout);

    expect(stalls, 0);
  });

  testWidgets('buffering during a seek starts no watch', (tester) async {
    watchdog.observe(_buffering, seeking: true);

    await tester.pump(_pastTimeout);

    expect(stalls, 0);
  });
}
