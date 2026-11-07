import 'package:flutter/widgets.dart';

import '../../core/utils/responsive.dart';
import '../../domain/models/tmdb_movie.dart';
import '../theme/app_theme.dart';
import 'focusable_lift_card.dart';
import 'media_image.dart';
import 'no_poster_placeholder.dart';
import 'rating_label.dart';

/// A movie's poster above its title, rating and release year, sized for the
/// current breakpoint and text scale.
class MoviePosterCard extends StatelessWidget {
  const MoviePosterCard({super.key, required this.movie, required this.onTap});

  final TmdbMovie movie;
  final VoidCallback onTap;

  static const int _titleMaxLines = 2;

  static const _border = Border.fromBorderSide(
    BorderSide(color: AppColors.border),
  );

  static TextStyle _titleStyle(ResponsiveLayout r) =>
      r.scaleText(AppTextStyles.captionStrong);

  static TextStyle _detailStyle(ResponsiveLayout r) =>
      r.scaleText(AppTextStyles.caption);

  static EdgeInsets _captionPadding(ResponsiveLayout r) => EdgeInsets.symmetric(
    horizontal: r.scaled(AppSpacing.sm),
    vertical: r.scaled(AppSpacing.xxs),
  );

  /// Card height for the current breakpoint and text scale. The caption
  /// always reserves two title lines, so cards in a row line up.
  static double heightFor(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final caption =
        _captionPadding(r).vertical +
        AppTextStyles.lineHeightOf(context, _titleStyle(r)) * _titleMaxLines +
        r.scaled(AppSpacing.xxxs) +
        AppTextStyles.lineHeightOf(context, _detailStyle(r));
    return (_border.dimensions.vertical + r.posterCardHeight + caption)
        .ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final radius = Radius.circular(r.scaled(AppRadius.lg));
    final width = r.posterCardWidth;

    return FocusableLiftCard(
      onTap: onTap,
      borderRadius: BorderRadius.all(radius),
      child: Container(
        width: width,
        height: heightFor(context),
        decoration: BoxDecoration(
          color: AppColors.glassSurfaceStrong,
          borderRadius: BorderRadius.all(radius),
          border: _border,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: radius),
              child: MediaImage(
                path: movie.posterPath,
                width: width,
                height: r.posterCardHeight,
                fallback: NoPosterPlaceholder(
                  width: width,
                  height: r.posterCardHeight,
                ),
              ),
            ),
            Padding(
              padding: _captionPadding(r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: r.scaled(AppSpacing.xxxs),
                children: [
                  Text(
                    movie.title,
                    maxLines: _titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: _titleStyle(r),
                  ),
                  _Details(movie: movie, style: _detailStyle(r)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.movie, required this.style});

  final TmdbMovie movie;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final rating = movie.voteAverage;
    final year = movie.releaseYear;

    return Row(
      spacing: AppSpacing.xs,
      children: [
        if (rating != null)
          RatingLabel(
            rating: rating,
            style: style.copyWith(color: AppColors.textPrimary),
          ),
        if (year != null)
          Flexible(
            child: Text('$year', overflow: TextOverflow.ellipsis, style: style),
          ),
      ],
    );
  }
}
