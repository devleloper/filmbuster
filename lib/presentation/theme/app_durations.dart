abstract final class AppDurations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  /// Delay between consecutive items of a staggered entrance.
  static const Duration stagger = Duration(milliseconds: 50);

  /// One revolution of the loading spinner.
  static const Duration spinner = Duration(milliseconds: 1100);

  /// How long an error message stays on screen.
  static const Duration errorMessage = Duration(seconds: 4);
}
