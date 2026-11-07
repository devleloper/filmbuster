import 'package:filmbuster/core/app_ready/app_ready_notifier.dart';
import 'package:filmbuster/core/app_ready/app_ready_scope.dart';
import 'package:filmbuster/core/config/data_source_mode.dart';
import 'package:filmbuster/core/di/injector.dart';
import 'package:filmbuster/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'disk_assets.dart';

/// [body] on a screen of the app's theme.
Widget inApp(Widget body) => MaterialApp(
  theme: buildAppTheme(),
  home: Scaffold(body: body),
);

/// [home] in the app's theme, once the splash has handed over to Home.
Widget afterSplash(Widget home, {TransitionBuilder? builder}) {
  final ready = AppReadyNotifier()..markSplashComplete();
  addTearDown(ready.dispose);
  return AppReadyScope(
    notifier: ready,
    child: MaterialApp(theme: buildAppTheme(), builder: builder, home: home),
  );
}

/// Unmounts the app and runs out the timers it leaves behind: entrance
/// delays and the image cache's cleanup, which runs 10 s after a load.
Future<void> unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 10));
}

Future<void> pumpRouterApp(
  WidgetTester tester,
  GoRouter router, {
  bool splashComplete = false,
}) {
  final ready = AppReadyNotifier();
  if (splashComplete) ready.markSplashComplete();
  addTearDown(ready.dispose);
  return tester.pumpWidget(
    AppReadyScope(
      notifier: ready,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

/// Pumps a second of frames. `pumpAndSettle` never returns while the hero
/// carousel or a loading indicator animates.
Future<void> pumpASecond(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Composes demo mode on the catalogue from disk for each test.
void useDemoDependencies() {
  setUp(
    () => configureDependencies(
      mode: DataSourceMode.demo,
      bundle: DiskAssetBundle(),
    ),
  );
  tearDown(resetDependencies);
}
