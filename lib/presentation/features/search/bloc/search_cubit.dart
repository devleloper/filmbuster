import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/text_similarity.dart';
import '../../../../domain/models/tmdb_movie.dart';
import '../../../../domain/repositories/movie_repository.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._movies) : super(const SearchInitial());

  static const _closeMatch = 80;

  final MovieRepository _movies;

  /// Bumped by every search, so a slow answer to an older query never
  /// replaces a newer one.
  int _generation = 0;

  Future<void> search(String query) async {
    final trimmed = query.trim();
    final generation = ++_generation;

    if (trimmed.isEmpty) {
      emit(const SearchInitial());
      return;
    }

    emit(const SearchLoading());
    try {
      final results = await _movies.search(trimmed);
      if (isClosed || generation != _generation) return;
      emit(SearchSuccess(_rankByRelevance(trimmed, results), query: trimmed));
    } catch (error, stackTrace) {
      if (isClosed || generation != _generation) return;
      emit(SearchFailure(error.toAppFailure(stackTrace), query: trimmed));
    }
  }

  Future<void> retry() async {
    if (state case SearchFailure(:final query)) await search(query);
  }

  /// Matching titles move to the front, but each group keeps the
  /// repository's order (TMDB relevance and popularity), so an exact but
  /// obscure title never outranks the well-known one.
  static List<TmdbMovie> _rankByRelevance(
    String query,
    List<TmdbMovie> results,
  ) {
    bool matches(TmdbMovie movie) =>
        containsAllTokens(query, movie.title) ||
        tokenSortSimilarity(query, movie.title) >= _closeMatch;
    return [
      ...results.where(matches),
      ...results.where((movie) => !matches(movie)),
    ];
  }
}
