import 'package:equatable/equatable.dart';

import 'json_parsing.dart';

/// The license of a film, for example `CC-BY-3.0` named "CC BY 3.0".
class ContentLicense extends Equatable {
  const ContentLicense({required this.spdxId, required this.name, this.url});

  final String spdxId;
  final String name;

  /// The license deed, `http` or `https`; `null` when the license has none.
  final Uri? url;

  factory ContentLicense.fromJson(Map<String, dynamic> json) {
    final spdxId = json['spdxId'] as String;
    final name = json['name'] as String;
    if (spdxId.isEmpty || name.isEmpty) {
      throw const FormatException('ContentLicense needs spdxId and name');
    }
    final url = json['url'] as String?;
    return ContentLicense(
      spdxId: spdxId,
      name: name,
      url: url == null ? null : parseAbsoluteUrl(url, allowHttp: true),
    );
  }

  @override
  List<Object?> get props => [spdxId, name, url];
}
