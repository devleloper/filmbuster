import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

/// Stands in for a poster that is missing or failed to load.
class NoPosterPlaceholder extends StatelessWidget {
  const NoPosterPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.fontSize,
  });

  final double width;
  final double height;

  /// Label size; defaults to the 12 pt caption, the smallest readable size.
  final double? fontSize;

  static const double _iconSize = 32;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.glassSurfaceStrong,
      padding: const EdgeInsets.all(AppSpacing.sm),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            size: _iconSize,
            color: AppColors.textTertiary,
          ),
          AppSpacing.vGapXs,
          Text(
            'No Poster Available',
            style: AppTextStyles.caption.copyWith(fontSize: fontSize),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
