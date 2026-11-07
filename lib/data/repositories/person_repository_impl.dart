import '../../domain/models/tmdb_movie.dart';
import '../../domain/models/tmdb_person_details.dart';
import '../../domain/repositories/person_repository.dart';
import '../remote/tmdb_api_service.dart';

class PersonRepositoryImpl implements PersonRepository {
  const PersonRepositoryImpl(this._api);

  final TmdbApiService _api;

  @override
  Future<TmdbPersonDetails> getDetails(int personId) =>
      _api.getPersonDetails(personId);

  @override
  Future<List<TmdbMovie>> getMovies(int personId) =>
      _api.getPersonMovies(personId);
}
