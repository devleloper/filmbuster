import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:camera/camera.dart';
import 'package:filmbuster/presentation/features/player/bloc/player_bloc.dart';
import 'package:filmbuster/presentation/features/player/bloc/player_event.dart';
import 'package:filmbuster/presentation/features/player/bloc/player_state.dart';
import 'package:filmbuster/presentation/features/player/vr/services/head_tracker.dart';
import 'package:filmbuster/presentation/features/player/vr/services/vr_camera.dart';
import 'package:filmbuster/presentation/features/player/vr/vr_mode_selection.dart';
import 'package:filmbuster/presentation/features/player/vr/vr_player_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../support/app.dart';
import '../../../support/fake_playback_engine.dart';
import '../../../support/player_overlay_harness.dart';

const _dimmingStep = 'HapticFeedbackType.selectionClick';
const _recenter = 'HapticFeedbackType.lightImpact';

const _playing = PlayerState(loading: false, playback: samplePlayback);

final _findsOnePerEye = findsNWidgets(2);

class _MockPlayerBloc extends MockBloc<PlayerEvent, PlayerState>
    implements PlayerBloc {}

class _NoCamera implements VrCamera {
  @override
  Future<CameraController?> open() async => null;

  @override
  Future<void> close() async {}
}

/// The gyroscope behind the screen's head gestures.
class _FakeGyroscope extends SensorsPlatform {
  final _readings = StreamController<GyroscopeEvent>.broadcast();

  /// Reports the head turning at [rate] rad/s, to the left when positive,
  /// at time [at].
  void turn(double rate, {required Duration at}) =>
      _readings.add(GyroscopeEvent(rate, 0, 0, DateTime(2026).add(at)));

  @override
  Stream<GyroscopeEvent> gyroscopeEventStream({
    Duration samplingPeriod = SensorInterval.normalInterval,
  }) => _readings.stream;

  Future<void> close() => _readings.close();
}

/// The haptic feedback the screen asks for, which tells its gestures apart
/// while the video is still loading.
List<String> _recordHaptics(TestDefaultBinaryMessenger messenger) {
  final haptics = <String>[];
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') {
      haptics.add(call.arguments as String);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return haptics;
}

/// Pumps the spatial scene for a player in [state] and returns the haptic
/// feedback it asks for.
Future<List<String>> _pumpSpatialScreen(
  WidgetTester tester, {
  PlayerState state = const PlayerState(),
}) async {
  final haptics = _recordHaptics(tester.binding.defaultBinaryMessenger);
  final headTracker = HeadTracker(
    gyroscope: const Stream.empty(),
    accelerometer: const Stream.empty(),
  );
  addTearDown(headTracker.dispose);
  final bloc = _MockPlayerBloc();
  when(() => bloc.state).thenReturn(state);
  final video = SilentVideoController();

  await tester.pumpWidget(
    inApp(
      BlocProvider<PlayerBloc>.value(
        value: bloc,
        child: VrPlayerScreen(
          selection: const VrModeSelection(mode: VrMode.spatial),
          camera: _NoCamera(),
          headTracker: headTracker,
          commands: CallbackPlayerCommands(),
          videoController: () => video,
        ),
      ),
    ),
  );
  return haptics;
}

Future<void> _doubleTap(WidgetTester tester) async {
  await tester.tap(find.byType(VrPlayerScreen));
  await tester.pump(kDoubleTapMinTime);
  await tester.tap(find.byType(VrPlayerScreen));
  await tester.pump(kDoubleTapTimeout);
}

Future<void> _pinchOut(WidgetTester tester) async {
  final center = tester.getCenter(find.byType(VrPlayerScreen));
  final left = await tester.startGesture(center - const Offset(40, 0));
  final right = await tester.startGesture(center + const Offset(40, 0));
  for (var step = 0; step < 4; step++) {
    await left.moveBy(const Offset(-20, 0));
    await right.moveBy(const Offset(20, 0));
    await tester.pump();
  }
  await left.up();
  await right.up();
  await tester.pump();
}

/// Shakes the head left, right and left again.
Future<void> _shakeHead(WidgetTester tester, _FakeGyroscope gyroscope) async {
  gyroscope
    ..turn(3, at: Duration.zero)
    ..turn(-3, at: const Duration(milliseconds: 100))
    ..turn(3, at: const Duration(milliseconds: 200));
  // The readings arrive after this frame; the next one draws the gesture.
  await tester.pump();
  await tester.pump();
}

/// How large the screen is drawn, 1 being its fitted size.
double _screenScale(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .byWidgetPredicate(
            (widget) => widget is Transform && widget.child is AspectRatio,
          )
          .first,
    )
    .transform
    .getMaxScaleOnAxis();

void main() {
  late _FakeGyroscope gyroscope;

  setUp(() {
    gyroscope = _FakeGyroscope();
    SensorsPlatform.instance = gyroscope;
  });

  tearDown(() => gyroscope.close());

  testWidgets('a tap steps the camera dimming', (tester) async {
    final haptics = await _pumpSpatialScreen(tester);

    await tester.tap(find.byType(VrPlayerScreen));
    await tester.pump(kDoubleTapTimeout);

    expect(haptics, [_dimmingStep]);
    await unmountApp(tester);
  });

  testWidgets('a double tap recenters without touching the dimming', (
    tester,
  ) async {
    final haptics = await _pumpSpatialScreen(tester);

    await _doubleTap(tester);

    expect(haptics, [_recenter]);
    await unmountApp(tester);
  });

  testWidgets('a hold let go before exit leaves the dimming alone', (
    tester,
  ) async {
    final haptics = await _pumpSpatialScreen(tester);

    await tester.longPress(find.byType(VrPlayerScreen));
    await tester.pump(kDoubleTapTimeout);

    expect(haptics, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('a head shake recenters and keeps the pinched screen size', (
    tester,
  ) async {
    await _pumpSpatialScreen(tester, state: _playing);
    await _pinchOut(tester);
    final pinched = _screenScale(tester);
    expect(pinched, greaterThan(1));

    await _shakeHead(tester, gyroscope);

    expect(find.text('Recenter'), _findsOnePerEye);
    expect(_screenScale(tester), pinched);
    await unmountApp(tester);
  });

  testWidgets('a double tap recenters and restores the screen size', (
    tester,
  ) async {
    await _pumpSpatialScreen(tester, state: _playing);
    await _pinchOut(tester);

    await _doubleTap(tester);

    expect(find.text('Recenter'), _findsOnePerEye);
    expect(_screenScale(tester), 1);
    await unmountApp(tester);
  });
}
