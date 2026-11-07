import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/router/back_navigation.dart';
import '../../../../core/router/route_args.dart';
import '../../../../domain/models/tmdb_movie_details.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/feedback/status_views.dart';
import '../bloc/detail_cubit.dart';
import '../widgets/detail_content.dart';
import '../widgets/detail_shimmer.dart';

class DetailLayout extends StatelessWidget {
  const DetailLayout({super.key});

  static void _play(
    BuildContext context,
    TmdbMovieDetails detail,
    SourcesStatus sources,
  ) {
    if (sources case SourcesLoaded(:final first?, :final playable)) {
      context.push(
        AppRoutes.player,
        extra: PlayerRouteArgs(
          source: first.toPlayerSource(),
          sources: [for (final source in playable) source.toPlayerSource()],
          movieTitle: detail.title,
          artworkPath: detail.backdropPath ?? detail.posterPath,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FocusTraversalGroup(
        child: BlocBuilder<DetailCubit, DetailState>(
          builder: (context, state) => switch (state) {
            DetailLoading() => const _WithHeader(child: DetailShimmer()),
            DetailFailure(:final message) => _WithHeader(
              child: ErrorStateView(
                message: message,
                onRetry: context.read<DetailCubit>().load,
                onBack: context.popOrGoHome,
              ),
            ),
            DetailSuccess(:final detail, :final sources) => DetailContent(
              detail: detail,
              sources: sources,
              onBack: context.popOrGoHome,
              onPlay: () => _play(context, detail, sources),
              onRetrySources: context.read<DetailCubit>().retrySources,
            ),
          },
        ),
      ),
    );
  }
}

class _WithHeader extends StatelessWidget {
  const _WithHeader({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          AppHeader(onBack: context.popOrGoHome),
          Expanded(child: child),
        ],
      ),
    );
  }
}
