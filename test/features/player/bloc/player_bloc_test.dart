import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/core/router/route_args.dart';
import 'package:filmbuster/domain/models/player_source.dart';
import 'package:filmbuster/presentation/features/player/bloc/player_bloc.dart';
import 'package:filmbuster/presentation/features/player/bloc/player_event.dart';
import 'package:filmbuster/presentation/features/player/bloc/player_state.dart';
import 'package:filmbuster/presentation/features/player/models/playback_status.dart';
import 'package:filmbuster/presentation/features/player/models/player_timings.dart';
import 'package:filmbuster/presentation/features/player/models/player_tracks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_playback_engine.dart';

const _source = PlayerSource(
  url: 'https://example.org/sintel-1080.mp4',
  label: '1080p',
);
const _otherSource = PlayerSource(
  url: 'https://example.org/sintel-720.mp4',
  label: '720p',
);

const _timings = PlayerTimings(
  firstFrame: Duration(milliseconds: 100),
  qualitySwitch: Duration(milliseconds: 100),
  stall: Duration(milliseconds: 100),
  seekCommitDelay: Duration(milliseconds: 20),
  engineCommand: Duration(milliseconds: 50),
  disposeGrace: Duration.zero,
  seekBudget: Duration(milliseconds: 30),
  reopenBudget: Duration(milliseconds: 30),
  recreateBudget: Duration(milliseconds: 30),
);

final _silentSourceTimeout =
    _timings.firstFrame * (_timings.maxSilentStarts + 1);

/// Longer than any chain of engine timeouts in [_timings].
const _allTimeoutsRunOut = Duration(seconds: 1);

const _playing = PlaybackStatus(
  position: Duration(seconds: 30),
  duration: Duration(minutes: 15),
  playing: true,
);

class _Session {
  _Session(this.tester) {
    bloc.stream.listen(states.add);
    addTearDown(bloc.close);
  }

  final WidgetTester tester;
  final FakePlaybackEngine engine = FakePlaybackEngine();
  final List<PlayerState> states = [];

  late final PlayerBloc bloc = PlayerBloc(
    args: const PlayerRouteArgs(
      source: _source,
      sources: [_source, _otherSource],
    ),
    engine: engine,
    timings: _timings,
  );

  PlayerState get state => bloc.state;

  Future<void> elapse([Duration duration = Duration.zero]) =>
      tester.pump(duration);

  Future<void> startPlaying() async {
    bloc.add(const PlayerStarted());
    await elapse();
    engine.report(_playing);
    await elapse();
  }

  Future<void> send(PlayerEvent event) async {
    bloc.add(event);
    await elapse();
  }
}

/// Runs [body] on the test clock against a fresh [_Session], then runs out
/// the timeouts left behind, which a widget test would report as pending.
void _sessionTest(
  String description,
  Future<void> Function(_Session session) body,
) {
  testWidgets(description, (tester) async {
    final session = _Session(tester);
    await body(session);
    await session.elapse(_allTimeoutsRunOut);
  });
}

