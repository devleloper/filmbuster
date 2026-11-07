part of 'search_cubit.dart';

sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => const [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchSuccess extends SearchState {
  const SearchSuccess(this.results, {required this.query});

  final List<TmdbMovie> results;
  final String query;

  @override
  List<Object?> get props => [results, query];
}

class SearchFailure extends SearchState {
  const SearchFailure(this.failure, {required this.query});

  final AppFailure failure;
  final String query;

  String get message => failure.message;

  @override
  List<Object?> get props => [failure, query];
}
