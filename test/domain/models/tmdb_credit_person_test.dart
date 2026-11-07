import 'package:filmbuster/domain/models/tmdb_credit_person.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TmdbCreditPerson', () {
    test('role prefers character over job', () {
      const json = {
        'id': 1,
        'name': 'X',
        'character': 'Hero',
        'job': 'Director',
      };
      expect(TmdbCreditPerson.fromJson(json).role, 'Hero');
    });
  });
}
