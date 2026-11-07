import 'package:flutter/widgets.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/header_logo_layout.dart';
import '../../../widgets/app_logo.dart';

/// The logo centred on the background, matching the native launch screen.
class SplashLogoStatic extends StatelessWidget {
  const SplashLogoStatic({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(
        child: AppLogo(
          width: HeaderLogoLayout.splashWidth,
          height: HeaderLogoLayout.splashHeight,
        ),
      ),
    );
  }
}
