import 'package:filmbuster/presentation/features/player/utils/pinch_fill_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PinchFillTracker pinch;

  setUp(() => pinch = PinchFillTracker()..start());

  test('spreading past the threshold fills, once per pinch', () {
    expect(pinch.update(1.05), isNull);
    expect(pinch.update(1.1), isTrue);
    expect(pinch.update(0.5), isNull);
  });

  test('closing past the threshold fits', () {
    expect(pinch.update(0.9), isFalse);
  });

  test('a small pinch keeps the mode', () {
    expect(pinch.update(1.05), isNull);
    expect(pinch.update(0.95), isNull);
  });

  test('the next pinch decides again', () {
    pinch.update(1.1);

    pinch.start();

    expect(pinch.update(0.9), isFalse);
  });
}
