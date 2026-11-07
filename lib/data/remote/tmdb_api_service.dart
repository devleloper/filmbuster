import 'package:dio/dio.dart';

import '../../core/error/app_failure.dart';
import '../../domain/models/json_parsing.dart';
import '../../domain/models/tmdb_movie.dart';
import '../../domain/models/tmdb_movie_details.dart';
import '../../domain/models/tmdb_person_details.dart';
import 'api_guard.dart';

/// TMDB metadata, read through the backend proxy.
class TmdbApiService {
  TmdbApiService(this._dio);

  final Dio _dio;

  Future<List<TmdbMovie>> searchMovies(String query) => _get(
    '/api/v1/tmdb/search',
    queryParameters: {'q': query},
    decode: _movies,
    fallbackMessage: 'Search failed. Please try again.',
  );

  Future<TmdbMovieDetails> getMovieDetails(int tmdbId) => _get(
    '/api/v1/tmdb/movie/$tmdbId',
    decode: (data) => TmdbMovieDetails.fromJson(parseJsonObject(data)),
    notFoundMessage: NotFoundFailure.movieMessage,
    fallbackMessage: 'Could not load movie details.',
  );

  Future<TmdbPersonDetails> getPersonDetails(int personId) => _get(
    '/api/v1/tmdb/person/$personId',
    decode: (data) => TmdbPersonDetails.fromJson(parseJsonObject(data)),
    notFoundMessage: NotFoundFailure.personMessage,
    fallbackMessage: 'Could not load person details.',
  );

  Future<List<TmdbMovie>> getPersonMovies(int personId) => _get(
    '/api/v1/tmdb/person/$personId/movies',
    decode: _movies,
    notFoundMessage: NotFoundFailure.personMessage,
    fallbackMessage: 'Could not load filmography.',
  );

  Future<List<TmdbMovie>> getPopular() =>
      _getMovieList('/api/v1/tmdb/discover/popular');

  Future<List<TmdbMovie>> getTopRated() =>
      _getMovieList('/api/v1/tmdb/discover/top-rated');

  Future<List<TmdbMovie>> getTrending() =>
      _getMovieList('/api/v1/tmdb/trending/day');

  Future<List<TmdbMovie>> _getMovieList(String path) =>
      _get(path, decode: _movies, fallbackMessage: 'Could not load movies.');

  Future<T> _get<T>(
    String path, {
    required T Function(Object? data) decode,
    required String fallbackMessage,
    Map<String, dynamic>? queryParameters,
    String? notFoundMessage,
  }) {
    return guardApiCall(
      () async {
        final response = await _dio.get<dynamic>(
          path,
          queryParameters: queryParameters,
        );
        return decode(response.data);
      },
      statusMessages: {404: ?notFoundMessage},
      fallbackMessage: fallbackMessage,
    );
  }

  static List<TmdbMovie> _movies(Object? data) =>
      parseJsonList(parseJsonObject(data)['results'], TmdbMovie.fromJson);
}
