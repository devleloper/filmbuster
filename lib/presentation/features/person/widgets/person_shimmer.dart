import 'package:flutter/widgets.dart';

import '../../../../core/utils/responsive.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/feedback/shimmer_placeholder.dart';
import '../../../widgets/movie_poster_card.dart';
import 'person_hero.dart';

class PersonShimmer extends StatelessWidget {
  const PersonShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final posterCardHeight = MoviePosterCard.heightFor(context);
    final avatarWidth = r.scaled(PersonHero.avatarSize.width);
    final avatarHeight = r.scaled(PersonHero.avatarSize.height);
    final lineHeight = r.scaled(AppTextStyles.bodyMedium.fontSize!);
    final gap = r.scaled(AppSpacing.md);

    return ShimmerGroup(
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: r.horizontalPadding,
          vertical: r.scaled(AppSpacing.sm),
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: avatarWidth,
                height: avatarHeight,
                radius: r.scaled(AppRadius.md),
              ),
              SizedBox(width: r.scaled(AppSpacing.lg)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: r.scaled(80), height: lineHeight),
                    SizedBox(height: gap),
                    ShimmerBox(
                      width: double.infinity,
                      height: lineHeight,
                      radius: 4,
                    ),
                    SizedBox(height: r.scaled(AppSpacing.sm)),
                    ShimmerBox(
                      width: double.infinity,
                      height: lineHeight,
                      radius: 4,
                    ),
                    SizedBox(height: r.scaled(AppSpacing.sm)),
                    ShimmerBox(
                      width: r.scaled(180),
                      height: lineHeight,
                      radius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: r.scaled(AppSpacing.xxl)),
          ShimmerBox(
            width: r.scaled(80),
            height: r.scaled(AppTextStyles.titleLarge.fontSize!),
            radius: 4,
          ),
          SizedBox(height: gap),
          SizedBox(
            height: posterCardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, _) => SizedBox(width: gap),
              itemBuilder: (_, _) => ShimmerBox(
                width: r.posterCardWidth,
                height: posterCardHeight,
                radius: r.scaled(AppRadius.lg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
