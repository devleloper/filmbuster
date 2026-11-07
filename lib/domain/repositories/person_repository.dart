import '../models/tmdb_movie.dart';
import '../models/tmdb_person_details.dart';

abstract interface class PersonRepository {
  Future<TmdbPersonDetails> getDetails(int personId);

  Future<List<TmdbMovie>> getMovies(int personId);
}
