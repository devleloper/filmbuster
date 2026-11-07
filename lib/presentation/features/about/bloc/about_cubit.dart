import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../domain/models/open_movie.dart';
import '../../../../domain/repositories/open_movie_repository.dart';

part 'about_state.dart';

class AboutCubit extends Cubit<AboutState> {
  AboutCubit(this._openMovies) : super(const AboutLoading());

  final OpenMovieRepository _openMovies;

  Future<void> load() async {
    emit(const AboutLoading());
    try {
      final movies = await _openMovies.getAll();
      if (isClosed) return;
      emit(AboutSuccess(movies));
    } catch (error, stackTrace) {
      if (isClosed) return;
      emit(AboutFailure(error.toAppFailure(stackTrace)));
    }
  }
}
