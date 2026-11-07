import 'package:dio/dio.dart';
import 'package:filmbuster/core/config/data_source_mode.dart';
import 'package:filmbuster/core/di/injector.dart';
import 'package:filmbuster/data/local/bundled_catalog.dart';
import 'package:filmbuster/data/local/demo_movie_repository.dart';
import 'package:filmbuster/data/local/demo_person_repository.dart';
import 'package:filmbuster/data/remote/tmdb_api_service.dart';
import 'package:filmbuster/data/repositories/movie_repository_impl.dart';
import 'package:filmbuster/data/repositories/movie_sources_repository_impl.dart';
import 'package:filmbuster/data/repositories/person_repository_impl.dart';
import 'package:filmbuster/domain/repositories/movie_repository.dart';
import 'package:filmbuster/domain/repositories/movie_sources_repository.dart';
import 'package:filmbuster/domain/repositories/open_movie_repository.dart';
import 'package:filmbuster/domain/repositories/person_repository.dart';
import 'package:filmbuster/presentation/features/player/services/playback_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(resetDependencies);

  test('without a mode or URL the app composes demo mode', () {
    configureDependencies();
    expect(getIt<DataSourceMode>(), DataSourceMode.demo);
  });

  test('demo wires the bundled catalogue and registers no Dio', () {
    configureDependencies(mode: DataSourceMode.demo);

    expect(getIt<DataSourceMode>(), DataSourceMode.demo);
    expect(getIt<MovieRepository>(), isA<DemoMovieRepository>());
    expect(getIt<PersonRepository>(), isA<DemoPersonRepository>());
    expect(getIt<OpenMovieRepository>(), isA<BundledCatalog>());
    expect(getIt<MovieSourcesRepository>(), same(getIt<OpenMovieRepository>()));
    expect(getIt.isRegistered<Dio>(), isFalse);
    expect(getIt.isRegistered<TmdbApiService>(), isFalse);
  });

  test('live wires the API with the given base URL', () {
    configureDependencies(
      mode: DataSourceMode.live,
      baseUrl: 'https://api.example.com',
    );

    expect(getIt<DataSourceMode>(), DataSourceMode.live);
    expect(getIt<Dio>().options.baseUrl, 'https://api.example.com');
    expect(getIt<MovieRepository>(), isA<MovieRepositoryImpl>());
    expect(getIt<PersonRepository>(), isA<PersonRepositoryImpl>());
    expect(getIt<MovieSourcesRepository>(), isA<MovieSourcesRepositoryImpl>());
    expect(getIt<OpenMovieRepository>(), isA<BundledCatalog>());
  });

  test('both modes register a playback engine for the player', () async {
    for (final mode in DataSourceMode.values) {
      configureDependencies(mode: mode, baseUrl: 'https://api.example.com');
      expect(getIt.isRegistered<PlaybackEngine>(), isTrue, reason: '$mode');
      await resetDependencies();
    }
  });

  test('live without a base URL is a configuration error', () {
    expect(
      () => configureDependencies(mode: DataSourceMode.live),
      throwsStateError,
    );
  });
}
