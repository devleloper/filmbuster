import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/domain/models/tmdb_movie.dart';
import 'package:filmbuster/presentation/features/search/bloc/search_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/mocks.dart';

void main() {
  late MockMovieRepository movies;

  setUp(() {
    movies = MockMovieRepository();
  });

  group('SearchCubit', () {
    blocTest<SearchCubit, SearchState>(
      'moves matching titles first and keeps the repository order',
      setUp: () {
        when(() => movies.search(any())).thenAnswer(
          (_) async => const [
            TmdbMovie(id: 1, title: 'Dune: Part Two'),
            TmdbMovie(id: 2, title: 'Arrival'),
            TmdbMovie(id: 3, title: 'Dune'),
          ],
        );
      },
      build: () => SearchCubit(movies),
      act: (cubit) => cubit.search('dune'),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchSuccess>().having(
          (s) => [for (final m in s.results) m.id],
          'order',
          [1, 3, 2],
        ),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'an exact but obscure title does not outrank the popular one',
      setUp: () {
        when(() => movies.search(any())).thenAnswer(
          (_) async => const [
            TmdbMovie(id: 603, title: 'The Matrix'),
            TmdbMovie(id: 604, title: 'The Matrix Reloaded'),
            TmdbMovie(id: 9, title: 'Matrix'),
          ],
        );
      },
      build: () => SearchCubit(movies),
      act: (cubit) => cubit.search('matrix'),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchSuccess>().having(
          (s) => s.results.first.title,
          'first',
          'The Matrix',
        ),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'trims the query before searching',
      setUp: () {
        when(() => movies.search(any())).thenAnswer((_) async => []);
      },
      build: () => SearchCubit(movies),
      act: (cubit) => cubit.search('  dune  '),
      verify: (_) => verify(() => movies.search('dune')).called(1),
    );

    blocTest<SearchCubit, SearchState>(
      'an empty query resets to initial without hitting the network',
      build: () => SearchCubit(movies),
      act: (cubit) => cubit.search('   '),
      expect: () => [isA<SearchInitial>()],
      verify: (_) => verifyNever(() => movies.search(any())),
    );

    blocTest<SearchCubit, SearchState>(
      'reports a typed failure with the query that failed',
      setUp: () {
        when(() => movies.search(any())).thenThrow(const TimeoutFailure());
      },
      build: () => SearchCubit(movies),
      act: (cubit) => cubit.search(' dune '),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchFailure>()
            .having((s) => s.failure, 'failure', isA<TimeoutFailure>())
            .having((s) => s.query, 'query', 'dune'),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'retry repeats the search that failed',
      setUp: () {
        when(
          () => movies.search('dune'),
        ).thenAnswer((_) async => const [TmdbMovie(id: 1, title: 'Dune')]);
      },
      build: () => SearchCubit(movies),
      seed: () => const SearchFailure(NetworkFailure(), query: 'dune'),
      act: (cubit) => cubit.retry(),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchSuccess>()
            .having((s) => s.query, 'query', 'dune')
            .having((s) => s.results.single.title, 'result', 'Dune'),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'retry does nothing unless a search failed',
      build: () => SearchCubit(movies),
      act: (cubit) => cubit.retry(),
      expect: () => const <SearchState>[],
      verify: (_) => verifyNever(() => movies.search(any())),
    );

    group('while an older search is still running', () {
      late Completer<List<TmdbMovie>> slow;

      setUp(() {
        when(() => movies.search('slow')).thenAnswer((_) => slow.future);
      });

      Future<void> searchSlowThenFast(SearchCubit cubit) async {
        // Created inside `act`: a future's error never reaches a listener in
        // another error zone, and blocTest runs `act` in its own.
        slow = Completer<List<TmdbMovie>>();
        unawaited(cubit.search('slow'));
        await cubit.search('fast');
      }

      blocTest<SearchCubit, SearchState>(
        'a slow first response never overwrites a newer one',
        setUp: () => when(
          () => movies.search('fast'),
        ).thenAnswer((_) async => const [TmdbMovie(id: 2, title: 'Fast')]),
        build: () => SearchCubit(movies),
        act: (cubit) async {
          await searchSlowThenFast(cubit);
          slow.complete(const [TmdbMovie(id: 1, title: 'Slow')]);
          await pumpEventQueue();
        },
        expect: () => [
          isA<SearchLoading>(),
          isA<SearchSuccess>().having(
            (s) => s.results.single.title,
            'result',
            'Fast',
          ),
        ],
      );

      blocTest<SearchCubit, SearchState>(
        'a stale failure never overwrites a newer success',
        setUp: () =>
            when(() => movies.search('fast')).thenAnswer((_) async => []),
        build: () => SearchCubit(movies),
        act: (cubit) async {
          await searchSlowThenFast(cubit);
          slow.completeError(const NetworkFailure());
          await pumpEventQueue();
        },
        expect: () => [isA<SearchLoading>(), isA<SearchSuccess>()],
      );
    });
  });
}
