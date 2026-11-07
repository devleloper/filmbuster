import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/utils/device_detector.dart';
import '../../../../core/utils/responsive.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/header_logo_layout.dart';
import '../../../widgets/adaptive/adaptive_scaffold.dart';
import '../../../widgets/app_logo.dart';

/// Shrinks the logo from the centre into the Home header while the
/// background fades out, then calls [onAnimationComplete].
class SplashLogoAnimated extends StatefulWidget {
  const SplashLogoAnimated({super.key, required this.onAnimationComplete});

  static const duration = Duration(milliseconds: 800);

  final VoidCallback onAnimationComplete;

  @override
  State<SplashLogoAnimated> createState() => _SplashLogoAnimatedState();
}

class _SplashLogoAnimatedState extends State<SplashLogoAnimated>
    with SingleTickerProviderStateMixin {
  static const _curve = Curves.easeInOutCubic;
  static const _splashSize = Size(
    HeaderLogoLayout.splashWidth,
    HeaderLogoLayout.splashHeight,
  );
  static const _headerSize = Size(
    HeaderLogoLayout.width,
    HeaderLogoLayout.height,
  );

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: SplashLogoAnimated.duration)
          ..addStatusListener((status) {
            if (status.isCompleted) widget.onAnimationComplete();
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controller.isDismissed) return;
    if (AppMotion.reduced(context)) {
      // Completing calls back into the parent, which is building this widget.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.value = 1;
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final r = ResponsiveLayout.of(context);
    // The splash sits above the shell, so it clears the rail itself.
    final leftInset = DeviceDetector.isLeanback(context)
        ? math.max(padding.left, AdaptiveScaffold.leanbackContentInset)
        : padding.left;
    final headerTopLeft = Offset(
      leftInset + r.horizontalPadding,
      padding.top + HeaderLogoLayout.top,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _curve.transform(_controller.value);
        final backgroundOpacity = 1 - const Interval(0.5, 1).transform(t);
        final logoSize = Size.lerp(_splashSize, _headerSize, t)!;
        final centred = Alignment.center.inscribe(logoSize, Offset.zero & size);
        final logo = Offset.lerp(centred.topLeft, headerTopLeft, t)! & logoSize;
        return Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.background.withValues(
                  alpha: backgroundOpacity,
                ),
              ),
            ),
            Positioned.fromRect(
              rect: logo,
              child: ClipRect(
                child: AppLogo(width: logo.width, height: logo.height),
              ),
            ),
          ],
        );
      },
    );
  }
}
