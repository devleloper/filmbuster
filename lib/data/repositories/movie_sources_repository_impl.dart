import '../../domain/models/movie_source.dart';
import '../../domain/repositories/movie_sources_repository.dart';
import '../remote/movie_sources_api_service.dart';

class MovieSourcesRepositoryImpl implements MovieSourcesRepository {
  const MovieSourcesRepositoryImpl(this._api);

  final MovieSourcesApiService _api;

  @override
  Future<MovieSourceList> getSources(int tmdbId) => _api.getSources(tmdbId);
}
