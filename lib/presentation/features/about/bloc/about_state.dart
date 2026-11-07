part of 'about_cubit.dart';

sealed class AboutState extends Equatable {
  const AboutState();

  @override
  List<Object?> get props => const [];
}

class AboutLoading extends AboutState {
  const AboutLoading();
}

class AboutSuccess extends AboutState {
  const AboutSuccess(this.movies);

  final List<OpenMovie> movies;

  @override
  List<Object?> get props => [movies];
}

class AboutFailure extends AboutState {
  const AboutFailure(this.failure);

  final AppFailure failure;

  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}
