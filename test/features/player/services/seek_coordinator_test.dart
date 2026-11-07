import 'dart:async';

import 'package:filmbuster/presentation/features/player/services/seek_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecoverySteps {
  _RecoverySteps({
    this.seekLands = true,
    this.reopenLands = true,
    this.recreateLands = true,
  });

  final bool seekLands;
  final bool reopenLands;
  final bool recreateLands;

  final List<String> calls = [];
  final List<String> checks = [];
  final List<Duration> targets = [];
  final List<Completer<void>> hangingSteps = [];

  bool _lastStepLands = true;

  SeekCoordinator coordinator() => SeekCoordinator(
    seek: (target) => _step('seek', target, seekLands),
    reopen: (target) => _step('reopen', target, reopenLands),
    recreate: (target) => _step('recreate', target, recreateLands),
    awaitSettled: (target, within) => _check('settled'),
    awaitProgress: (target, within) => _check('progress'),
    seekBudget: const Duration(milliseconds: 10),
    reopenBudget: const Duration(milliseconds: 10),
    recreateBudget: const Duration(milliseconds: 10),
  );

  Future<bool> _check(String name) async {
    checks.add(name);
    return _lastStepLands;
  }

  Future<void> _step(String name, Duration target, bool lands) {
    calls.add(name);
    targets.add(target);
    _lastStepLands = lands;
    if (lands) return Future<void>.value();

    final completer = Completer<void>();
    hangingSteps.add(completer);
    return completer.future;
  }
}

void main() {
  group('SeekCoordinator', () {
    test('a seek that lands does not touch the recovery ladder', () async {
      final steps = _RecoverySteps();

      final outcome = await steps.coordinator().request(
        const Duration(minutes: 5),
      );

      expect(outcome, SeekOutcome.settled);
      expect(steps.calls, ['seek']);
    });

    test('a seek that never lands reopens the stream', () async {
      final steps = _RecoverySteps(seekLands: false);

      final outcome = await steps.coordinator().request(
        const Duration(minutes: 5),
      );

      expect(outcome, SeekOutcome.recovered);
      expect(steps.calls, ['seek', 'reopen']);
      expect(steps.targets, everyElement(const Duration(minutes: 5)));
    });

    test('a reopen that never lands rebuilds the engine', () async {
      final steps = _RecoverySteps(seekLands: false, reopenLands: false);

      final outcome = await steps.coordinator().request(
        const Duration(minutes: 5),
      );

      expect(outcome, SeekOutcome.recovered);
      expect(steps.calls, ['seek', 'reopen', 'recreate']);
    });

    test('reports failure once every rung has been tried', () async {
      final steps = _RecoverySteps(
        seekLands: false,
        reopenLands: false,
        recreateLands: false,
      );

      final outcome = await steps.coordinator().request(
        const Duration(minutes: 5),
      );

      expect(outcome, SeekOutcome.failed);
      expect(steps.calls, ['seek', 'reopen', 'recreate']);
    });

    test('a step that never completes does not block the sequence', () async {
      final steps = _RecoverySteps(seekLands: false);

      await steps.coordinator().request(const Duration(minutes: 5));

      expect(steps.hangingSteps.single.isCompleted, isFalse);
    });

    test('a stall recovery skips the plain seek', () async {
      final steps = _RecoverySteps();

      final outcome = await steps.coordinator().request(
        const Duration(minutes: 5),
        skipPlainSeek: true,
      );

      expect(outcome, SeekOutcome.recovered);
      expect(steps.calls, ['reopen']);
    });

    test('a seek checks that playback lands on the target', () async {
      final steps = _RecoverySteps(seekLands: false, reopenLands: false);

      await steps.coordinator().request(const Duration(minutes: 5));

      expect(steps.checks, ['settled', 'settled', 'settled']);
    });

    test('a stall recovery checks that playback moves on', () async {
      final steps = _RecoverySteps(reopenLands: false);

      await steps.coordinator().request(
        const Duration(minutes: 5),
        skipPlainSeek: true,
      );

      expect(steps.checks, ['progress', 'progress']);
    });

    test(
      'a seek made during a stall recovery starts with a plain seek',
      () async {
        final steps = _RecoverySteps();
        final coordinator = steps.coordinator();

        final recovery = coordinator.request(
          const Duration(seconds: 10),
          skipPlainSeek: true,
        );
        final seek = coordinator.request(const Duration(minutes: 5));

        expect(await seek, SeekOutcome.superseded);
        expect(await recovery, SeekOutcome.settled);
        expect(steps.calls, ['reopen', 'seek']);
      },
    );

    test(
      'requests made during a seek collapse into the latest target',
      () async {
        final steps = _RecoverySteps();
        final coordinator = steps.coordinator();

        final first = coordinator.request(const Duration(seconds: 10));
        final second = coordinator.request(const Duration(seconds: 20));
        final third = coordinator.request(const Duration(seconds: 30));

        expect(await second, SeekOutcome.superseded);
        expect(await third, SeekOutcome.superseded);
        expect(await first, SeekOutcome.settled);

        expect(steps.calls, ['seek', 'seek']);
        expect(steps.targets, [
          const Duration(seconds: 10),
          const Duration(seconds: 30),
        ]);
      },
    );
  });
}
