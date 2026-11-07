import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/router/back_navigation.dart';
import '../../../../core/utils/responsive.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/feedback/status_views.dart';
import '../../../widgets/movie_poster_reel.dart';
import '../bloc/person_cubit.dart';
import '../widgets/person_hero.dart';
import '../widgets/person_shimmer.dart';

class PersonLayout extends StatelessWidget {
  const PersonLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: DecoratedBox(
        decoration: AppGradients.screenBackgroundDecoration,
        child: SafeArea(
          child: BlocBuilder<PersonCubit, PersonState>(
            builder: (context, state) => Column(
              children: [
                AppHeader(
                  onBack: context.popOrGoHome,
                  title: state is PersonSuccess ? state.person.name : null,
                  // Smaller than a screen title, so that long names fit.
                  titleStyle: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: switch (state) {
                    PersonLoading() => const PersonShimmer(),
                    PersonFailure(:final message) => ErrorStateView(
                      message: message,
                      onRetry: context.read<PersonCubit>().load,
                      onBack: context.popOrGoHome,
                    ),
                    PersonSuccess() => _PersonBody(state: state),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonBody extends StatelessWidget {
  const _PersonBody({required this.state});

  final PersonSuccess state;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final sectionGap = SizedBox(height: r.scaled(AppSpacing.xxl));

    return ListView(
      padding: EdgeInsets.symmetric(vertical: r.scaled(AppSpacing.sm)),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding),
          child: PersonHero(person: state.person),
        ),
        sectionGap,
        MoviePosterReel(
          title: 'Movies',
          movies: state.movies,
          onMovieTap: (movie) => context.push(AppRoutes.detail(movie.id)),
        ),
        sectionGap,
      ],
    );
  }
}