void main() {
  group('loading', () {
    _sessionTest('opens the source and plays once the engine shows progress', (
      session,
    ) async {
      final engine = session.engine;

      await session.startPlaying();

      expect(engine.callsOf('open'), ['open ${_source.url} ${Duration.zero}']);
      expect(session.state.loading, isFalse);
      expect(session.state.failure, isNull);
      expect(session.state.currentSource, _source);
    });

    _sessionTest('rebuilds a silent engine, then reports the source as dead', (
      session,
    ) async {
      final engine = session.engine;

      await session.send(const PlayerStarted());
      await session.elapse(_silentSourceTimeout);

      expect(engine.callsOf('recreateAt'), hasLength(_timings.maxSilentStarts));
      expect(session.state.loading, isFalse);
      expect(session.state.failure, isA<ServerFailure>());
    });

    _sessionTest(
      'an engine rebuild that never finishes still ends in an error',
      (session) async {
        final engine = session.engine
          ..hangNext('recreateAt', times: _timings.maxSilentStarts);

        final worstCase =
            _silentSourceTimeout +
            _timings.engineCommand * _timings.maxSilentStarts;

        await session.send(const PlayerStarted());
        await session.elapse(worstCase);

        expect(
          engine.callsOf('recreateAt'),
          hasLength(_timings.maxSilentStarts),
        );
        expect(session.state.failure, isA<ServerFailure>());
      },
    );

    _sessionTest('retry after a failure loads the source again', (
      session,
    ) async {
      final engine = session.engine;
      await session.send(const PlayerStarted());
      await session.elapse(_silentSourceTimeout);
      final opensBefore = engine.callsOf('open').length;

      await session.send(const PlayerRetryRequested());

      expect(session.state.loading, isTrue);
      expect(session.state.failure, isNull);
      expect(engine.callsOf('open'), hasLength(opensBefore + 1));
    });

    _sessionTest('retry after a silent source rebuilds the engine again', (
      session,
    ) async {
      final engine = session.engine;
      await session.send(const PlayerStarted());
      await session.elapse(_silentSourceTimeout);
      final recreatesBefore = engine.callsOf('recreateAt').length;

      await session.send(const PlayerRetryRequested());
      await session.elapse(_silentSourceTimeout);

      expect(
        engine.callsOf('recreateAt').length - recreatesBefore,
        _timings.maxSilentStarts,
      );
      expect(session.state.failure, isA<ServerFailure>());
    });
  });

  group('commands', () {
    _sessionTest('play/pause pauses a playing engine', (session) async {
      await session.startPlaying();

      await session.send(const PlayerPlayPauseToggled());

      expect(session.engine.calls.last, 'pause');
    });

    _sessionTest('play/pause plays a paused engine', (session) async {
      await session.startPlaying();
      session.engine.report(_playing.copyWith(playing: false));

      await session.send(const PlayerPlayPauseToggled());

      expect(session.engine.calls.last, 'play');
    });

    _sessionTest('track choices reach the engine', (session) async {
      await session.startPlaying();

      await session.send(const PlayerAudioTrackSelected('2'));
      await session.send(const PlayerSubtitleTrackSelected('3'));
      await session.send(const PlayerSubtitleTrackSelected(null));

      expect(session.engine.calls.sublist(session.engine.calls.length - 3), [
        'selectAudioTrack 2',
        'selectSubtitleTrack 3',
        'selectSubtitleTrack null',
      ]);
    });

    _sessionTest('the tracks the engine reports reach the state', (
      session,
    ) async {
      await session.startPlaying();
      const tracks = PlayerTracks(
        audio: [MediaTrack(id: '1', language: 'en')],
        audioId: '1',
      );

      session.engine.reportTracks(tracks);
      await session.elapse();

      expect(session.state.tracks, tracks);
    });

    _sessionTest('a command the engine never answers rebuilds the stream and '
        'leaves the player responsive', (session) async {
      final engine = session.engine;
      await session.startPlaying();
      engine.hangNext('pause');

      await session.send(const PlayerPlayPauseToggled());
      await session.elapse(_timings.engineCommand);

      expect(
        session.states.map((state) => state.notice),
        contains('The player stopped responding. Reconnecting.'),
      );
      expect(engine.callsOf('open').last, startsWith('open ${_source.url}'));

      await session.send(const PlayerSeekRequested(Duration(minutes: 2)));
      expect(session.state.pendingSeekTarget, const Duration(minutes: 2));
    });

    _sessionTest('a command the engine rejects leaves the stream alone', (
      session,
    ) async {
      final engine = session.engine;
      await session.startPlaying();
      final opensBefore = engine.callsOf('open').length;
      engine.failNext('selectSubtitleTrack');

      await session.send(const PlayerSubtitleTrackSelected('3'));
      await session.elapse(_timings.engineCommand);

      expect(session.state.notice, isNull);
      expect(engine.callsOf('open'), hasLength(opensBefore));
    });

    _sessionTest('the viewer switches between filling and fitting the screen', (
      session,
    ) async {
      await session.startPlaying();

      await session.send(const PlayerFillScreenChanged(true));
      expect(session.state.fillsScreen, isTrue);

      await session.send(const PlayerFillScreenChanged(false));
      expect(session.state.fillsScreen, isFalse);
    });
  });

  group('recovery', () {
    Future<void> recoverStalledStream(_Session session) async {
      await session.send(const PlayerStallRecoveryRequested());
      session.engine.report(
        _playing.copyWith(
          position: _playing.position + const Duration(seconds: 2),
        ),
      );
      await session.elapse();
      await session.elapse();
    }

    _sessionTest('buffering that outlasts the stall timeout reopens the '
        'stream where it stopped', (session) async {
      final engine = session.engine;
      await session.startPlaying();

      engine.report(_playing.copyWith(buffering: true));
      await session.elapse(_timings.stall);
      await session.elapse();

      expect(engine.callsOf('open'), [
        'open ${_source.url} ${Duration.zero}',
        'open ${_source.url} ${_playing.position}',
      ]);
    });

    _sessionTest('buffering that ends in time leaves the stream alone', (
      session,
    ) async {
      final engine = session.engine;
      await session.startPlaying();

      engine.report(_playing.copyWith(buffering: true));
      await session.elapse(_timings.stall ~/ 2);
      engine.report(_playing);
      await session.elapse(_timings.stall);

      expect(engine.callsOf('open'), hasLength(1));
    });

    _sessionTest(
      'a stall timer that fires during a seek leaves the seek alone',
      (session) async {
        final engine = session.engine;
        await session.startPlaying();
        engine.report(_playing.copyWith(buffering: true));
        await session.elapse(_timings.stall - const Duration(milliseconds: 10));

        await session.send(const PlayerSeekRequested(Duration(minutes: 5)));
        await session.elapse(const Duration(milliseconds: 15));
        expect(session.state.isSeekBuffering, isTrue);
        engine.report(_playing.copyWith(position: const Duration(minutes: 5)));
        await session.elapse();

        expect(engine.callsOf('seek'), ['seek 0:05:00.000000']);
        expect(engine.callsOf('open'), hasLength(1));
      },
    );

    _sessionTest('a stream reopened after the viewer paused stays paused', (
      session,
    ) async {
      await session.startPlaying();
      await session.send(const PlayerPlayPauseToggled());

      await recoverStalledStream(session);

      expect(session.engine.calls.last, 'pause');
      expect(session.state.isSeekBuffering, isFalse);
    });

    _sessionTest('a stream reopened while playing keeps playing', (
      session,
    ) async {
      await session.startPlaying();

      await recoverStalledStream(session);

      expect(session.engine.callsOf('pause'), isEmpty);
    });

    _sessionTest('a seek made during a recovery that fails is dropped', (
      session,
    ) async {
      await session.startPlaying();
      await session.send(const PlayerStallRecoveryRequested());

      await session.send(const PlayerSeekRequested(Duration(minutes: 5)));
      await session.elapse(_allTimeoutsRunOut);

      expect(session.state.notice, startsWith('This source stopped'));
      expect(session.state.pendingSeekTarget, isNull);
    });

    _sessionTest(
      'a quality switch that never starts keeps the source and tells '
      'the viewer',
      (session) async {
        await session.startPlaying();

        await session.send(const PlayerQualitySwitchRequested(_otherSource));
        await session.elapse(_timings.qualitySwitch);

        expect(session.state.isSwitchingQuality, isFalse);
        expect(session.state.currentSource, _source);
        expect(session.state.notice, startsWith('Failed to switch quality'));
      },
    );

    _sessionTest('a quality switch completes once the new source plays on', (
      session,
    ) async {
      final engine = session.engine;
      await session.startPlaying();

      await session.send(const PlayerQualitySwitchRequested(_otherSource));
      engine.report(
        _playing.copyWith(
          position: _playing.position + const Duration(seconds: 2),
        ),
      );
      await session.elapse();

      expect(
        engine.callsOf('open').last,
        'open ${_otherSource.url} ${_playing.position}',
      );
      expect(session.state.isSwitchingQuality, isFalse);
      expect(session.state.currentSource, _otherSource);
      expect(session.state.notice, isNull);
    });
  });

  group('progress', () {
    _sessionTest('a burst of skips seeks once, to their sum', (session) async {
      await session.startPlaying();

      for (var i = 0; i < 3; i++) {
        await session.send(const PlayerRelativeSeekRequested(10));
      }
      expect(session.state.pendingSeekTarget, const Duration(minutes: 1));
      await session.elapse(_timings.seekCommitDelay);
      session.engine.report(
        _playing.copyWith(position: const Duration(minutes: 1)),
      );
      await session.elapse();

      expect(session.engine.callsOf('seek'), ['seek 0:01:00.000000']);
      expect(session.engine.callsOf('open'), hasLength(1));
    });

    _sessionTest('position ticks reach the state at most every progress step', (
      session,
    ) async {
      await session.startPlaying();
      session.states.clear();

      for (var tick = 1; tick <= 20; tick++) {
        session.engine.report(
          _playing.copyWith(
            position: _playing.position + Duration(milliseconds: 50 * tick),
          ),
        );
        await session.elapse();
      }

      final published = session.states.map((state) => state.playback).toSet();
      expect(published.length, lessThanOrEqualTo(6));
    });

    _sessionTest('a pause reaches the state without waiting for a step', (
      session,
    ) async {
      await session.startPlaying();

      session.engine.report(
        _playing.copyWith(
          position: _playing.position + const Duration(milliseconds: 10),
          playing: false,
        ),
      );
      await session.elapse();

      expect(session.state.playback?.playing, isFalse);
    });

    _sessionTest('a pending seek clears on the first tick at its target', (
      session,
    ) async {
      await session.startPlaying();
      const target = Duration(minutes: 5);
      await session.send(const PlayerSeekRequested(target));
      expect(session.state.pendingSeekTarget, target);

      session.engine.report(_playing.copyWith(position: target));
      await session.elapse();

      expect(session.state.pendingSeekTarget, isNull);
    });
  });

  test(
    'closing pauses the engine and disposes it after the grace period',
    () async {
      final engine = FakePlaybackEngine();
      const grace = Duration(milliseconds: 50);
      final bloc = PlayerBloc(
        args: const PlayerRouteArgs(source: _source),
        engine: engine,
        timings: const PlayerTimings(disposeGrace: grace),
      );
      bloc.add(const PlayerStarted());
      await pumpEventQueue();

      await bloc.close();

      expect(engine.callsOf('pause'), hasLength(1));
      expect(engine.callsOf('dispose'), isEmpty);
      await Future<void>.delayed(grace);
      expect(engine.callsOf('dispose'), hasLength(1));
    },
  );
}
