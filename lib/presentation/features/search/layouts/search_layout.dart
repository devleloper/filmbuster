import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/router/back_navigation.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/tmdb_movie.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/animations/staggered_entrance.dart';
import '../../../widgets/feedback/shimmer_placeholder.dart';
import '../../../widgets/feedback/status_views.dart';
import '../../../widgets/focusable_lift_card.dart';
import '../../../widgets/navigation/app_tab.dart';
import '../../../widgets/navigation/shell_focus_scope.dart';
import '../bloc/search_cubit.dart';
import '../widgets/search_bar.dart';
import '../widgets/search_result_card.dart';

/// Keeps the scaled-up focused card inside the list's clip.
const double _focusLiftPadding = 6;

class SearchLayout extends StatefulWidget {
  const SearchLayout({super.key});

  @override
  State<SearchLayout> createState() => _SearchLayoutState();
}

class _SearchLayoutState extends State<SearchLayout> {
  final _searchBarFocusNode = FocusNode();
  final _firstResultFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_searchBarFocusNode.context != null) {
        _searchBarFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchBarFocusNode.dispose();
    _firstResultFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ShellFocusScope.registerEntry(context, AppTab.search, _searchBarFocusNode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: ColoredBox(
        color: AppColors.backgroundDeep,
        child: SafeArea(
          bottom: false,
          child: FocusTraversalGroup(
            child: _EscapeReturnsToSearchBar(
              searchBarFocusNode: _searchBarFocusNode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SearchHeader(
                    searchBarFocusNode: _searchBarFocusNode,
                    firstResultFocusNode: _firstResultFocusNode,
                  ),
                  Expanded(
                    child: _SearchResults(
                      firstResultFocusNode: _firstResultFocusNode,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Escape or Back from the results returns to the search bar; from the
/// search bar it leaves Search for Home.
class _EscapeReturnsToSearchBar extends StatelessWidget {
  const _EscapeReturnsToSearchBar({
    required this.searchBarFocusNode,
    required this.child,
  });

  final FocusNode searchBarFocusNode;
  final Widget child;

  void _onEscape(BuildContext context) {
    if (searchBarFocusNode.hasPrimaryFocus) {
      context.popOrGoHome();
    } else {
      searchBarFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            _onEscape(context),
        const SingleActivator(LogicalKeyboardKey.goBack): () =>
            _onEscape(context),
      },
      child: child,
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.searchBarFocusNode,
    required this.firstResultFocusNode,
  });

  final FocusNode searchBarFocusNode;
  final FocusNode firstResultFocusNode;

  void _focusFirstResult() {
    if (firstResultFocusNode.context != null) {
      firstResultFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final gap = r.scaled(AppSpacing.md);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): _focusFirstResult,
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          r.horizontalPadding,
          gap,
          r.horizontalPadding,
          r.scaled(AppSpacing.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Search',
              style: r.scaleText(
                AppTextStyles.displayLarge.copyWith(
                  fontSize: 26, // design-literal: one-off heading size
                ),
              ),
            ),
            SizedBox(height: gap),
            AppSearchBar(
              focusNode: searchBarFocusNode,
              onSubmit: context.read<SearchCubit>().search,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.firstResultFocusNode});

  final FocusNode firstResultFocusNode;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding),
      child: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) => switch (state) {
          SearchInitial() => const _FindMoviesHint(),
          SearchLoading() => const _SearchShimmer(),
          SearchFailure(:final message) => ErrorStateView(
            message: message,
            onRetry: context.read<SearchCubit>().retry,
          ),
          SearchSuccess(:final results, :final query) when results.isEmpty =>
            EmptyStateView(
              icon: Icons.search_off_rounded,
              title: 'No results for “$query”',
              description: 'Check the spelling or try another title.',
            ),
          SearchSuccess(:final results) => _ResultsList(
            results: results,
            firstResultFocusNode: firstResultFocusNode,
          ),
        },
      ),
    );
  }
}

class _FindMoviesHint extends StatelessWidget {
  const _FindMoviesHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Find movies',
        style: AppTextStyles.base.copyWith(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ResultsList extends StatefulWidget {
  const _ResultsList({
    required this.results,
    required this.firstResultFocusNode,
  });

  final List<TmdbMovie> results;
  final FocusNode firstResultFocusNode;

  @override
  State<_ResultsList> createState() => _ResultsListState();
}

class _ResultsListState extends State<_ResultsList> {
  // Cards built after the first frame are scrolled into view rather than
  // arriving with the results, so they appear without an entrance.
  bool _firstFrameShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _firstFrameShown = true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final results = widget.results;

    return ListView.separated(
      padding: EdgeInsets.only(
        top: AppSpacing.lg + _focusLiftPadding,
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: results.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: r.scaled(AppSpacing.md)),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.all(_focusLiftPadding),
        child: StaggeredEntrance(
          index: index,
          enabled: !_firstFrameShown,
          child: _ResultCard(
            movie: results[index],
            focusNode: index == 0 ? widget.firstResultFocusNode : null,
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.movie, this.focusNode});

  final TmdbMovie movie;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return FocusableLiftCard(
      focusNode: focusNode,
      onTap: () => context.push(AppRoutes.detail(movie.id)),
      borderRadius: BorderRadius.circular(
        ResponsiveLayout.of(context).scaled(SearchResultCard.radius),
      ),
      child: SearchResultCard(movie: movie),
    );
  }
}

class _SearchShimmer extends StatelessWidget {
  const _SearchShimmer();

  static const int _rowCount = 4;

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final gap = r.scaled(AppSpacing.md);

    return ShimmerGroup(
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        itemCount: _rowCount,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(
                width: r.scaled(SearchResultCard.posterSize.width),
                height: r.scaled(SearchResultCard.posterSize.height),
                radius: r.scaled(AppRadius.md),
              ),
              SizedBox(width: gap),
              const Expanded(child: _ShimmerTextLines()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerTextLines extends StatelessWidget {
  const _ShimmerTextLines();

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveLayout.of(context);
    final gap = r.scaled(AppSpacing.sm);
    final titleBar = r.scaled(AppTextStyles.titleMedium.fontSize!);
    final detailBar = r.scaled(AppTextStyles.bodyMedium.fontSize!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(height: titleBar, width: double.infinity),
        SizedBox(height: gap),
        ShimmerBox(height: detailBar, width: r.scaled(80)),
        SizedBox(height: gap),
        ShimmerBox(height: detailBar, width: double.infinity),
      ],
    );
  }
}
