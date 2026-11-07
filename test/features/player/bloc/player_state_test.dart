import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/presentation/features/player/bloc/player_state.dart';
import 'package:filmbuster/presentation/features/player/models/playback_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _status = PlaybackStatus(
  position: Duration(seconds: 30),
  duration: Duration(minutes: 15),
  buffer: Duration(seconds: 40),
  playing: true,
  width: 1920,
  height: 1080,
);

const _base = PlayerState(loading: false, playback: _status);

void main() {
  group('PlayerState.sameSurfaceAs', () {
    test('ignores playback progress and control-only fields', () {
      final ticked = _base.copyWith(
        playback: _status.copyWith(
          position: const Duration(minutes: 1),
          buffer: const Duration(minutes: 2),
          playing: false,
        ),
        pendingSeekTarget: const Duration(minutes: 3),
        isSwitchingQuality: true,
        notice: 'Reconnecting.',
      );

      expect(ticked.sameSurfaceAs(_base), isTrue);
    });

    final changes = {
      'loading': _base.copyWith(loading: true),
      'failure': _base.copyWith(failure: const ServerFailure(message: 'x')),
      'video presence': const PlayerState(loading: false),
      'engine generation': _base.copyWith(engineGeneration: 1),
      'screen fill': _base.copyWith(fillsScreen: true),
      'seek buffering': _base.copyWith(isSeekBuffering: true),
      'aspect ratio': _base.copyWith(playback: _status.copyWith(height: 800)),
    };
    for (final MapEntry(key: field, value: changed) in changes.entries) {
      test('notices a change in $field', () {
        expect(changed.sameSurfaceAs(_base), isFalse);
      });
    }
  });

  group('PlayerState.copyWith', () {
    test('a repeated notice is a new state, so the viewer sees it again', () {
      final first = const PlayerState().copyWith(notice: 'Reconnecting.');
      final repeated = first.copyWith(notice: 'Reconnecting.');

      expect(repeated, isNot(first));
      expect(repeated.noticeId, first.noticeId + 1);
    });
  });
}
