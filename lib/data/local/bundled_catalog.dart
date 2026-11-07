import '../../core/error/app_failure.dart';
import '../../domain/models/movie_source.dart';
import '../../domain/models/open_movie.dart';
import '../../domain/repositories/movie_sources_repository.dart';
import '../../domain/repositories/open_movie_repository.dart';
import 'catalog_contents.dart';

typedef AssetStringLoader = Future<String> Function(String key);

/// The open-movie catalogue that ships with the app; it never touches the
/// network.
class BundledCatalog implements OpenMovieRepository, MovieSourcesRepository {
  BundledCatalog(this._loadString);

  static const String assetKey = 'assets/demo/catalog.json';

  final AssetStringLoader _loadString;

  Future<CatalogContents>? _catalog;

  /// Cached after the first successful read. Throws [ParsingFailure] for a
  /// damaged file and [UnknownFailure] when the asset cannot be read.
  Future<CatalogContents> load() async {
    try {
      return await (_catalog ??= _read());
    } catch (_) {
      _catalog = null;
      rethrow;
    }
  }

  Future<CatalogContents> _read() async {
    final String raw;
    try {
      raw = await _loadString(assetKey);
    } catch (error, stackTrace) {
      throw UnknownFailure(
        message: 'The bundled catalogue could not be loaded.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    try {
      return CatalogContents.parse(raw);
    } catch (error, stackTrace) {
      throw ParsingFailure(
        message: 'The bundled catalogue is damaged.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<OpenMovie>> getAll() async {
    final catalog = await load();
    return [for (final id in catalog.order) catalog.openMovies[id]!];
  }

  @override
  Future<OpenMovie?> findByTmdbId(int tmdbId) async =>
      (await load()).openMovies[tmdbId];

  @override
  Future<MovieSourceList> getSources(int tmdbId) async {
    final catalog = await load();
    return MovieSourceList(results: catalog.sources[tmdbId] ?? const []);
  }
}
