import 'package:flutter/widgets.dart';

import '../../theme/app_theme.dart';

/// Fades the bottom of the screen to black behind the navigation bar.
class GradientBottomFade extends StatelessWidget {
  const GradientBottomFade({super.key});

  static const double height = 150;

  static const LinearGradient _gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.transparent, AppColors.scrimStrong, AppColors.black],
  );

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: SizedBox(
        height: height,
        child: DecoratedBox(decoration: BoxDecoration(gradient: _gradient)),
      ),
    );
  }
}
