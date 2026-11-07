import 'package:bloc_test/bloc_test.dart';
import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/domain/models/content_license.dart';
import 'package:filmbuster/domain/models/open_movie.dart';
import 'package:filmbuster/presentation/features/about/bloc/about_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/mocks.dart';

void main() {
  late MockOpenMovieRepository repository;

  final sintel = OpenMovie(
    tmdbId: 45745,
    title: 'Sintel',
    year: 2010,
    directedBy: 'Colin Levy',
    attribution: '(c) copyright 2010 Blender Foundation | durian.blender.org',
    license: const ContentLicense(spdxId: 'CC-BY-3.0', name: 'CC BY 3.0'),
    sourceUrl: Uri.parse('https://durian.blender.org/about/'),
  );
  const failure = ParsingFailure(message: 'The bundled catalogue is damaged.');

  setUp(() => repository = MockOpenMovieRepository());

  group('AboutCubit', () {
    blocTest<AboutCubit, AboutState>(
      'emits the open movies',
      setUp: () =>
          when(() => repository.getAll()).thenAnswer((_) async => [sintel]),
      build: () => AboutCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        const AboutLoading(),
        AboutSuccess([sintel]),
      ],
    );

    blocTest<AboutCubit, AboutState>(
      'a catalogue failure is shown with its message, and retry recovers',
      setUp: () {
        var calls = 0;
        when(() => repository.getAll()).thenAnswer((_) async {
          if (calls++ == 0) throw failure;
          return [sintel];
        });
      },
      build: () => AboutCubit(repository),
      act: (cubit) async {
        await cubit.load();
        await cubit.load();
      },
      expect: () => [
        const AboutLoading(),
        const AboutFailure(failure),
        const AboutLoading(),
        AboutSuccess([sintel]),
      ],
    );

    test('does not emit after close', () async {
      when(() => repository.getAll()).thenAnswer((_) async => [sintel]);
      final cubit = AboutCubit(repository);
      final pending = cubit.load();
      await cubit.close();
      await pending;
      expect(cubit.state, const AboutLoading());
    });
  });
}
