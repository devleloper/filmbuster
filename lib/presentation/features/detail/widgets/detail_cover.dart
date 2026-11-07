import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/media_image.dart';

class DetailCover extends StatelessWidget {
  const DetailCover({
    super.key,
    required this.title,
    this.posterPath,
    this.backdropPath,
  });

  final String title;
  final String? posterPath;
  final String? backdropPath;

  static const LinearGradient _titleScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.transparent, AppColors.scrimStrong, AppColors.black],
  );

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => MediaImage.backdrop(
            path: backdropPath ?? posterPath,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 150,
          child: DecoratedBox(decoration: BoxDecoration(gradient: _titleScrim)),
        ),
        Positioned(
          left: r.horizontalPadding,
          right: r.horizontalPadding,
          bottom: AppSpacing.lg,
          child: Text(
            title,
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 24, // design-literal: one-off cover title size
            ),
          ),
        ),
      ],
    );
  }
}
