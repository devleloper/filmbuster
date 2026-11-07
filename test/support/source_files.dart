import 'dart:io';

/// [directories] are relative to `client/`, where tests run.
List<File> dartFilesUnder(List<String> directories) => [
  for (final directory in directories)
    ...Directory(directory)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart')),
];

List<String> filesContaining(List<String> directories, Pattern pattern) => [
  for (final file in dartFilesUnder(directories))
    if (file.readAsStringSync().contains(pattern)) file.path,
];

final _importPattern = RegExp(
  r'''^import\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// What [file] imports. Imports of this package become paths such as
/// `lib/data/remote/api_guard.dart`; `dart:` and other packages stay as
/// written.
List<String> importsOf(File file) => [
  for (final match in _importPattern.allMatches(file.readAsStringSync()))
    _resolve(file, match.group(1)!),
];

String _resolve(File file, String uri) {
  const self = 'package:filmbuster/';
  if (uri.startsWith(self)) return 'lib/${uri.substring(self.length)}';
  if (uri.contains(':')) return uri;
  return Uri.file(file.path).resolve(uri).toFilePath();
}

/// `file: import` for every import of the files under [under] that
/// [isForbidden] rejects, except in the files listed in [allowed].
List<String> importViolations({
  required List<String> under,
  required bool Function(String file, String import) isForbidden,
  Set<String> allowed = const {},
}) => [
  for (final file in dartFilesUnder(under))
    if (!allowed.contains(file.path))
      for (final import in importsOf(file))
        if (isForbidden(file.path, import)) '${file.path}: $import',
];
