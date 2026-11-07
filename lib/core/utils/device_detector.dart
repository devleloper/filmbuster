import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'responsive.dart';

enum InputKind {
  /// Fingers on a touch screen, phones and tablets.
  touch,

  /// Mouse and keyboard, desktops and desktop browsers.
  pointer,

  /// A remote control or D-pad that only moves focus.
  directional,
}

/// Chooses between the touch and the leanback (TV and desktop) layouts.
/// Input kind wins over width: a touch tablet keeps the touch layout at any
/// width, a TV gets leanback whatever its logical width.
abstract final class DeviceDetector {
  @visibleForTesting
  static const MethodChannel channel = MethodChannel(
    'dev.devlet.filmbuster/device',
  );

  static const Duration _televisionQueryTimeout = Duration(milliseconds: 500);

  static InputKind inputKindOf(BuildContext context) => resolveInputKind(
    navigationMode: MediaQuery.navigationModeOf(context),
    platform: defaultTargetPlatform,
  );

  @visibleForTesting
  static InputKind resolveInputKind({
    required NavigationMode navigationMode,
    required TargetPlatform platform,
  }) {
    if (navigationMode == NavigationMode.directional) {
      return InputKind.directional;
    }
    return switch (platform) {
      TargetPlatform.iOS ||
      TargetPlatform.android ||
      TargetPlatform.fuchsia => InputKind.touch,
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => InputKind.pointer,
    };
  }

  /// Whether to use the leanback layout: always for a remote, never for
  /// touch, and on desktops once the window is wide enough for the side rail.
  static bool isLeanback(BuildContext context) =>
      switch (inputKindOf(context)) {
        InputKind.directional => true,
        InputKind.touch => false,
        InputKind.pointer => switch (ResponsiveLayout.of(context).breakpoint) {
          ResponsiveBreakpoint.large || ResponsiveBreakpoint.xlarge => true,
          ResponsiveBreakpoint.compact || ResponsiveBreakpoint.medium => false,
        },
      };

  /// Whether the app runs on an Android TV. Never throws: anything but a
  /// clear answer from the platform counts as "not a TV".
  static Future<bool> detectTelevision() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final isTelevision = await channel
          .invokeMethod<bool>('isTelevision')
          .timeout(_televisionQueryTimeout);
      return isTelevision ?? false;
    } on Exception {
      return false;
    }
  }
}
