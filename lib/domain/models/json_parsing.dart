/// A wrong shape, or `null` unless [nullAsEmpty] is set, throws
/// [FormatException], so a broken response is reported instead of shown as
/// "nothing found".
List<T> parseJsonList<T>(
  Object? raw,
  T Function(Map<String, dynamic> json) fromJson, {
  bool nullAsEmpty = false,
}) {
  if (raw == null && nullAsEmpty) return const [];
  if (raw is! List) {
    throw FormatException('Expected a JSON array but got ${raw.runtimeType}');
  }
  return raw
      .map((item) => fromJson(parseJsonObject(item)))
      .toList(growable: false);
}

Map<String, dynamic> parseJsonObject(Object? raw) => switch (raw) {
  final Map<String, dynamic> json => json,
  _ => throw FormatException(
    'Expected a JSON object but got ${raw.runtimeType}',
  ),
};

/// Accepts only an absolute `https` URL, or `http` with [allowHttp]; anything
/// else throws [FormatException].
Uri parseAbsoluteUrl(String raw, {bool allowHttp = false}) {
  final uri = Uri.parse(raw);
  final schemeAllowed =
      uri.isScheme('https') || (allowHttp && uri.isScheme('http'));
  if (!schemeAllowed || uri.host.isEmpty) {
    throw FormatException('Not an absolute URL with an allowed scheme', raw);
  }
  return uri;
}
