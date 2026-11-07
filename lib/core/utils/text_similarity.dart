import 'dart:math' as math;

final RegExp _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Similarity of [a] and [b] from 0 to 100, ignoring word order, case and
/// punctuation. Only the same set of words scores 100; a string without
/// words scores 0.
int tokenSortSimilarity(String a, String b) {
  final left = _tokenSort(a);
  final right = _tokenSort(b);
  if (left.isEmpty || right.isEmpty) return 0;
  final longest = math.max(left.length, right.length);
  final distance = _levenshtein(left, right);
  if (distance == 0) return 100;
  return math.min(99, ((longest - distance) * 100 / longest).round());
}

/// Whether every token of [query] appears among the tokens of [text],
/// ignoring case and punctuation. An empty query matches nothing.
bool containsAllTokens(String query, String text) {
  final wanted = _tokens(query);
  if (wanted.isEmpty) return false;
  return _tokens(text).toSet().containsAll(wanted);
}

List<String> _tokens(String input) =>
    input.toLowerCase().split(_separators).where((t) => t.isNotEmpty).toList();

List<int> _tokenSort(String input) =>
    (_tokens(input)..sort()).join(' ').runes.toList();

int _levenshtein(List<int> a, List<int> b) {
  var previous = List<int>.generate(b.length + 1, (i) => i);
  var current = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = math.min(
        math.min(current[j - 1] + 1, previous[j] + 1),
        previous[j - 1] + cost,
      );
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[b.length];
}
