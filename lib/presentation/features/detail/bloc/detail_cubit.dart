import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../domain/models/movie_source.dart';
import '../../../../domain/models/tmdb_movie_details.dart';
import '../../../../domain/repositories/movie_repository.dart';
import '../../../../domain/repositories/movie_sources_repository.dart';

part 'detail_state.dart';

/// Loads a movie and, concurrently, its playable sources. A sources failure
/// never fails Detail: it becomes [SourcesFailed] inside [DetailSuccess].
class DetailCubit extends Cubit<DetailState> {
  /// [isPlayable] keeps only the sources this platform can play; without
  /// it every source is kept.
  DetailCubit(
    this._movies,
    this._sources,
    this._tmdbId, {
    bool Function(MovieSource source)? isPlayable,
  }) : _isPlayable = isPlayable ?? _playsAll,
       super(const DetailLoading());

  static const _log = AppLogger('Detail');

  final MovieRepository _movies;
  final MovieSourcesRepository _sources;
  final int _tmdbId;
  final bool Function(MovieSource source) _isPlayable;

  static bool _playsAll(MovieSource _) => true;

  /// Bumped by every load, so an answer to an older request is dropped.
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    emit(const DetailLoading());
    final sources = _fetchSources();
    try {
      final detail = await _movies.getDetails(_tmdbId);
      if (isClosed || generation != _generation) return;
      emit(DetailSuccess(detail));
    } catch (error, stackTrace) {
      if (isClosed || generation != _generation) return;
      emit(DetailFailure(error.toAppFailure(stackTrace)));
      return;
    }
    final status = await sources;
    _emitSources(generation, status);
  }

  Future<void> retrySources() async {
    if (state is! DetailSuccess) return;
    final generation = ++_generation;
    _emitSources(generation, const SourcesLoading());
    _emitSources(generation, await _fetchSources());
  }

  Future<SourcesStatus> _fetchSources() async {
    try {
      final list = await _sources.getSources(_tmdbId);
      final playable = list.results.where(_isPlayable).toList(growable: false);
      return SourcesLoaded(playable: playable, partial: list.partial);
    } catch (error, stackTrace) {
      final failure = error.toAppFailure(stackTrace);
      _log.warn('sources for $_tmdbId failed: ${failure.message}');
      return SourcesFailed(failure);
    }
  }

  void _emitSources(int generation, SourcesStatus status) {
    final current = state;
    if (isClosed || generation != _generation || current is! DetailSuccess) {
      return;
    }
    emit(current.copyWithSources(status));
  }
}
