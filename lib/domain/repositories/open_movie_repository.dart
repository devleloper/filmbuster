import '../models/open_movie.dart';

abstract interface class OpenMovieRepository {
  Future<List<OpenMovie>> getAll();

  Future<OpenMovie?> findByTmdbId(int tmdbId);
}
