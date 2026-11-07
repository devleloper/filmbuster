import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_shadows.dart';

/// A frosted vertical bar filled from the bottom to [value] (0 to 1).
class GlassSliderIndicator extends StatelessWidget {
  const GlassSliderIndicator({super.key, required this.value});

  final double value;

  static const double _width = 32;
  static const double _height = 120;
  static const _radius = Radius.circular(16);
  static const _fillRadius = Radius.circular(12);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(_radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: _width,
          height: _height,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.4),
            borderRadius: const BorderRadius.all(_radius),
            border: Border.all(width: 0.5, color: AppColors.borderStrong),
            boxShadow: AppShadows.overVideo,
          ),
          child: FractionallySizedBox(
            heightFactor: value.clamp(0.0, 1.0),
            widthFactor: 1,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(bottom: _fillRadius),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
