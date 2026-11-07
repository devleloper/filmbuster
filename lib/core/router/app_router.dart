import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/features/about/view/about_screen.dart';
import '../../presentation/features/detail/view/detail_screen.dart';
import '../../presentation/features/home/view/home_screen.dart';
import '../../presentation/features/person/view/person_screen.dart';
import '../../presentation/features/player/view/player_screen.dart';
import '../../presentation/features/search/view/search_screen.dart';
import '../../presentation/screens/main_screen.dart';
import '../../presentation/widgets/navigation/animated_shell_content.dart';
import '../../presentation/widgets/navigation/app_tab.dart';
import 'app_routes.dart';
import 'route_args.dart';

GoRouter buildRouter() {
  // Screens outside the tabs name the root navigator as their parent;
  // otherwise go_router pushes them into the current tab's navigator, under
  // the tab bar.
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            MainScreen(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            AnimatedShellContent(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        branches: [
          for (final tab in AppTab.values)
            StatefulShellBranch(routes: [_tabRoute(tab)]),
        ],
      ),
      GoRoute(
        path: AppRoutes.detailPattern,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => DetailScreen(id: _idOf(state)),
      ),
      GoRoute(
        path: AppRoutes.personPattern,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PersonScreen(id: _idOf(state)),
      ),
      GoRoute(
        path: AppRoutes.about,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.player,
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) =>
            state.extra is PlayerRouteArgs ? null : AppRoutes.home,
        builder: (context, state) =>
            PlayerScreen(args: state.extra as PlayerRouteArgs),
      ),
    ],
  );
}

GoRoute _tabRoute(AppTab tab) => switch (tab) {
  AppTab.home => GoRoute(
    path: AppRoutes.home,
    builder: (context, state) => const HomeScreen(),
  ),
  AppTab.search => GoRoute(
    path: AppRoutes.search,
    builder: (context, state) => const SearchScreen(),
  ),
};

/// A malformed id becomes 0, which matches no movie or person, so the
/// screen shows its error state.
int _idOf(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
