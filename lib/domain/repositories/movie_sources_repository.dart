import '../models/movie_source.dart';

abstract interface class MovieSourcesRepository {
  Future<MovieSourceList> getSources(int tmdbId);
}
