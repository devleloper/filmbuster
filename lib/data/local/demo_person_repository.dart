import '../../core/error/app_failure.dart';
import '../../domain/models/tmdb_movie.dart';
import '../../domain/models/tmdb_person_details.dart';
import '../../domain/repositories/person_repository.dart';
import 'bundled_catalog.dart';

/// People have local ids; a filmography is the bundled titles that credit
/// the person.
class DemoPersonRepository implements PersonRepository {
  const DemoPersonRepository(this._catalog);

  final BundledCatalog _catalog;

  @override
  Future<TmdbPersonDetails> getDetails(int personId) async {
    final person = (await _catalog.load()).people[personId];
    if (person == null) {
      throw const NotFoundFailure(message: NotFoundFailure.personMessage);
    }
    return person;
  }

  @override
  Future<List<TmdbMovie>> getMovies(int personId) async {
    final catalog = await _catalog.load();
    if (!catalog.people.containsKey(personId)) {
      throw const NotFoundFailure(message: NotFoundFailure.personMessage);
    }
    return [
      for (final movie in catalog.ordered)
        if (movie.credits.any((credit) => credit.id == personId))
          movie.toSummary(),
    ];
  }
}
