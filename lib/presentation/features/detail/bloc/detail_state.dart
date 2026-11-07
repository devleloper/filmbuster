part of 'detail_cubit.dart';

sealed class DetailState extends Equatable {
  const DetailState();

  @override
  List<Object?> get props => const [];
}

class DetailLoading extends DetailState {
  const DetailLoading();
}

class DetailSuccess extends DetailState {
  const DetailSuccess(this.detail, {this.sources = const SourcesLoading()});

  final TmdbMovieDetails detail;
  final SourcesStatus sources;

  DetailSuccess copyWithSources(SourcesStatus sources) =>
      DetailSuccess(detail, sources: sources);

  @override
  List<Object?> get props => [detail, sources];
}

class DetailFailure extends DetailState {
  const DetailFailure(this.failure);

  final AppFailure failure;

  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}

/// Playable sources of the movie shown in [DetailSuccess].
sealed class SourcesStatus extends Equatable {
  const SourcesStatus();

  @override
  List<Object?> get props => const [];
}

class SourcesLoading extends SourcesStatus {
  const SourcesLoading();
}

class SourcesLoaded extends SourcesStatus {
  const SourcesLoaded({this.playable = const [], this.partial = false});

  /// Sources this platform can play, best first.
  final List<MovieSource> playable;

  /// A provider failed, so [playable] may be incomplete.
  final bool partial;

  /// The source Play opens; null hides Play.
  MovieSource? get first => playable.firstOrNull;

  /// Nothing to play, but a retry may find something.
  bool get canRetry => playable.isEmpty && partial;

  @override
  List<Object?> get props => [playable, partial];
}

class SourcesFailed extends SourcesStatus {
  const SourcesFailed(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}
