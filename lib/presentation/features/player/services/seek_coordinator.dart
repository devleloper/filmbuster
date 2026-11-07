import 'dart:async';

import '../../../../core/logging/app_logger.dart';

enum SeekOutcome {
  /// A plain seek reached the target.
  settled,

  /// The target was reached by reopening the stream or rebuilding the engine.
  recovered,

  /// Every recovery step was tried and the target was never reached.
  failed,

  /// A newer request replaced this one before it finished.
  superseded,
}

typedef SeekStep = Future<void> Function(Duration target);

/// Completes with whether the engine shows, within [within], that a step
/// towards [target] worked.
typedef SeekCheck = Future<bool> Function(Duration target, Duration within);

/// Moves playback to a target through ever stronger steps: a plain seek,
/// reopening the stream, then rebuilding the engine.
///
/// A step's own future is not awaited, since a wedged engine may never
/// complete it; instead each step gets a budget to show the target in the
/// status stream. Requests made while one runs collapse into the latest.
class SeekCoordinator {
  SeekCoordinator({
    required SeekStep seek,
    required SeekStep reopen,
    required SeekStep recreate,
    required SeekCheck awaitSettled,
    required SeekCheck awaitProgress,
    required Duration seekBudget,
    required Duration reopenBudget,
    required Duration recreateBudget,
  }) : _seek = seek,
       _reopen = reopen,
       _recreate = recreate,
       _awaitSettled = awaitSettled,
       _awaitProgress = awaitProgress,
       _seekBudget = seekBudget,
       _reopenBudget = reopenBudget,
       _recreateBudget = recreateBudget;

  static const _log = AppLogger('Seek');

  final SeekStep _seek;
  final SeekStep _reopen;
  final SeekStep _recreate;
  final SeekCheck _awaitSettled;
  final SeekCheck _awaitProgress;

  final Duration _seekBudget;
  final Duration _reopenBudget;
  final Duration _recreateBudget;

  ({Duration target, bool skipPlainSeek})? _queued;
  bool _running = false;

  /// Starts at the reopen step when [skipPlainSeek] is set, for a stream
  /// that stalled where it is.
  Future<SeekOutcome> request(
    Duration target, {
    bool skipPlainSeek = false,
  }) async {
    _queued = (target: target, skipPlainSeek: skipPlainSeek);
    if (_running) return SeekOutcome.superseded;

    _running = true;
    try {
      var outcome = SeekOutcome.failed;
      for (var next = _queued; next != null; next = _queued) {
        _queued = null;
        outcome = await _commit(next.target, skipPlainSeek: next.skipPlainSeek);
      }
      return outcome;
    } finally {
      _running = false;
    }
  }

  Future<SeekOutcome> _commit(
    Duration target, {
    required bool skipPlainSeek,
  }) async {
    if (!skipPlainSeek) {
      if (await _attempt(_seek, target, _seekBudget, _awaitSettled)) {
        return SeekOutcome.settled;
      }
      _log.warn('seek to $target did not land, reopening the stream');
    }

    // A stalled stream reopens where it already is, so only playback moving
    // on proves that it flows again.
    final landed = skipPlainSeek ? _awaitProgress : _awaitSettled;
    if (await _attempt(_reopen, target, _reopenBudget, landed)) {
      return SeekOutcome.recovered;
    }
    _log.warn('reopen at $target did not land, rebuilding the engine');

    if (await _attempt(_recreate, target, _recreateBudget, landed)) {
      return SeekOutcome.recovered;
    }

    _log.error('could not reach $target: engine is unresponsive');
    return SeekOutcome.failed;
  }

  Future<bool> _attempt(
    SeekStep step,
    Duration target,
    Duration budget,
    SeekCheck landed,
  ) {
    unawaited(
      Future<void>.sync(
        () => step(target),
      ).catchError((Object error) => _log.warn('seek step failed: $error')),
    );
    return landed(target, budget);
  }
}
