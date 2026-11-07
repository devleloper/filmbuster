import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_ready/app_ready_scope.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/tmdb_movie.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/header_logo_layout.dart';
import '../../../widgets/animations/staggered_entrance.dart';
import '../../../widgets/app_buttons.dart';
import '../../../widgets/app_icon_button.dart';
import '../../../widgets/app_logo.dart';
import '../../../widgets/attribution/demo_badge.dart';
import '../../../widgets/feedback/status_views.dart';
import '../../../widgets/movie_poster_reel.dart';
import '../bloc/home_cubit.dart';
import '../widgets/hero_carousel.dart';

enum HomeRefresh {
  /// Pull the list down; content stays on screen while it reloads.
  pull,

  /// A Reload button in the header, reachable by focus.
  button,
}

class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key, required this.refresh, this.isDemo = false});

  final HomeRefresh refresh;

  /// Shows the "Demo catalog" badge and names the rails after the bundled
  /// catalogue.
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: DecoratedBox(
        decoration: AppGradients.screenBackgroundDecoration,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: HeaderLogoLayout.top),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHeader(
                  isDemo: isDemo,
                  showReload: refresh == HomeRefresh.button,
                ),
                AppSpacing.vGapLg,
                Expanded(
                  child: BlocBuilder<HomeCubit, HomeState>(
                    builder: (context, state) => switch (state) {
                      HomeLoading() => const LoadingStateView(),
                      HomeFailure(:final message) => ErrorStateView(
                        message: message,
                        onRetry: context.read<HomeCubit>().load,
                      ),
                      HomeEmpty() => const _EmptyCatalogue(),
                      HomeSuccess() => _HomeContent(
                        state: state,
                        titles: isDemo ? _RailTitles.demo : _RailTitles.live,
                        pullToRefresh: refresh == HomeRefresh.pull,
                      ),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.isDemo, required this.showReload});

  final bool isDemo;
  final bool showReload;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding),
      // The badge wraps under the logo at large text sizes so the buttons keep
      // their width. Top alignment keeps the logo where the splash leaves it.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                const _HomeLogo(),
                if (isDemo)
                  const DemoBadge(
                    label: 'Demo catalog',
                    semanticLabel: 'Demo catalog: open movies only',
                  ),
              ],
            ),
          ),
          if (showReload)
            AppIconButton(
              icon: Icons.refresh_rounded,
              semanticLabel: 'Reload',
              onPressed: context.read<HomeCubit>().load,
            ),
          AppIconButton(
            icon: Icons.info_outline_rounded,
            semanticLabel: 'About and credits',
            onPressed: () => context.push(AppRoutes.about),
          ),
        ],
      ),
    );
  }
}

class _HomeLogo extends StatelessWidget {
  const _HomeLogo();

  @override
  Widget build(BuildContext context) {
    // Until the splash hands the logo over, an empty box of the same size
    // keeps the badge from jumping.
    if (!AppReadyScope.of(context).splashComplete) {
      return const SizedBox(
        width: HeaderLogoLayout.width,
        height: HeaderLogoLayout.height,
      );
    }
    return const AppLogo(
      width: HeaderLogoLayout.width,
      height: HeaderLogoLayout.height,
    );
  }
}

class _EmptyCatalogue extends StatelessWidget {
  const _EmptyCatalogue();

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.movie_filter_outlined,
      title: 'Nothing to show yet',
      description: 'The catalogue came back empty. Try again in a moment.',
      primary: PrimaryButton(
        onPressed: context.read<HomeCubit>().load,
        child: const Text('Reload'),
      ),
    );
  }
}

class _RailTitles {
  const _RailTitles(this.popular, this.topRated, this.trending);

  static const live = _RailTitles('Popular', 'Top Rated', 'Trending Today');

  /// The demo rails re-order one small catalogue, so they are not named
  /// after TMDB charts.
  static const demo = _RailTitles(
    'Open movies',
    'Blender Studio',
    'From the archive',
  );

  final String popular;
  final String topRated;
  final String trending;
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.state,
    required this.titles,
    required this.pullToRefresh,
  });

  final HomeSuccess state;
  final _RailTitles titles;
  final bool pullToRefresh;

  static const double _railGap = 18;

  @override
  Widget build(BuildContext context) {
    void openDetail(TmdbMovie movie) =>
        context.push(AppRoutes.detail(movie.id));
    final rails = [
      (titles.popular, state.popular),
      (titles.topRated, state.topRated),
      (titles.trending, state.trending),
    ];

    final content = ListView(
      // Lets a short list be pulled down too.
      physics: pullToRefresh ? const AlwaysScrollableScrollPhysics() : null,
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      children: [
        HeroCarousel(movies: state.trending, onMovieTap: openDetail),
        for (final (index, (title, movies)) in rails.indexed) ...[
          const SizedBox(height: _railGap),
          StaggeredEntrance(
            index: index,
            child: MoviePosterReel(
              title: title,
              movies: movies,
              staggered: true,
              onMovieTap: openDetail,
            ),
          ),
        ],
      ],
    );
    if (!pullToRefresh) return content;

    return RefreshIndicator(
      onRefresh: context.read<HomeCubit>().refresh,
      color: AppColors.white,
      backgroundColor: AppColors.borderStrong,
      child: content,
    );
  }
}
