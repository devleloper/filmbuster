import '../models/tmdb_movie.dart';
import '../models/tmdb_movie_details.dart';

abstract interface class MovieRepository {
  Future<List<TmdbMovie>> getPopular();

  Future<List<TmdbMovie>> getTopRated();

  Future<List<TmdbMovie>> getTrending();

  Future<TmdbMovieDetails> getDetails(int tmdbId);

  Future<List<TmdbMovie>> search(String query);
}
