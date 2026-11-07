import 'dart:async';

import 'package:filmbuster/presentation/features/player/widgets/video_gesture_control_layer.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _brightnessChannel = MethodChannel(
  'github.com/aaassseee/screen_brightness',
);

/// Answers brightness reads with [brightness] and returns the names of the
/// methods called on the channel.
List<String> _mockBrightness(WidgetTester tester, Future<double> brightness) {
  final messenger = tester.binding.defaultBinaryMessenger;
  final calls = <String>[];
  messenger.setMockMethodCallHandler(_brightnessChannel, (call) {
    calls.add(call.method);
    return call.method.startsWith('get') ? brightness : Future.value();
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(_brightnessChannel, null),
  );
  return calls;
}

Future<void> _pumpLayer(WidgetTester tester) => tester.pumpWidget(
  const Directionality(
    textDirection: TextDirection.ltr,
    child: VideoGestureControlLayer(child: SizedBox.expand()),
  ),
);

void main() {
  testWidgets('leaving while the brightness is still being read is safe', (
    tester,
  ) async {
    final brightness = Completer<double>();
    _mockBrightness(tester, brightness.future);
    await _pumpLayer(tester);

    await tester.dragFrom(const Offset(20, 300), const Offset(0, -100));
    await tester.pumpWidget(const SizedBox());
    brightness.complete(0.8);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a drag changes nothing until the current level is read', (
    tester,
  ) async {
    final calls = _mockBrightness(tester, Completer<double>().future);
    await _pumpLayer(tester);

    final drag = await tester.startGesture(const Offset(20, 300));
    await drag.moveBy(const Offset(0, -100));
    await drag.up();
    await tester.pump();

    expect(calls.where((method) => method.startsWith('set')), isEmpty);
  });
}
