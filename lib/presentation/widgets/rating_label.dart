import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

/// A yellow star and [rating] to one decimal, the star as tall as [style].
class RatingLabel extends StatelessWidget {
  const RatingLabel({super.key, required this.rating, required this.style});

  final double rating;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xxxs,
      children: [
        Icon(
          Icons.star,
          size: style.fontSize,
          applyTextScaling: true,
          color: AppColors.primaryYellow,
        ),
        Text(rating.toStringAsFixed(1), style: style),
      ],
    );
  }
}
