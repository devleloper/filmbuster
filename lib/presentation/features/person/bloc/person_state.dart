part of 'person_cubit.dart';

sealed class PersonState extends Equatable {
  const PersonState();

  @override
  List<Object?> get props => const [];
}

class PersonLoading extends PersonState {
  const PersonLoading();
}

class PersonSuccess extends PersonState {
  const PersonSuccess({required this.person, required this.movies});

  final TmdbPersonDetails person;
  final List<TmdbMovie> movies;

  @override
  List<Object?> get props => [person, movies];
}

class PersonFailure extends PersonState {
  const PersonFailure(this.failure);

  final AppFailure failure;

  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}
