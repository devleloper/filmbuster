/// Image widths the TMDB image server serves, named as in its URLs.
enum TmdbImageSize {
  w185(185),
  w342(342),
  w500(500),
  w780(780);

  const TmdbImageSize(this.width);

  final int width;
}

abstract final class TmdbImageUrl {
  static const String _base = 'https://image.tmdb.org/t/p';

  // w500 is the largest poster the app asks for: bigger files cost far more
  // bandwidth than they add detail at the sizes posters are shown.
  static const List<TmdbImageSize> _posterSizes = [
    TmdbImageSize.w185,
    TmdbImageSize.w342,
    TmdbImageSize.w500,
  ];

  /// Marks a bundled image: `asset:assets/demo/images/sintel-poster.webp`.
  static const String bundledPrefix = 'asset:';

  static bool isBundled(String? path) =>
      path != null && path.startsWith(bundledPrefix);

  /// The asset key of a bundled [path], or `null` for any other path.
  static String? bundledAsset(String? path) =>
      isBundled(path) ? path!.substring(bundledPrefix.length) : null;

  /// The image server URL for a TMDB [path], or `null` for a missing or
  /// bundled one; render bundled paths with [bundledAsset].
  static String? build(String? path, {required TmdbImageSize size}) {
    if (path == null || path.isEmpty || isBundled(path)) return null;
    return '$_base/${size.name}$path';
  }

  /// The smallest poster size at least [pixelWidth] wide, or the largest
  /// one the app requests.
  static TmdbImageSize posterSizeFor(int pixelWidth) => _posterSizes.firstWhere(
    (size) => size.width >= pixelWidth,
    orElse: () => _posterSizes.last,
  );

  static String? backdrop(String? path) =>
      build(path, size: TmdbImageSize.w780);
}
