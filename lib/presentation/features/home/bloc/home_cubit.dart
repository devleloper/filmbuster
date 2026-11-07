import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../domain/models/tmdb_movie.dart';
import '../../../../domain/repositories/movie_repository.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._movies) : super(const HomeLoading());

  final MovieRepository _movies;

  /// Bumped by every refresh, so a slow answer to an older request never
  /// replaces a newer one.
  int _generation = 0;

  Future<void> load() async {
    emit(const HomeLoading());
    await refresh();
  }

  /// Fetches the catalogue again while the current content stays on screen.
  Future<void> refresh() async {
    final generation = ++_generation;
    try {
      final [popular, topRated, trending] = await Future.wait([
        _movies.getPopular(),
        _movies.getTopRated(),
        _movies.getTrending(),
      ]);
      if (isClosed || generation != _generation) return;
      if (popular.isEmpty && topRated.isEmpty && trending.isEmpty) {
        emit(const HomeEmpty());
      } else {
        emit(
          HomeSuccess(popular: popular, topRated: topRated, trending: trending),
        );
      }
    } catch (error, stackTrace) {
      if (isClosed || generation != _generation) return;
      emit(HomeFailure(error.toAppFailure(stackTrace)));
    }
  }
}
