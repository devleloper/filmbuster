import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';

import 'core/app_ready/app_ready_notifier.dart';
import 'core/app_ready/app_ready_scope.dart';
import 'core/config/app_config.dart';
import 'core/di/injector.dart';
import 'core/licenses/third_party_licenses.dart';
import 'core/router/app_router.dart';
import 'core/utils/device_detector.dart';
import 'presentation/features/splash/view/app_splash_overlay.dart';
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  registerThirdPartyLicenses();
  configureDependencies();
  MediaKit.ensureInitialized();
  final directionalNavigation =
      AppConfig.forceLeanback || await DeviceDetector.detectTelevision();

  runApp(
    FilmbusterApp(
      appReadyNotifier: AppReadyNotifier(),
      router: buildRouter(),
      directionalNavigation: directionalNavigation,
    ),
  );
}

class FilmbusterApp extends StatelessWidget {
  const FilmbusterApp({
    super.key,
    required this.appReadyNotifier,
    required this.router,
    this.directionalNavigation = false,
  });

  final AppReadyNotifier appReadyNotifier;
  final GoRouter router;

  final bool directionalNavigation;

  // Browsers scroll the page with the arrow keys; the app moves focus with
  // them everywhere, so a keyboard or a remote drives it the same way.
  static const Map<ShortcutActivator, Intent> _arrowKeysMoveFocus = {
    SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
      TraversalDirection.up,
    ),
    SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
      TraversalDirection.down,
    ),
    SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(
      TraversalDirection.left,
    ),
    SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(
      TraversalDirection.right,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return AppReadyScope(
      notifier: appReadyNotifier,
      child: MaterialApp.router(
        title: 'Filmbuster',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: router,
        shortcuts: {...WidgetsApp.defaultShortcuts, ..._arrowKeysMoveFocus},
        builder: (context, child) {
          final app = AppSplashOverlay(child: child);
          if (!directionalNavigation) return app;
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(navigationMode: NavigationMode.directional),
            child: app,
          );
        },
      ),
    );
  }
}
