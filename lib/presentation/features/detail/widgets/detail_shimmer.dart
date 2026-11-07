import 'package:flutter/widgets.dart';

import '../../../../core/utils/responsive.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/feedback/shimmer_placeholder.dart';
import 'detail_content.dart';

class DetailShimmer extends StatelessWidget {
  const DetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    // A bar is as tall as the letters of the text it stands in for.
    double barFor(TextStyle style) => r.scaled(style.fontSize!);
    final bodyBar = barFor(AppTextStyles.bodyMedium);

    return ShimmerGroup(
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: r.horizontalPadding,
          vertical: r.scaled(AppSpacing.md),
        ),
        children: [
          ShimmerBox(
            height: DetailContent.coverHeightFor(r.breakpoint),
            radius: r.scaled(AppRadius.xl),
          ),
          SizedBox(height: r.scaled(AppSpacing.lg)),
          ShimmerBox(
            height: barFor(AppTextStyles.headlineMedium),
            width: r.scaled(180),
          ),
          SizedBox(height: r.scaled(10)),
          ShimmerBox(
            height: barFor(AppTextStyles.titleMedium),
            width: r.scaled(120),
          ),
          SizedBox(height: r.scaled(14)),
          ShimmerBox(height: bodyBar, width: double.infinity, radius: 4),
          SizedBox(height: r.scaled(10)),
          ShimmerBox(height: bodyBar, width: double.infinity, radius: 4),
          SizedBox(height: r.scaled(10)),
          ShimmerBox(height: bodyBar, width: r.scaled(220), radius: 4),
          SizedBox(height: r.scaled(AppSpacing.xl)),
          ShimmerBox(
            height: barFor(AppTextStyles.titleLarge),
            width: r.scaled(100),
          ),
          SizedBox(height: r.scaled(AppSpacing.md)),
          for (var i = 0; i < 3; i++)
            ShimmerBox(
              height: r.scaled(64),
              radius: r.scaled(AppRadius.md),
              margin: EdgeInsets.only(bottom: r.scaled(AppSpacing.md)),
            ),
        ],
      ),
    );
  }
}
