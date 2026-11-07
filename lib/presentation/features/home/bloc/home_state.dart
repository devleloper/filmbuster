part of 'home_cubit.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => const [];
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeSuccess extends HomeState {
  const HomeSuccess({
    required this.popular,
    required this.topRated,
    required this.trending,
  });

  final List<TmdbMovie> popular;
  final List<TmdbMovie> topRated;
  final List<TmdbMovie> trending;

  @override
  List<Object?> get props => [popular, topRated, trending];
}

/// The catalogue answered, but every list was empty.
class HomeEmpty extends HomeState {
  const HomeEmpty();
}

class HomeFailure extends HomeState {
  const HomeFailure(this.failure);

  final AppFailure failure;

  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}
