import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/router/route_args.dart';
import '../models/playback_status.dart';
import '../models/player_timings.dart';
import '../services/playback_engine.dart';
import '../services/playback_engine_waits.dart';
import '../services/progress_throttle.dart';
import '../services/seek_coordinator.dart';
import '../services/stall_watchdog.dart';
import 'player_event.dart';
import 'player_state.dart';

/// Drives one playback session: opening the source, seeking, recovering a
/// stalled stream and relaying the viewer's commands to the engine.
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc({
    required PlayerRouteArgs args,
    required PlaybackEngine engine,
    PlayerTimings timings = const PlayerTimings(),
  }) : _args = args,
       _engine = engine,
       _timings = timings,
       super(
         PlayerState(
           sources: args.sources,
           artworkPath: args.artworkPath,
           movieTitle: args.movieTitle,
         ),
       ) {
    on<PlayerStarted>(_onStarted);
    on<PlayerRetryRequested>(_onRetryRequested);
    on<PlayerPlaybackStatusChanged>(_onPlaybackStatusChanged);
    on<PlayerTracksChanged>(_onTracksChanged);
    on<PlayerPlayPauseToggled>(_onPlayPauseToggled);
    on<PlayerAudioTrackSelected>(_onAudioTrackSelected);
    on<PlayerSubtitleTrackSelected>(_onSubtitleTrackSelected);
    on<PlayerSeekRequested>(_onSeekRequested);
    on<PlayerRelativeSeekRequested>(_onRelativeSeekRequested);
    on<PlayerSeekCommitRequested>(_onSeekCommitRequested);
    on<PlayerStallRecoveryRequested>(_onStallRecoveryRequested);
    on<PlayerQualitySwitchRequested>(_onQualitySwitchRequested);
    on<PlayerFillScreenChanged>(_onFillScreenChanged);
  }

  static const _log = AppLogger('Player');

  static const _sourceStoppedNotice =
      'This source stopped responding. Try another one.';
  static const _engineStuckNotice =
      'The player stopped responding. Reconnecting.';
  static const _qualitySwitchFailedNotice =
      'Failed to switch quality: The source did not start in time. '
      'Please try another one.';

  final PlayerRouteArgs _args;
  final PlaybackEngine _engine;
  final PlayerTimings _timings;

  late final SeekCoordinator _seeks = SeekCoordinator(
    seek: _engine.seek,
    reopen: (target) => _engine.open(_streamUrl, start: target),
    recreate: (target) => _engine.recreateAt(_streamUrl, target),
    awaitSettled: _engine.settlesWithin,
    awaitProgress: _engine.playsOnPastWithin,
    seekBudget: _timings.seekBudget,
    reopenBudget: _timings.reopenBudget,
    recreateBudget: _timings.recreateBudget,
  );
  late final ProgressThrottle _progress = ProgressThrottle(
    step: _timings.progressStep,
  );
  late final StallWatchdog _stalls = StallWatchdog(
    timeout: _timings.stall,
    onStall: () {
      if (!_isGone) add(const PlayerStallRecoveryRequested());
    },
  );

  final List<StreamSubscription<Object?>> _engineSubscriptions = [];
  Timer? _seekCommitTimer;
  bool _started = false;
  bool _closing = false;
  bool _wantsPlaying = true;

  String get _streamUrl => state.currentSource?.url ?? _args.source.url;

  bool get _isGone => _closing || isClosed;

  Future<void> _onStarted(
    PlayerStarted event,
    Emitter<PlayerState> emit,
  ) async {
    if (_started) return;
    _started = true;

    _engine.create();
    _engineSubscriptions.addAll([
      _engine.statusChanges.listen(_onEngineStatus),
      _engine.trackChanges.listen((tracks) => add(PlayerTracksChanged(tracks))),
    ]);

    await _loadMedia(emit);
  }

  Future<void> _onRetryRequested(
    PlayerRetryRequested event,
    Emitter<PlayerState> emit,
  ) => _loadMedia(emit);

  Future<void> _loadMedia(Emitter<PlayerState> emit) async {
    emit(state.copyWith(loading: true, clearFailure: true));

    final source = _args.source;
    if (source.url.isEmpty) {
      _failLoading(
        const ValidationFailure(
          message: 'No playable source was provided for this movie.',
        ),
        emit,
      );
      return;
    }
    emit(state.copyWith(currentSource: source));

    _openAndPlay(source.url);
    var silentStarts = 0;
    while (!await _engine.startsWithin(_timings.firstFrame)) {
      if (_isGone) return;
      if (silentStarts == _timings.maxSilentStarts) {
        _failLoading(
          const ServerFailure(
            message:
                'This source never started playing. Please try another one.',
          ),
          emit,
        );
        return;
      }
      silentStarts++;
      _log.warn('no frames from the engine, restarting it ($silentStarts)');
      await _answersInTime(
        'recreate',
        () => _engine.recreateAt(source.url, Duration.zero),
      );
      if (_isGone) return;
      _openAndPlay(source.url);
    }
  }

  void _failLoading(AppFailure failure, Emitter<PlayerState> emit) {
    _log.error('playback failed: ${failure.message}');
    emit(state.copyWith(loading: false, failure: failure));
  }

  void _onEngineStatus(PlaybackStatus status) {
    if (_isGone ||
        !_progress.admit(status, pendingSeekTarget: state.pendingSeekTarget)) {
      return;
    }
    add(PlayerPlaybackStatusChanged(status));
  }

  void _onPlaybackStatusChanged(
    PlayerPlaybackStatusChanged event,
    Emitter<PlayerState> emit,
  ) {
    final status = event.status;
    _stalls.observe(status, seeking: state.isSeekBuffering);

    final firstFrames =
        state.loading && status.hasStarted && state.currentSource != null;
    if (firstFrames) unawaited(_engine.hardenForStreaming());

    final target = state.pendingSeekTarget;
    emit(
      state.copyWith(
        playback: status,
        engineGeneration: _engine.generation,
        loading: firstFrames ? false : null,
        clearPendingSeekTarget: target != null && status.isNear(target),
      ),
    );
  }

  void _onTracksChanged(PlayerTracksChanged event, Emitter<PlayerState> emit) {
    emit(state.copyWith(tracks: event.tracks));
  }

  Future<void> _onPlayPauseToggled(
    PlayerPlayPauseToggled event,
    Emitter<PlayerState> emit,
  ) {
    _wantsPlaying = !_engine.status.playing;
    return _wantsPlaying
        ? _sendCommand('play', _engine.play, emit)
        : _sendCommand('pause', _engine.pause, emit);
  }

  Future<void> _onAudioTrackSelected(
    PlayerAudioTrackSelected event,
    Emitter<PlayerState> emit,
  ) => _sendCommand(
    'select audio track',
    () => _engine.selectAudioTrack(event.id),
    emit,
  );

  Future<void> _onSubtitleTrackSelected(
    PlayerSubtitleTrackSelected event,
    Emitter<PlayerState> emit,
  ) => _sendCommand(
    'select subtitle track',
    () => _engine.selectSubtitleTrack(event.id),
    emit,
  );

  void _onFillScreenChanged(
    PlayerFillScreenChanged event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(fillsScreen: event.fillsScreen));
  }

  Future<void> _onSeekRequested(
    PlayerSeekRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (_isGone) return;
    _seekCommitTimer?.cancel();
    emit(
      state.copyWith(
        pendingSeekTarget: _engine.status.clampToMedia(event.target),
      ),
    );
    await _commitSeek(emit);
  }

  void _onRelativeSeekRequested(
    PlayerRelativeSeekRequested event,
    Emitter<PlayerState> emit,
  ) {
    if (_isGone) return;
    final base = state.pendingSeekTarget ?? _engine.status.position;
    final target = base + Duration(seconds: event.seconds);
    emit(
      state.copyWith(pendingSeekTarget: _engine.status.clampToMedia(target)),
    );

    _seekCommitTimer?.cancel();
    _seekCommitTimer = Timer(_timings.seekCommitDelay, () {
      if (!_isGone) add(const PlayerSeekCommitRequested());
    });
  }

  Future<void> _onSeekCommitRequested(
    PlayerSeekCommitRequested event,
    Emitter<PlayerState> emit,
  ) => _commitSeek(emit);

  Future<void> _commitSeek(Emitter<PlayerState> emit) async {
    final target = state.pendingSeekTarget;
    if (target == null || _isGone || !_engine.isCreated) return;

    // A seek buffers by design; a stall timer started before it is stale.
    _stalls.cancel();
    emit(state.copyWith(isSeekBuffering: true));
    final outcome = await _seeks.request(target);
    if (_isGone || outcome == SeekOutcome.superseded) return;

    await _finishSeek(outcome, emit, clearPendingSeekTarget: true);
  }

  Future<void> _onStallRecoveryRequested(
    PlayerStallRecoveryRequested event,
    Emitter<PlayerState> emit,
  ) async {
    // A seek in progress climbs the same recovery steps on its own.
    if (_isGone || !_engine.isCreated || state.isSeekBuffering) return;
    _log.warn('playback stalled, rebuilding the stream');

    emit(state.copyWith(isSeekBuffering: true));
    final outcome = await _seeks.request(
      _engine.status.position,
      skipPlainSeek: true,
    );
    if (_isGone || outcome == SeekOutcome.superseded) return;

    await _finishSeek(outcome, emit, clearPendingSeekTarget: false);
  }

  Future<void> _finishSeek(
    SeekOutcome outcome,
    Emitter<PlayerState> emit, {
    required bool clearPendingSeekTarget,
  }) async {
    final failed = outcome == SeekOutcome.failed;
    emit(
      state.copyWith(
        isSeekBuffering: false,
        // A target that was never reached must not anchor the next skip.
        clearPendingSeekTarget: clearPendingSeekTarget || failed,
        engineGeneration: _engine.generation,
        notice: failed ? _sourceStoppedNotice : null,
      ),
    );
    // Reopening a stream starts playback; a viewer who had paused expects
    // it to stay paused.
    if (outcome == SeekOutcome.recovered && !_wantsPlaying) {
      await _sendCommand('pause', _engine.pause, emit);
    }
  }

  Future<void> _onQualitySwitchRequested(
    PlayerQualitySwitchRequested event,
    Emitter<PlayerState> emit,
  ) async {
    final source = event.source;
    if (state.currentSource?.url == source.url) return;

    emit(state.copyWith(isSwitchingQuality: true));
    final resumeAt = _engine.status.position;
    _openAndPlay(source.url, start: resumeAt);
    // Until the new source plays, the engine still reports the old one.
    final started = await _engine.playsOnPastWithin(
      resumeAt,
      _timings.qualitySwitch,
    );
    if (_isGone) return;

    if (started) {
      emit(state.copyWith(currentSource: source, isSwitchingQuality: false));
    } else {
      _log.warn('quality switch to ${source.label} did not start');
      emit(
        state.copyWith(
          isSwitchingQuality: false,
          notice: _qualitySwitchFailedNotice,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    _closing = true;
    _stalls.cancel();
    _seekCommitTimer?.cancel();
    await Future.wait([
      for (final subscription in _engineSubscriptions) subscription.cancel(),
    ]);
    if (_engine.isCreated) {
      unawaited(_engine.pause().catchError((Object _) {}));
      unawaited(Future<void>.delayed(_timings.disposeGrace, _engine.dispose));
    }
    return super.close();
  }

  /// Sends a command that must answer within [PlayerTimings.engineCommand];
  /// an engine that does not is rebuilt.
  Future<void> _sendCommand(
    String name,
    Future<void> Function() run,
    Emitter<PlayerState> emit,
  ) async {
    if (await _answersInTime(name, run) || _isGone) return;
    emit(state.copyWith(notice: _engineStuckNotice));
    add(const PlayerStallRecoveryRequested());
  }

  Future<bool> _answersInTime(String name, Future<void> Function() run) async {
    try {
      await run().timeout(_timings.engineCommand);
    } on TimeoutException {
      _log.warn('$name timed out');
      return false;
    } catch (error) {
      // A command that fails outright was still answered.
      _log.warn('$name failed: $error');
    }
    return true;
  }

  void _openAndPlay(String url, {Duration start = Duration.zero}) {
    _wantsPlaying = true;
    unawaited(
      _engine
          .open(url, start: start)
          .catchError((Object error) => _log.warn('open failed: $error')),
    );
  }
}
