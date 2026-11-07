import 'package:filmbuster/domain/models/tmdb_person_details.dart';
import 'package:filmbuster/presentation/features/person/bloc/person_cubit.dart';
import 'package:filmbuster/presentation/features/person/layouts/person_layout.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/app.dart';
import '../../../support/mocks.dart';
import '../../../support/poppins.dart';
import '../../../support/test_view.dart';
import '../../../support/text_layout.dart';

Future<void> _pumpPerson(WidgetTester tester, String name) async {
  final people = MockPersonRepository();
  when(
    () => people.getDetails(1),
  ).thenAnswer((_) async => TmdbPersonDetails(id: 1, name: name));
  when(() => people.getMovies(1)).thenAnswer((_) async => const []);
  final cubit = PersonCubit(people, 1);
  addTearDown(cubit.close);
  await cubit.load();

  await tester.pumpWidget(
    inApp(BlocProvider.value(value: cubit, child: const PersonLayout())),
  );
}

void main() {
  setUpAll(loadPoppins);

  testWidgets('the header names the person in 18 pt semibold on a phone', (
    tester,
  ) async {
    useViewSize(tester, referencePhone);
    await _pumpPerson(tester, 'Sacha Goedegebure');

    final name = drawnStyleOf(tester, find.text('Sacha Goedegebure'));
    expect(name.fontSize, 18);
    expect(name.fontWeight, FontWeight.w600);
  });

  testWidgets('the header shows a long name in full on the narrowest phone', (
    tester,
  ) async {
    useViewSize(tester, compactPhone);
    await _pumpPerson(tester, 'Isabella Montgomery-Lee');

    final name = tester.renderObject<RenderParagraph>(
      find.text('Isabella Montgomery-Lee'),
    );
    expect(name.didExceedMaxLines, isFalse);
  });
}
