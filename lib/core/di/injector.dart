import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../data/local/bundled_catalog.dart';
import '../../data/local/demo_movie_repository.dart';
import '../../data/local/demo_person_repository.dart';
import '../../data/remote/movie_sources_api_service.dart';
import '../../data/remote/tmdb_api_service.dart';
import '../../data/repositories/movie_repository_impl.dart';
import '../../data/repositories/movie_sources_repository_impl.dart';
import '../../data/repositories/person_repository_impl.dart';
import '../../domain/repositories/movie_repository.dart';
import '../../domain/repositories/movie_sources_repository.dart';
import '../../domain/repositories/open_movie_repository.dart';
import '../../domain/repositories/person_repository.dart';
import '../../presentation/features/player/services/media_kit_playback_engine.dart';
import '../../presentation/features/player/services/playback_engine.dart';
import '../config/app_config.dart';
import '../config/data_source_mode.dart';
import '../network/dio_factory.dart';

final GetIt getIt = GetIt.instance;

/// The only place that chooses between demo and live data. Demo mode
/// registers no [Dio], so it cannot send API requests.
void configureDependencies({
  DataSourceMode? mode,
  AssetBundle? bundle,
  String? baseUrl,
}) {
  final resolvedMode = mode ?? AppConfig.dataSource;
  final catalog = BundledCatalog((bundle ?? rootBundle).loadString);

  getIt
    ..registerSingleton<DataSourceMode>(resolvedMode)
    ..registerSingleton<OpenMovieRepository>(catalog)
    ..registerFactory<PlaybackEngine>(MediaKitPlaybackEngine.new);

  switch (resolvedMode) {
    case DataSourceMode.demo:
      getIt
        ..registerLazySingleton<MovieRepository>(
          () => DemoMovieRepository(catalog),
        )
        ..registerLazySingleton<PersonRepository>(
          () => DemoPersonRepository(catalog),
        )
        ..registerSingleton<MovieSourcesRepository>(catalog);
    case DataSourceMode.live:
      final url = baseUrl ?? AppConfig.baseUrl;
      if (url == null) {
        throw StateError('Live mode needs API_BASE_URL.');
      }
      getIt
        ..registerLazySingleton<Dio>(() => DioFactory.create(baseUrl: url))
        ..registerLazySingleton<TmdbApiService>(() => TmdbApiService(getIt()))
        ..registerLazySingleton<MovieSourcesApiService>(
          () => MovieSourcesApiService(getIt()),
        )
        ..registerLazySingleton<MovieRepository>(
          () => MovieRepositoryImpl(getIt()),
        )
        ..registerLazySingleton<PersonRepository>(
          () => PersonRepositoryImpl(getIt()),
        )
        ..registerLazySingleton<MovieSourcesRepository>(
          () => MovieSourcesRepositoryImpl(getIt()),
        );
  }
}

Future<void> resetDependencies() => getIt.reset();
