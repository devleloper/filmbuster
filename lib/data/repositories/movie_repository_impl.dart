import '../../domain/models/tmdb_movie.dart';
import '../../domain/models/tmdb_movie_details.dart';
import '../../domain/repositories/movie_repository.dart';
import '../remote/tmdb_api_service.dart';

class MovieRepositoryImpl implements MovieRepository {
  const MovieRepositoryImpl(this._api);

  final TmdbApiService _api;

  @override
  Future<List<TmdbMovie>> getPopular() => _api.getPopular();

  @override
  Future<List<TmdbMovie>> getTopRated() => _api.getTopRated();

  @override
  Future<List<TmdbMovie>> getTrending() => _api.getTrending();

  @override
  Future<TmdbMovieDetails> getDetails(int tmdbId) =>
      _api.getMovieDetails(tmdbId);

  @override
  Future<List<TmdbMovie>> search(String query) => _api.searchMovies(query);
}
