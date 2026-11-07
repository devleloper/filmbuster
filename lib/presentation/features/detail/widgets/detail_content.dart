import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/licenses/content_credits.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/external_url.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/tmdb_image_url.dart';
import '../../../../domain/models/tmdb_movie_details.dart';
import '../../../../domain/models/tmdb_trailer.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_icon_button.dart';
import '../../../widgets/info_chip.dart';
import '../../../widgets/movie_poster_reel.dart';
import '../../../widgets/rating_label.dart';
import '../../../widgets/text_link.dart';
import '../bloc/detail_cubit.dart';
import 'detail_cover.dart';
import 'persons_reel.dart';
import 'play_section.dart';

class DetailContent extends StatefulWidget {
  const DetailContent({
    super.key,
    required this.detail,
    required this.sources,
    required this.onBack,
    required this.onPlay,
    required this.onRetrySources,
  });

  static double coverHeightFor(ResponsiveBreakpoint breakpoint) =>
      switch (breakpoint) {
        ResponsiveBreakpoint.compact || ResponsiveBreakpoint.medium => 260,
        ResponsiveBreakpoint.large || ResponsiveBreakpoint.xlarge => 320,
      };

  final TmdbMovieDetails detail;
  final SourcesStatus sources;
  final VoidCallback onBack;
  final VoidCallback onPlay;
  final VoidCallback onRetrySources;

  @override
  State<DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends State<DetailContent> {
  /// The collapsed bar fades its title in as the cover title scrolls away.
  static const double _titleFadeStart = 100;
  static const double _titleFadeExtent = 100;

  final _scrollController = ScrollController();
  final _titleOpacity = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateTitleOpacity);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleOpacity.dispose();
    super.dispose();
  }

  void _updateTitleOpacity() {
    final progress =
        (_scrollController.offset - _titleFadeStart) / _titleFadeExtent;
    _titleOpacity.value = Curves.easeInOut.transform(progress.clamp(0, 1));
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final r = ResponsiveLayout.of(context);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverAppBar(
          expandedHeight: DetailContent.coverHeightFor(r.breakpoint),
          pinned: true,
          backgroundColor: AppColors.background,
          surfaceTintColor: AppColors.transparent,
          scrolledUnderElevation: 0,
          leading: AppIconButton(
            icon: Icons.arrow_back,
            onPressed: widget.onBack,
            semanticLabel: 'Back',
          ),
          title: ValueListenableBuilder(
            valueListenable: _titleOpacity,
            builder: (context, opacity, title) =>
                Opacity(opacity: opacity, child: title),
            child: Text(
              detail.title,
              style: r.scaleText(AppTextStyles.titleLarge),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: DetailCover(
              title: detail.title,
              posterPath: detail.posterPath,
              backdropPath: detail.backdropPath,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _DetailBody(
            detail: detail,
            sources: widget.sources,
            onPlay: widget.onPlay,
            onRetrySources: widget.onRetrySources,
          ),
        ),
      ],
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.detail,
    required this.sources,
    required this.onPlay,
    required this.onRetrySources,
  });

  final TmdbMovieDetails detail;
  final SourcesStatus sources;
  final VoidCallback onPlay;
  final VoidCallback onRetrySources;

  bool get _hasBundledImages =>
      TmdbImageUrl.isBundled(detail.posterPath) ||
      TmdbImageUrl.isBundled(detail.backdropPath);

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final gutter = EdgeInsets.symmetric(horizontal: r.horizontalPadding);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: gutter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.vGapMd,
              _MetaRow(detail: detail),
              AppSpacing.vGapSm,
              if (detail.genres.isNotEmpty) _GenreChips(genres: detail.genres),
              AppSpacing.vGapMd,
              PlaySection(
                title: detail.title,
                sources: sources,
                onPlay: onPlay,
                onRetry: onRetrySources,
              ),
              if (_hasBundledImages) const _DerivedImagesNote(),
              if (detail.trailers.isNotEmpty)
                _TrailerLink(
                  title: detail.title,
                  trailer: detail.trailers.first,
                ),
            ],
          ),
        ),
        AppSpacing.vGapMd,
        if (detail.cast.isNotEmpty || detail.crew.isNotEmpty) ...[
          PersonsReel(cast: detail.cast, crew: detail.crew),
          AppSpacing.vGapXl,
        ],
        Padding(
          padding: gutter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ResponsiveLayout.maxTextWidth,
            ),
            child: Text(
              detail.overview ?? 'No overview available',
              style: r
                  .scaleText(AppTextStyles.bodyMedium)
                  .copyWith(height: 1.5),
            ),
          ),
        ),
        AppSpacing.vGapXxl,
        if (detail.similar.isNotEmpty) ...[
          MoviePosterReel(
            title: 'You Might Like',
            movies: detail.similar,
            onMovieTap: (movie) => context.push(AppRoutes.detail(movie.id)),
          ),
          AppSpacing.vGapXxl,
        ],
      ],
    );
  }
}

class _DerivedImagesNote extends StatelessWidget {
  const _DerivedImagesNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        derivedImagesNote,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _TrailerLink extends StatelessWidget {
  const _TrailerLink({required this.title, required this.trailer});

  final String title;
  final TmdbTrailer trailer;

  @override
  Widget build(BuildContext context) {
    return TextLink(
      label: 'Trailer',
      icon: Icons.smart_display_rounded,
      onTap: ExternalUrl.onTapFor(trailer.url),
      // The visible word stays in the accessible name (WCAG 2.5.3).
      semanticLabel: '$title trailer',
      semanticHint: ExternalUrl.semanticHint,
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.detail});

  final TmdbMovieDetails detail;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final secondary = r.scaleText(AppTextStyles.bodyMedium);

    return Wrap(
      spacing: 10,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (detail.releaseYear case final year?)
          Text('$year', style: secondary),
        if (detail.voteAverage case final rating?)
          RatingLabel(
            rating: rating,
            style: r.scaleText(AppTextStyles.labelMedium),
          ),
        if (detail.runtime case final runtime?)
          Text('$runtime min', style: secondary),
      ],
    );
  }
}

class _GenreChips extends StatelessWidget {
  const _GenreChips({required this.genres});

  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [for (final genre in genres) InfoChip(genre)],
    );
  }
}
