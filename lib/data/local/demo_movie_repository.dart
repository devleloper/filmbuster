import '../../core/error/app_failure.dart';
import '../../core/utils/text_similarity.dart';
import '../../domain/models/tmdb_movie.dart';
import '../../domain/models/tmdb_movie_details.dart';
import '../../domain/repositories/movie_repository.dart';
import 'bundled_catalog.dart';

/// Rails are deterministic orderings of the same bundled titles: popular is
/// the curated order, top rated is newest first, trending is oldest first.
class DemoMovieRepository implements MovieRepository {
  const DemoMovieRepository(this._catalog);

  static const int _fuzzyMatchThreshold = 60;

  final BundledCatalog _catalog;

  @override
  Future<List<TmdbMovie>> getPopular() => _summaries();

  @override
  Future<List<TmdbMovie>> getTopRated() => _byYear(newestFirst: true);

  @override
  Future<List<TmdbMovie>> getTrending() => _byYear(newestFirst: false);

  /// Every other catalogue title counts as similar; there are no trailers,
  /// since demo mode works offline without TMDB videos.
  @override
  Future<TmdbMovieDetails> getDetails(int tmdbId) async {
    final details = (await _catalog.load()).movies[tmdbId];
    if (details == null) {
      throw const NotFoundFailure(message: NotFoundFailure.movieMessage);
    }
    final similar = await _summaries();
    return details.copyWith(
      similar: [
        for (final movie in similar)
          if (movie.id != tmdbId) movie,
      ],
      trailers: const [],
    );
  }

  /// Unranked: the caller orders the results.
  @override
  Future<List<TmdbMovie>> search(String query) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    final movies = await _summaries();
    return [
      for (final movie in movies)
        if (_matchesTitle(movie.title, needle)) movie,
    ];
  }

  static bool _matchesTitle(String title, String needle) =>
      title.toLowerCase().contains(needle) ||
      tokenSortSimilarity(needle, title) >= _fuzzyMatchThreshold;

  Future<List<TmdbMovie>> _byYear({required bool newestFirst}) async {
    final movies = await _summaries();
    return movies..sort((a, b) {
      final byYear = (a.releaseYear ?? 0).compareTo(b.releaseYear ?? 0);
      final ordered = newestFirst ? -byYear : byYear;
      return ordered != 0 ? ordered : a.title.compareTo(b.title);
    });
  }

  Future<List<TmdbMovie>> _summaries() async {
    final catalog = await _catalog.load();
    return [for (final movie in catalog.ordered) movie.toSummary()];
  }
}
