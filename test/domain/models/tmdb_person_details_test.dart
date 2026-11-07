import 'package:filmbuster/domain/models/tmdb_person_details.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TmdbPersonDetails', () {
    test('person details read the camelCase contract only', () {
      final person = TmdbPersonDetails.fromJson(const {
        'id': 1,
        'name': 'A',
        'profilePath': '/a.jpg',
        'biography': null,
        'knownForDepartment': 'Acting',
      });
      expect(person.profilePath, '/a.jpg');
      expect(person.knownForDepartment, 'Acting');
      expect(
        TmdbPersonDetails.fromJson(const {
          'id': 1,
          'name': 'A',
          'profile_path': '/a.jpg',
        }).profilePath,
        isNull,
      );
    });

    test('a person without a name is a type error', () {
      expect(
        () => TmdbPersonDetails.fromJson(const {'id': 1}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
