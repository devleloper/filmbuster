import 'package:flutter_test/flutter_test.dart';

import '../support/source_files.dart';

/// Values that belong in `lib/presentation/theme/` tokens. A line may keep one
/// when it carries a `// design-literal: <reason>` comment.
final _literals = <String, RegExp>{
  'Color(0x': RegExp(r'Color\(0x'),
  'Colors.': RegExp(r'(^|[^A-Za-z])Colors\.'),
  'poppinsText(': RegExp(r'poppinsText\('),
  'Duration(': RegExp(r'Duration\((milli)?seconds'),
  'fontSize: <number>': RegExp(r'fontSize: \d'),
  'Radius.circular(<number>)': RegExp(r'(Border)?Radius\.circular\(\d'),
  'TextStyle(': RegExp(r'(^|[^A-Za-z])TextStyle\('),
};

/// Most literals each pattern may still have in `lib/presentation/features/`.
/// Lower a number when a change removes literals; never raise one.
const _featureBudget = <String, int>{
  'Color(0x': 0,
  'Colors.': 0,
  'poppinsText(': 0,
  'Duration(': 31,
  'fontSize: <number>': 2,
  'Radius.circular(<number>)': 3,
  'TextStyle(': 4,
};

Map<String, List<String>> _findLiterals(String directory) {
  final hits = {for (final name in _literals.keys) name: <String>[]};
  for (final file in dartFilesUnder([directory])) {
    for (final (index, line) in file.readAsLinesSync().indexed) {
      if (line.contains('// design-literal:')) continue;
      for (final MapEntry(key: name, value: pattern) in _literals.entries) {
        if (pattern.hasMatch(line)) {
          hits[name]!.add('${file.path}:${index + 1}: ${line.trim()}');
        }
      }
    }
  }
  return hits;
}

void main() {
  test('shared widgets take colours, type, motion and radii from tokens', () {
    final hits = _findLiterals('lib/presentation/widgets');
    for (final MapEntry(key: name, value: lines) in hits.entries) {
      expect(lines, isEmpty, reason: '$name literals:\n${lines.join('\n')}');
    }
  });

  test('feature screens do not add design literals', () {
    final hits = _findLiterals('lib/presentation/features');
    for (final MapEntry(key: name, value: budget) in _featureBudget.entries) {
      expect(
        hits[name]!.length,
        lessThanOrEqualTo(budget),
        reason: '$name literals:\n${hits[name]!.join('\n')}',
      );
    }
  });
}
