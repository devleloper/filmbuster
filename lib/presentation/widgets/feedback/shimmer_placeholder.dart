import 'package:flutter/widgets.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_theme.dart';

/// Paints its [ShimmerBox] descendants as one moving highlight, or as still
/// placeholders when the user asked for reduced motion.
class ShimmerGroup extends StatelessWidget {
  const ShimmerGroup({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          AppColors.glassSurfaceStrong,
          BlendMode.srcIn,
        ),
        child: child,
      );
    }
    return Shimmer.fromColors(
      baseColor: AppColors.glassSurfaceStrong,
      highlightColor: AppColors.borderStrong,
      child: child,
    );
  }
}

/// A placeholder block; only its shape matters, [ShimmerGroup] paints it.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.radius = AppRadius.sm,
    this.margin,
  });

  final double? width;
  final double? height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
    );
  }
}
