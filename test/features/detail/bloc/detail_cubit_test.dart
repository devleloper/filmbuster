import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/domain/models/movie_source.dart';
import 'package:filmbuster/domain/models/tmdb_movie_details.dart';
import 'package:filmbuster/presentation/features/detail/bloc/detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/mocks.dart';

void main() {
  late MockMovieRepository movies;
  late MockMovieSourcesRepository sources;

  final mp4 = Fixtures.source();
  final mkv = Fixtures.source(
    id: 'openmovies.dune-1080p',
    mimeType: 'video/x-matroska',
    codecs: null,
  );

  setUp(() {
    movies = MockMovieRepository();
    sources = MockMovieSourcesRepository();
    when(
      () => movies.getDetails(1),
    ).thenAnswer((_) async => Fixtures.movieDetails);
  });

  DetailCubit build({int id = 1, bool Function(MovieSource)? isPlayable}) =>
      DetailCubit(movies, sources, id, isPlayable: isPlayable);

  const detailsWithSourcesLoading = DetailSuccess(Fixtures.movieDetails);

  SourcesLoaded loadedSources(DetailCubit cubit) =>
      (cubit.state as DetailSuccess).sources as SourcesLoaded;

  group('DetailCubit', () {
    blocTest<DetailCubit, DetailState>(
      'emits details, then the loaded sources',
      setUp: () => when(
        () => sources.getSources(1),
      ).thenAnswer((_) async => MovieSourceList(results: [mp4])),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const DetailLoading(),
        detailsWithSourcesLoading,
        DetailSuccess(
          Fixtures.movieDetails,
          sources: SourcesLoaded(playable: [mp4]),
        ),
      ],
    );

    blocTest<DetailCubit, DetailState>(
      'loading again requests the same movie',
      setUp: () => when(
        () => sources.getSources(1),
      ).thenAnswer((_) async => MovieSourceList(results: [mp4])),
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.load();
      },
      skip: 3,
      expect: () => [
        const DetailLoading(),
        detailsWithSourcesLoading,
        DetailSuccess(
          Fixtures.movieDetails,
          sources: SourcesLoaded(playable: [mp4]),
        ),
      ],
      verify: (_) => verify(() => movies.getDetails(1)).called(2),
    );

    test('loads details and sources concurrently', () async {
      final details = Completer<TmdbMovieDetails>();
      when(() => movies.getDetails(1)).thenAnswer((_) => details.future);
      when(
        () => sources.getSources(1),
      ).thenAnswer((_) async => const MovieSourceList());
      final cubit = build();
      addTearDown(cubit.close);

      final loading = cubit.load();
      await pumpEventQueue();

      verify(() => sources.getSources(1)).called(1);
      details.complete(Fixtures.movieDetails);
      await loading;
    });

    blocTest<DetailCubit, DetailState>(
      'an empty list offers neither Play nor Retry',
      setUp: () => when(
        () => sources.getSources(1),
      ).thenAnswer((_) async => const MovieSourceList()),
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        final status = loadedSources(cubit);
        expect(status.first, isNull);
        expect(status.canRetry, isFalse);
      },
    );

    blocTest<DetailCubit, DetailState>(
      'a partial empty answer can be retried',
      setUp: () => when(
        () => sources.getSources(1),
      ).thenAnswer((_) async => const MovieSourceList(partial: true)),
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        final status = loadedSources(cubit);
        expect(status.partial, isTrue);
        expect(status.canRetry, isTrue);
      },
    );

    blocTest<DetailCubit, DetailState>(
      'a partial answer with sources still offers Play',
      setUp: () => when(
        () => sources.getSources(1),
      ).thenAnswer((_) async => MovieSourceList(results: [mp4], partial: true)),
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        final status = loadedSources(cubit);
        expect(status.first, mp4);
        expect(status.canRetry, isFalse);
      },
    );

    blocTest<DetailCubit, DetailState>(
      'the platform filter drops unplayable sources',
      setUp: () => when(
        () => sources.getSources(1),
      ).thenAnswer((_) async => MovieSourceList(results: [mkv, mp4])),
      build: () => build(isPlayable: (s) => s.mimeType == 'video/mp4'),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        final status = loadedSources(cubit);
        expect(status.playable, [mp4]);
      },
    );

    const failure = ServerFailure(message: 'Sources down');

    blocTest<DetailCubit, DetailState>(
      'a sources failure never fails Detail, and retry recovers',
      setUp: () {
        var calls = 0;
        when(() => sources.getSources(1)).thenAnswer((_) async {
          if (calls++ == 0) throw failure;
          return MovieSourceList(results: [mp4]);
        });
      },
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.retrySources();
      },
      expect: () => [
        const DetailLoading(),
        detailsWithSourcesLoading,
        const DetailSuccess(
          Fixtures.movieDetails,
          sources: SourcesFailed(failure),
        ),
        detailsWithSourcesLoading,
        DetailSuccess(
          Fixtures.movieDetails,
          sources: SourcesLoaded(playable: [mp4]),
        ),
      ],
    );

    blocTest<DetailCubit, DetailState>(
      'retrySources does nothing before details are loaded',
      build: build,
      act: (cubit) => cubit.retrySources(),
      expect: () => const <DetailState>[],
      verify: (_) => verifyNever(() => sources.getSources(any())),
    );

    blocTest<DetailCubit, DetailState>(
      'maps a missing movie to a not-found failure',
      setUp: () {
        when(() => movies.getDetails(404)).thenThrow(const NotFoundFailure());
        when(
          () => sources.getSources(404),
        ).thenAnswer((_) async => const MovieSourceList());
      },
      build: () => build(id: 404),
      act: (cubit) => cubit.load(),
      expect: () => [
        const DetailLoading(),
        isA<DetailFailure>().having(
          (s) => s.failure,
          'failure',
          isA<NotFoundFailure>(),
        ),
      ],
    );

    test('does not emit sources after close', () async {
      final gate = Completer<MovieSourceList>();
      when(() => sources.getSources(1)).thenAnswer((_) => gate.future);
      final cubit = build();
      final loading = cubit.load();
      await pumpEventQueue();
      await cubit.close();
      gate.complete(MovieSourceList(results: [mp4]));
      await loading;
      expect(cubit.state, detailsWithSourcesLoading);
    });

    test('a reload drops the sources answer of the previous load', () async {
      final first = Completer<MovieSourceList>();
      var calls = 0;
      when(() => sources.getSources(1)).thenAnswer(
        (_) => calls++ == 0
            ? first.future
            : Future.value(const MovieSourceList(partial: true)),
      );
      final cubit = build();
      final stale = cubit.load();
      await pumpEventQueue();
      await cubit.load();
      first.complete(MovieSourceList(results: [mp4]));
      await stale;
      expect(
        cubit.state,
        const DetailSuccess(
          Fixtures.movieDetails,
          sources: SourcesLoaded(partial: true),
        ),
      );
      await cubit.close();
    });
  });
}
