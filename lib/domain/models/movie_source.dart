import 'package:equatable/equatable.dart';

import 'content_license.dart';
import 'json_parsing.dart';
import 'player_source.dart';

/// How the bytes of a [MovieSource] are delivered (not where they come from).
enum SourceKind { direct, stream }

class MovieSource extends Equatable {
  const MovieSource({
    required this.id,
    required this.providerName,
    required this.kind,
    required this.url,
    required this.quality,
    required this.mimeType,
    required this.license,
    required this.attribution,
    this.codecs,
    this.sourcePageUrl,
  });

  final String id;
  final String providerName;
  final SourceKind kind;

  /// Played verbatim; never rebuilt or rewritten.
  final Uri url;
  final String quality;
  final String mimeType;
  final String? codecs;
  final ContentLicense license;
  final String attribution;
  final Uri? sourcePageUrl;

  /// An unknown `kind` or a malformed field throws [FormatException].
  factory MovieSource.fromJson(Map<String, dynamic> json) {
    final kind = _kindFrom(json['kind']);
    if (kind == null) {
      throw FormatException('Unknown source kind: ${json['kind']}');
    }
    final attribution = json['attribution'] as String;
    if (attribution.trim().isEmpty) {
      throw const FormatException('A source needs an attribution');
    }
    final pageUrl = json['sourcePageUrl'] as String?;
    return MovieSource(
      id: json['id'] as String,
      providerName: json['providerName'] as String,
      kind: kind,
      url: parseAbsoluteUrl(
        json['url'] as String,
        allowHttp: kind == SourceKind.stream,
      ),
      quality: json['quality'] as String,
      mimeType: json['mimeType'] as String,
      codecs: json['codecs'] as String?,
      license: ContentLicense.fromJson(parseJsonObject(json['license'])),
      attribution: attribution,
      sourcePageUrl: pageUrl == null ? null : parseAbsoluteUrl(pageUrl),
    );
  }

  PlayerSource toPlayerSource() =>
      PlayerSource(url: url.toString(), label: '$quality · $providerName');

  @override
  List<Object?> get props => [
    id,
    providerName,
    kind,
    url,
    quality,
    mimeType,
    codecs,
    license,
    attribution,
    sourcePageUrl,
  ];
}

/// The sources of one movie, best first.
class MovieSourceList extends Equatable {
  const MovieSourceList({this.results = const [], this.partial = false});

  final List<MovieSource> results;

  /// `true` when a provider failed, so [results] may be incomplete.
  final bool partial;

  /// Sources of a kind this client does not know are skipped, so the server
  /// can add kinds without breaking older clients; any other malformed item
  /// throws.
  factory MovieSourceList.fromJson(Map<String, dynamic> json) {
    final sources = parseJsonList(json['results'], _knownKindOrNull);
    return MovieSourceList(
      results: List.unmodifiable(sources.nonNulls),
      partial: json['partial'] as bool,
    );
  }

  static MovieSource? _knownKindOrNull(Map<String, dynamic> json) =>
      _kindFrom(json['kind']) == null ? null : MovieSource.fromJson(json);

  @override
  List<Object?> get props => [results, partial];
}

SourceKind? _kindFrom(Object? name) => SourceKind.values.asNameMap()[name];
