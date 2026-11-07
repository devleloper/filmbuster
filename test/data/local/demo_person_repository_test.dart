import 'package:filmbuster/core/error/app_failure.dart';
import 'package:filmbuster/data/local/bundled_catalog.dart';
import 'package:filmbuster/data/local/demo_person_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/disk_assets.dart';

void main() {
  late BundledCatalog catalog;
  late DemoPersonRepository people;

  setUp(() {
    catalog = bundledCatalogFromDisk();
    people = DemoPersonRepository(catalog);
  });

  test('a director has their catalogue titles', () async {
    final sintel = (await catalog.load()).movies[45745]!;
    final director = sintel.crew.single;

    final person = await people.getDetails(director.id);

    expect(person.name, director.name);
    expect((await people.getMovies(director.id)).map((m) => m.id), [45745]);
  });

  test('an unknown person is NotFoundFailure', () async {
    await expectLater(people.getDetails(999), throwsA(isA<NotFoundFailure>()));
    await expectLater(people.getMovies(999), throwsA(isA<NotFoundFailure>()));
  });
}
