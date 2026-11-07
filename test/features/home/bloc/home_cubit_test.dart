import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/domain/models/tmdb_movie.dart';
import 'package:filmbuster/presentation/features/home/bloc/home_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/mocks.dart';

void main() {
  late MockMovieRepository movies;

  setUp(() {
    movies = MockMovieRepository();
  });

  void stubAll() {
    when(movies.getPopular).thenAnswer((_) async => [Fixtures.movie]);
    when(movies.getTopRated).thenAnswer((_) async => [Fixtures.otherMovie]);
    when(
      movies.getTrending,
    ).thenAnswer((_) async => [Fixtures.movie, Fixtures.otherMovie]);
  }

  group('HomeCubit', () {
    test('starts in the loading state', () {
      expect(HomeCubit(movies).state, isA<HomeLoading>());
    });

    blocTest<HomeCubit, HomeState>(
      'emits loading then success with all three catalogues',
      setUp: stubAll,
      build: () => HomeCubit(movies),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeSuccess>()
            .having((s) => s.popular, 'popular', [Fixtures.movie])
            .having((s) => s.topRated, 'topRated', [Fixtures.otherMovie])
            .having((s) => s.trending.length, 'trending', 2),
      ],
    );

    test('requests the three catalogues concurrently', () async {
      final popular = Completer<List<TmdbMovie>>();
      movies.stubCatalogues(const []);
      when(movies.getPopular).thenAnswer((_) => popular.future);
      final cubit = HomeCubit(movies);
      addTearDown(cubit.close);

      final loading = cubit.load();
      await pumpEventQueue();

      verify(movies.getTopRated).called(1);
      verify(movies.getTrending).called(1);
      popular.complete([]);
      await loading;
    });

    blocTest<HomeCubit, HomeState>(
      'surfaces a typed failure with a user-facing message',
      setUp: () {
        movies.stubCatalogues(const []);
        when(movies.getPopular).thenThrow(const NetworkFailure());
      },
      build: () => HomeCubit(movies),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeFailure>()
            .having((s) => s.failure, 'failure', isA<NetworkFailure>())
            .having(
              (s) => s.message.toLowerCase(),
              'message',
              isNot(contains('exception')),
            ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'wraps an untyped error instead of leaking it',
      setUp: () {
        movies.stubCatalogues(const []);
        when(movies.getPopular).thenThrow(StateError('boom'));
      },
      build: () => HomeCubit(movies),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeFailure>().having(
          (s) => s.failure,
          'failure',
          isA<UnknownFailure>(),
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'an empty catalogue is reported as empty, not as an empty page',
      setUp: () {
        movies.stubCatalogues(const []);
      },
      build: () => HomeCubit(movies),
      act: (cubit) => cubit.load(),
      expect: () => [isA<HomeLoading>(), isA<HomeEmpty>()],
    );

    blocTest<HomeCubit, HomeState>(
      'refreshing keeps the current content until the new one arrives',
      setUp: stubAll,
      build: () => HomeCubit(movies),
      seed: () => const HomeSuccess(popular: [], topRated: [], trending: []),
      act: (cubit) => cubit.refresh(),
      expect: () => [
        isA<HomeSuccess>().having((s) => s.trending.length, 'trending', 2),
      ],
    );

    test(
      'a late failure of an older refresh keeps the newer catalogue',
      () async {
        final first = Completer<List<TmdbMovie>>();
        final second = Completer<List<TmdbMovie>>();
        movies.stubCatalogues(const []);
        final answers = [first.future, second.future];
        when(movies.getPopular).thenAnswer((_) => answers.removeAt(0));
        final cubit = HomeCubit(movies);
        addTearDown(cubit.close);

        final older = cubit.refresh();
        final newer = cubit.refresh();
        second.complete([Fixtures.movie]);
        await newer;
        first.completeError(const NetworkFailure());
        await older;

        expect(
          cubit.state,
          isA<HomeSuccess>().having((s) => s.popular, 'popular', [
            Fixtures.movie,
          ]),
        );
      },
    );

    test('does not emit after close', () async {
      final popular = Completer<List<TmdbMovie>>();
      movies.stubCatalogues(const []);
      when(movies.getPopular).thenAnswer((_) => popular.future);
      final cubit = HomeCubit(movies);

      final loading = cubit.load();
      await cubit.close();
      popular.complete([Fixtures.movie]);
      await loading;

      expect(cubit.state, isA<HomeLoading>());
    });
  });
}
