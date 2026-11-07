import 'package:flutter/widgets.dart';

import 'app_ready_notifier.dart';

class AppReadyScope extends InheritedNotifier<AppReadyNotifier> {
  const AppReadyScope({
    required super.notifier,
    required super.child,
    super.key,
  });

  /// The nearest notifier; the caller rebuilds when it notifies.
  static AppReadyNotifier of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppReadyScope>()!.notifier!;

  /// The nearest notifier, for callbacks that must not subscribe to it.
  static AppReadyNotifier read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppReadyScope>()!.notifier!;
}
