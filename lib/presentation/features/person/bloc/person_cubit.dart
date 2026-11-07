import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../domain/models/tmdb_movie.dart';
import '../../../../domain/models/tmdb_person_details.dart';
import '../../../../domain/repositories/person_repository.dart';

part 'person_state.dart';

class PersonCubit extends Cubit<PersonState> {
  PersonCubit(this._people, this._personId) : super(const PersonLoading());

  final PersonRepository _people;
  final int _personId;

  Future<void> load() async {
    emit(const PersonLoading());
    try {
      final person = _people.getDetails(_personId);
      final movies = _people.getMovies(_personId);
      await Future.wait([person, movies]);
      if (isClosed) return;
      emit(PersonSuccess(person: await person, movies: await movies));
    } catch (error, stackTrace) {
      if (isClosed) return;
      emit(PersonFailure(error.toAppFailure(stackTrace)));
    }
  }
}
