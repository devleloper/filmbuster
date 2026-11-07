import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/tmdb_movie.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/media_image.dart';
import '../../../widgets/no_poster_placeholder.dart';
import '../../../widgets/rating_label.dart';

class SearchResultCard extends StatelessWidget {
  const SearchResultCard({super.key, required this.movie});

  /// Corner radius before breakpoint scaling.
  static const double radius = 20;

  /// Poster size before breakpoint scaling.
  static const Size posterSize = Size(90, 135);

  final TmdbMovie movie;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final secondaryStyle = r.scaleText(AppTextStyles.bodyMedium);
    final posterWidth = r.scaled(posterSize.width);
    final posterHeight = r.scaled(posterSize.height);
    final inset = r.scaled(AppSpacing.sm);
    final year = movie.releaseYear;
    final rating = movie.voteAverage;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(r.scaled(radius)),
        border: Border.all(color: AppColors.border),
      ),
      padding: EdgeInsets.fromLTRB(inset, inset, 0, inset),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(r.scaled(AppRadius.md)),
            child: MediaImage(
              path: movie.posterPath,
              width: posterWidth,
              height: posterHeight,
              fallback: NoPosterPlaceholder(
                width: posterWidth,
                height: posterHeight,
              ),
            ),
          ),
          SizedBox(width: r.scaled(AppSpacing.md)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: inset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: r.scaleText(
                      AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: r.scaled(AppSpacing.xxs)),
                  Row(
                    spacing: inset,
                    children: [
                      if (year != null) Text('$year', style: secondaryStyle),
                      if (rating != null)
                        RatingLabel(
                          rating: rating,
                          style: r.scaleText(AppTextStyles.labelMedium),
                        ),
                    ],
                  ),
                  SizedBox(height: r.scaled(AppSpacing.xs)),
                  Text(
                    movie.overview ?? 'No overview available',
                    style: secondaryStyle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
