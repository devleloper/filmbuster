import 'package:filmbuster/presentation/features/player/models/playback_status.dart';
import 'package:filmbuster/presentation/features/player/services/progress_throttle.dart';
import 'package:flutter_test/flutter_test.dart';

const _step = Duration(milliseconds: 250);

const _playing = PlaybackStatus(
  position: Duration(seconds: 30),
  duration: Duration(minutes: 15),
  playing: true,
);

PlaybackStatus _at(Duration position) => _playing.copyWith(position: position);

void main() {
  late ProgressThrottle throttle;

  setUp(() {
    throttle = ProgressThrottle(step: _step)..admit(_playing);
  });

  test('admits the first status', () {
    expect(ProgressThrottle(step: _step).admit(_playing), isTrue);
  });

  test('holds back progress smaller than a step', () {
    final tick = _at(_playing.position + const Duration(milliseconds: 100));

    expect(throttle.admit(tick), isFalse);
  });

  test('admits progress of a step since the last admitted status', () {
    throttle.admit(_at(_playing.position + const Duration(milliseconds: 100)));

    expect(throttle.admit(_at(_playing.position + _step)), isTrue);
  });

  test('admits buffer growth of a step', () {
    expect(throttle.admit(_playing.copyWith(buffer: _step)), isTrue);
  });

  test('admits any change besides progress at once', () {
    final paused = _playing.copyWith(
      position: _playing.position + const Duration(milliseconds: 10),
      playing: false,
    );

    expect(throttle.admit(paused), isTrue);
  });

  test('admits the first tick at a pending seek target', () {
    const target = Duration(seconds: 30, milliseconds: 100);

    expect(throttle.admit(_at(target), pendingSeekTarget: target), isTrue);
  });
}
