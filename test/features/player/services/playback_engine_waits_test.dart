import 'package:filmbuster/presentation/features/player/models/playback_status.dart';
import 'package:filmbuster/presentation/features/player/services/playback_engine_waits.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_playback_engine.dart';

const _within = Duration(milliseconds: 50);

const _playing = PlaybackStatus(
  position: Duration(seconds: 30),
  duration: Duration(minutes: 15),
  playing: true,
);

void main() {
  late FakePlaybackEngine engine;

  setUp(() {
    engine = FakePlaybackEngine();
    addTearDown(engine.dispose);
  });

  /// Reports [status] once the wait has started listening.
  void reportSoon(PlaybackStatus status) =>
      Future<void>.delayed(Duration.zero, () => engine.report(status));

  group('startsWithin', () {
    test('is true at once for playback that has started', () async {
      engine.status = _playing;

      expect(await engine.startsWithin(_within), isTrue);
    });

    test('is true when playback starts in time', () async {
      reportSoon(_playing);

      expect(await engine.startsWithin(_within), isTrue);
    });

    test('is false for an engine that reports nothing', () async {
      expect(await engine.startsWithin(_within), isFalse);
    });
  });

  group('settlesWithin', () {
    const target = Duration(minutes: 5);

    test('accepts a position within the seek tolerance', () async {
      reportSoon(
        _playing.copyWith(position: target - PlaybackStatus.seekTolerance),
      );

      expect(await engine.settlesWithin(target, _within), isTrue);
    });

    test('rejects a position further off', () async {
      reportSoon(
        _playing.copyWith(position: target - const Duration(seconds: 3)),
      );

      expect(await engine.settlesWithin(target, _within), isFalse);
    });
  });

  group('playsOnPastWithin', () {
    test('is false while playback stays where it was', () async {
      reportSoon(_playing);

      expect(
        await engine.playsOnPastWithin(_playing.position, _within),
        isFalse,
      );
    });

    test('is false for playback that is paused past it', () async {
      reportSoon(
        _playing.copyWith(
          position: _playing.position + PlaybackEngineWaits.progressProof * 2,
          playing: false,
        ),
      );

      expect(
        await engine.playsOnPastWithin(_playing.position, _within),
        isFalse,
      );
    });

    test('is true once playback moves past the proof distance', () async {
      reportSoon(
        _playing.copyWith(
          position: _playing.position + PlaybackEngineWaits.progressProof * 2,
        ),
      );

      expect(
        await engine.playsOnPastWithin(_playing.position, _within),
        isTrue,
      );
    });
  });
}
