import 'package:filmbuster/core/utils/device_detector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceDetector.resolveInputKind', () {
    InputKind resolve(
      TargetPlatform platform, {
      NavigationMode navigationMode = NavigationMode.traditional,
    }) => DeviceDetector.resolveInputKind(
      navigationMode: navigationMode,
      platform: platform,
    );

    test('phones and tablets are driven by touch', () {
      expect(resolve(TargetPlatform.iOS), InputKind.touch);
      expect(resolve(TargetPlatform.android), InputKind.touch);
    });

    test('desktops are driven by a pointer', () {
      expect(resolve(TargetPlatform.macOS), InputKind.pointer);
      expect(resolve(TargetPlatform.windows), InputKind.pointer);
      expect(resolve(TargetPlatform.linux), InputKind.pointer);
    });

    test('directional navigation wins on any platform', () {
      for (final platform in TargetPlatform.values) {
        expect(
          resolve(platform, navigationMode: NavigationMode.directional),
          InputKind.directional,
        );
      }
    });
  });

  group('DeviceDetector.isLeanback', () {
    Future<bool> isLeanbackAt(
      WidgetTester tester, {
      required Size size,
      NavigationMode navigationMode = NavigationMode.traditional,
    }) async {
      late bool leanback;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size, navigationMode: navigationMode),
          child: Builder(
            builder: (context) {
              leanback = DeviceDetector.isLeanback(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return leanback;
    }

    testWidgets('a touch tablet keeps the touch layout at any width', (
      tester,
    ) async {
      expect(await isLeanbackAt(tester, size: const Size(1024, 1366)), isFalse);
      expect(await isLeanbackAt(tester, size: const Size(1366, 1024)), isFalse);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('a remote control gets leanback even on a narrow screen', (
      tester,
    ) async {
      expect(
        await isLeanbackAt(
          tester,
          size: const Size(600, 960),
          navigationMode: NavigationMode.directional,
        ),
        isTrue,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('a desktop window switches to leanback from 900 dp', (
      tester,
    ) async {
      expect(await isLeanbackAt(tester, size: const Size(899, 600)), isFalse);
      expect(await isLeanbackAt(tester, size: const Size(900, 600)), isTrue);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  });

  group('DeviceDetector.detectTelevision', () {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(
      () => messenger.setMockMethodCallHandler(DeviceDetector.channel, null),
    );

    test('reports what Android answers', () async {
      messenger.setMockMethodCallHandler(
        DeviceDetector.channel,
        (call) async => call.method == 'isTelevision',
      );

      expect(await DeviceDetector.detectTelevision(), isTrue);
    });

    test('is false when the platform has no answer', () async {
      expect(await DeviceDetector.detectTelevision(), isFalse);
    });

    test('is false when the platform reports an error', () async {
      messenger.setMockMethodCallHandler(
        DeviceDetector.channel,
        (call) async => throw PlatformException(code: 'unavailable'),
      );

      expect(await DeviceDetector.detectTelevision(), isFalse);
    });

    test('does not ask outside Android', () async {
      var asked = false;
      messenger.setMockMethodCallHandler(DeviceDetector.channel, (call) async {
        asked = true;
        return true;
      });
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final television = await DeviceDetector.detectTelevision();

      expect(television, isFalse);
      expect(asked, isFalse);
    });
  });
}
