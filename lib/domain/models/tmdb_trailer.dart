import 'package:equatable/equatable.dart';

import 'json_parsing.dart';

/// An official trailer or teaser from TMDB `videos`, opened externally; the
/// app never embeds or downloads it.
class TmdbTrailer extends Equatable {
  const TmdbTrailer({required this.url});

  /// Watch URL built by the server; always `https`.
  final Uri url;

  factory TmdbTrailer.fromJson(Map<String, dynamic> json) =>
      TmdbTrailer(url: parseAbsoluteUrl(json['url'] as String));

  @override
  List<Object?> get props => [url];
}
