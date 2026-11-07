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

void main() {
  group('PlaybackStatus.sameExceptProgress', () {
    test('ignores position and buffer', () {
      final ticked = _status.copyWith(
        position: const Duration(seconds: 31),
        buffer: const Duration(seconds: 45),
      );

      expect(ticked.sameExceptProgress(_status), isTrue);
    });

    final changes = {
      'duration': _status.copyWith(duration: const Duration(minutes: 16)),
      'playing': _status.copyWith(playing: false),
      'buffering': _status.copyWith(buffering: true),
      'completed': _status.copyWith(completed: true),
      'width': _status.copyWith(width: 1280),
      'height': _status.copyWith(height: 720),
    };
    for (final MapEntry(key: field, value: changed) in changes.entries) {
      test('notices a change in $field', () {
        expect(changed.sameExceptProgress(_status), isFalse);
      });
    }
  });

  group('PlaybackStatus.isNear', () {
    const target = Duration(minutes: 5);

    test('accepts a position within the seek tolerance either side', () {
      for (final offset in [
        PlaybackStatus.seekTolerance,
        -PlaybackStatus.seekTolerance,
      ]) {
        expect(
          _status.copyWith(position: target + offset).isNear(target),
          isTrue,
        );
      }
    });

    test('rejects a position beyond the tolerance', () {
      final beyond =
          target +
          PlaybackStatus.seekTolerance +
          const Duration(milliseconds: 1);

      expect(_status.copyWith(position: beyond).isNear(target), isFalse);
    });
  });
}
