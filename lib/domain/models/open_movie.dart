import 'package:equatable/equatable.dart';

import 'content_license.dart';

/// An openly licensed film from the bundled catalogue, with what is needed
/// to credit it.
class OpenMovie extends Equatable {
  const OpenMovie({
    required this.tmdbId,
    required this.title,
    required this.year,
    required this.directedBy,
    required this.attribution,
    required this.license,
    required this.sourceUrl,
  });

  final int tmdbId;
  final String title;
  final int year;
  final String directedBy;
  final String attribution;
  final ContentLicense license;
  final Uri sourceUrl;

  @override
  List<Object?> get props => [
    tmdbId,
    title,
    year,
    directedBy,
    attribution,
    license,
    sourceUrl,
  ];
}
