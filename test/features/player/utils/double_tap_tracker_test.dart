import 'package:filmbuster/presentation/features/player/utils/double_tap_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

final _start = DateTime(2026);
const _shortly = Duration(milliseconds: 200);

void main() {
  test('a second tap close in time and place is a double tap', () {
    final taps = DoubleTapTracker();

    expect(taps.register(const Offset(100, 100), _start), isFalse);
    expect(taps.register(const Offset(110, 105), _start.add(_shortly)), isTrue);
  });

  test('a second tap after the window starts over', () {
    final taps = DoubleTapTracker();
    taps.register(const Offset(100, 100), _start);

    final tooLate = _start.add(DoubleTapTracker.window);

    expect(taps.register(const Offset(100, 100), tooLate), isFalse);
  });

  test('a second tap far away starts over', () {
    final taps = DoubleTapTracker();
    taps.register(const Offset(100, 100), _start);

    expect(
      taps.register(const Offset(300, 100), _start.add(_shortly)),
      isFalse,
    );
  });

  test('a third quick tap starts a new double tap', () {
    final taps = DoubleTapTracker();
    taps
      ..register(Offset.zero, _start)
      ..register(Offset.zero, _start.add(_shortly));

    expect(taps.register(Offset.zero, _start.add(_shortly * 2)), isFalse);
  });
}
