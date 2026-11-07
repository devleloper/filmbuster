import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/back_navigation.dart';
import '../../../../core/utils/external_url.dart';
import '../../../../core/utils/responsive.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/app_logo.dart';
import '../../../widgets/attribution/app_license_page.dart';
import '../../../widgets/attribution/attribution_section.dart';
import '../../../widgets/attribution/tmdb_attribution.dart';
import '../../../widgets/feedback/status_views.dart';
import '../../../widgets/text_link.dart';
import '../bloc/about_cubit.dart';
import '../widgets/open_movie_credit.dart';

class AboutLayout extends StatelessWidget {
  const AboutLayout({super.key});

  static const String _appName = 'Filmbuster';
  static final Uri _tmdbHome = Uri.https('www.themoviedb.org', '/');

  static const double _logoWidth = 160;
  static const double _logoHeight = 30;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'About', onBack: context.popOrGoHome),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: r.horizontalPadding,
                  vertical: AppSpacing.lg,
                ),
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AppLogo(width: _logoWidth, height: _logoHeight),
                  ),
                  AppSpacing.vGapXl,
                  AttributionSection(
                    title: 'Data source',
                    children: [
                      TmdbAttribution(
                        // TMDB asks for its logo to be less prominent than the
                        // app's own.
                        logoHeight: _logoHeight / 2,
                        link: TextLink(
                          label: 'themoviedb.org',
                          onTap: ExternalUrl.onTapFor(_tmdbHome),
                          semanticLabel: 'The Movie Database website',
                          semanticHint: ExternalUrl.semanticHint,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapXl,
                  const _OpenMoviesSection(),
                  AppSpacing.vGapXl,
                  AttributionSection(
                    title: 'Licenses',
                    children: [
                      TextLink(
                        label: 'Open-source licenses',
                        icon: Icons.chevron_right_rounded,
                        onTap: () => showAppLicensePage(
                          context,
                          applicationName: _appName,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenMoviesSection extends StatelessWidget {
  const _OpenMoviesSection();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AboutCubit>().state;
    return AttributionSection(
      title: 'Open movies',
      description:
          'Films by Blender Foundation, played from their public releases.',
      children: switch (state) {
        AboutLoading() => const [LoadingStateView()],
        AboutFailure(:final message) => [
          ErrorStateView(
            message: message,
            onRetry: context.read<AboutCubit>().load,
          ),
        ],
        AboutSuccess(:final movies) => [
          for (final movie in movies) OpenMovieCredit(movie: movie),
        ],
      },
    );
  }
}
