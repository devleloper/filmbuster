import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/tmdb_genres.dart';
import '../../../../domain/models/tmdb_movie.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_icon_button.dart';
import '../../../widgets/focusable_lift_card.dart';
import '../../../widgets/media_image.dart';
import '../../../widgets/no_poster_placeholder.dart';
import '../../../widgets/rating_label.dart';

/// Large posters that advance on their own, unless the user reduces motion
/// or navigates with a screen reader.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    super.key,
    required this.movies,
    required this.onMovieTap,
  });

  static const slideInterval = Duration(seconds: 5); // design-literal: pace

  final List<TmdbMovie> movies;
  final ValueChanged<TmdbMovie> onMovieTap;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  static const double _posterAspectRatio = 2 / 3;
  static const double _slideGap = 24;

  static double _heightFor(ResponsiveBreakpoint breakpoint) =>
      switch (breakpoint) {
        ResponsiveBreakpoint.compact => 320,
        ResponsiveBreakpoint.medium => 380,
        ResponsiveBreakpoint.large => 440,
        ResponsiveBreakpoint.xlarge => 500,
      };

  // Only the indicator listens, so changing slides does not rebuild them.
  final _activeIndex = ValueNotifier<int>(0);
  bool _paused = false;

  @override
  void dispose() {
    _activeIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movies = widget.movies;
    if (movies.isEmpty) return const SizedBox.shrink();

    final r = ResponsiveLayout.of(context);
    final height = _heightFor(r.breakpoint);
    final width = height * _posterAspectRatio;
    final canAdvance =
        !AppMotion.reduced(context) &&
        !MediaQuery.accessibleNavigationOf(context);

    return Column(
      children: [
        // The rail below lists the same movies; a moving carousel is a poor
        // focus target.
        ExcludeFocus(
          child: LayoutBuilder(
            builder: (context, constraints) => CarouselSlider.builder(
              itemCount: movies.length,
              itemBuilder: (_, index, _) => _HeroCard(
                movie: movies[index],
                width: width,
                height: height,
                onTap: () => widget.onMovieTap(movies[index]),
              ),
              options: CarouselOptions(
                height: height,
                viewportFraction: ((width + _slideGap) / constraints.maxWidth)
                    .clamp(0.25, 1.0),
                enlargeCenterPage: true,
                enlargeFactor: 0.25,
                autoPlay: canAdvance && !_paused,
                autoPlayInterval: HeroCarousel.slideInterval,
                autoPlayCurve: Curves.fastOutSlowIn,
                onPageChanged: (index, _) => _activeIndex.value = index,
              ),
            ),
          ),
        ),
        AppSpacing.vGapMd,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder(
              valueListenable: _activeIndex,
              builder: (context, index, _) => AnimatedSmoothIndicator(
                activeIndex: index,
                count: movies.length,
                duration: AppMotion.of(context, AppDurations.medium),
                effect: const WormEffect(
                  activeDotColor: AppColors.primaryYellow,
                  dotColor: AppColors.textDisabled,
                  dotHeight: AppSpacing.sm,
                  dotWidth: AppSpacing.sm,
                  spacing: AppSpacing.sm,
                ),
              ),
            ),
            if (canAdvance) ...[
              AppSpacing.hGapSm,
              AppIconButton(
                icon: _paused ? Icons.play_arrow : Icons.pause,
                semanticLabel: _paused ? 'Play carousel' : 'Pause carousel',
                onPressed: () => setState(() => _paused = !_paused),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.movie,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final TmdbMovie movie;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final rating = movie.voteAverage;

    return FocusableLiftCard(
      onTap: onTap,
      borderRadius: AppRadius.xxlAll,
      child: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          borderRadius: AppRadius.xxlAll,
          boxShadow: [
            BoxShadow(
              color: AppColors.scrimSoft,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.xxlAll,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaImage(
                path: movie.posterPath,
                width: width,
                height: height,
                fallback: NoPosterPlaceholder(
                  width: width,
                  height: height,
                  fontSize: r.scaleFontSize(14),
                ),
              ),
              if (rating != null)
                Positioned(
                  left: AppSpacing.lg,
                  top: AppSpacing.md,
                  child: _RatingBadge(rating: rating),
                ),
              const _CaptionScrim(),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: _Caption(movie: movie),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.scaled(10),
        vertical: r.scaled(AppSpacing.xs),
      ),
      decoration: const BoxDecoration(
        color: AppColors.scrimMedium,
        borderRadius: AppRadius.mdAll,
      ),
      child: RatingLabel(
        rating: rating,
        style: r.scaleText(
          AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _CaptionScrim extends StatelessWidget {
  const _CaptionScrim();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 110,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.transparent,
                  AppColors.scrimSoft,
                  AppColors.scrimHeavy,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 75,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.transparent,
                      AppColors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.movie});

  final TmdbMovie movie;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final genres = genreIdsToNames(movie.genreIds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          movie.title,
          style: r.scaleText(AppTextStyles.titleLarge),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (genres.isNotEmpty) ...[
          SizedBox(height: r.scaled(AppSpacing.xxs)),
          Text(
            genres.join(' • '),
            style: r
                .scaleText(AppTextStyles.caption)
                .copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
