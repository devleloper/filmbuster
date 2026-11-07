import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../../../core/app_ready/app_ready_scope.dart';
import '../widgets/splash_logo_animated.dart';
import '../widgets/splash_logo_static.dart';

/// Covers the app with the logo until Home has content, then moves the logo
/// into the Home header. After three seconds it stops waiting, so a slow
/// backend shows Home's own loading and error states instead of a frozen logo.
class AppSplashOverlay extends StatefulWidget {
  const AppSplashOverlay({super.key, required this.child});

  final Widget? child;

  @override
  State<AppSplashOverlay> createState() => _AppSplashOverlayState();
}

class _AppSplashOverlayState extends State<AppSplashOverlay> {
  static const _maxWait = Duration(seconds: 3);

  late final Timer _deadline;
  bool _overlayVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => FlutterNativeSplash.remove(),
    );
    _deadline = Timer(_maxWait, () => AppReadyScope.read(context).markReady());
  }

  @override
  void dispose() {
    _deadline.cancel();
    super.dispose();
  }

  void _onLogoAnimationComplete() {
    AppReadyScope.read(context).markSplashComplete();
    setState(() => _overlayVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    final ready = AppReadyScope.of(context).ready;
    return Stack(
      fit: StackFit.expand,
      children: [
        ?widget.child,
        if (_overlayVisible)
          IgnorePointer(
            child: ready
                ? SplashLogoAnimated(
                    onAnimationComplete: _onLogoAnimationComplete,
                  )
                : const SplashLogoStatic(),
          ),
      ],
    );
  }
}
