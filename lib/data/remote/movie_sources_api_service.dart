import 'package:dio/dio.dart';

import '../../domain/models/json_parsing.dart';
import '../../domain/models/movie_source.dart';
import 'api_guard.dart';

class MovieSourcesApiService {
  MovieSourcesApiService(this._dio);

  final Dio _dio;

  Future<MovieSourceList> getSources(int tmdbId) {
    return guardApiCall(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/movies/$tmdbId/sources',
      );
      return MovieSourceList.fromJson(parseJsonObject(response.data));
    }, fallbackMessage: 'Playback sources are unavailable. Please try again.');
  }
}
