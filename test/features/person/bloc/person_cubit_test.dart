import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/domain/models/tmdb_person_details.dart';
import 'package:filmbuster/presentation/features/person/bloc/person_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/mocks.dart';

void main() {
  late MockPersonRepository people;

  setUp(() {
    people = MockPersonRepository();
  });

  group('PersonCubit', () {
    blocTest<PersonCubit, PersonState>(
      'emits loading then person + filmography',
      setUp: () {
        when(
          () => people.getDetails(10),
        ).thenAnswer((_) async => Fixtures.person);
        when(
          () => people.getMovies(10),
        ).thenAnswer((_) async => [Fixtures.movie]);
      },
      build: () => PersonCubit(people, 10),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<PersonLoading>(),
        isA<PersonSuccess>()
            .having((s) => s.person.name, 'name', 'Denis Villeneuve')
            .having((s) => s.movies, 'movies', [Fixtures.movie]),
      ],
    );

    blocTest<PersonCubit, PersonState>(
      'a failure in either request fails the whole screen',
      setUp: () {
        when(
          () => people.getDetails(10),
        ).thenAnswer((_) async => Fixtures.person);
        when(() => people.getMovies(10)).thenThrow(const ServerFailure());
      },
      build: () => PersonCubit(people, 10),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<PersonLoading>(),
        isA<PersonFailure>().having(
          (s) => s.failure,
          'failure',
          isA<ServerFailure>(),
        ),
      ],
    );

    test('requests details and filmography concurrently', () async {
      final details = Completer<TmdbPersonDetails>();
      when(() => people.getDetails(10)).thenAnswer((_) => details.future);
      when(() => people.getMovies(10)).thenAnswer((_) async => []);
      final cubit = PersonCubit(people, 10);
      addTearDown(cubit.close);

      final loading = cubit.load();
      await pumpEventQueue();

      verify(() => people.getMovies(10)).called(1);
      details.complete(Fixtures.person);
      await loading;
    });

    blocTest<PersonCubit, PersonState>(
      'loading again requests the same person',
      setUp: () {
        when(
          () => people.getDetails(10),
        ).thenAnswer((_) async => Fixtures.person);
        when(() => people.getMovies(10)).thenAnswer((_) async => []);
      },
      build: () => PersonCubit(people, 10),
      act: (cubit) async {
        await cubit.load();
        await cubit.load();
      },
      skip: 2,
      expect: () => [isA<PersonLoading>(), isA<PersonSuccess>()],
      verify: (_) => verify(() => people.getDetails(10)).called(2),
    );
  });
}
