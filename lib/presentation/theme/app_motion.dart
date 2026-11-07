import 'package:flutter/widgets.dart';

/// Honours the platform's reduce-motion setting (iOS Reduce Motion, Android
/// Remove animations): transitions finish instantly when it is on.
abstract final class AppMotion {
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or [Duration.zero] when the user asked for reduced motion.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
