abstract final class AppRoutes {
  static const String home = '/home';
  static const String search = '/search';
  static const String player = '/player';
  static const String about = '/about';

  static const String detailPattern = '/detail/:id';
  static const String personPattern = '/person/:id';

  static String detail(int tmdbId) => '/detail/$tmdbId';

  static String person(int personId) => '/person/$personId';
}
