import 'package:filmbuster/core/utils/text_similarity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tokenSortSimilarity', () {
    test('identical strings score 100', () {
      expect(tokenSortSimilarity('Blade Runner', 'Blade Runner'), 100);
    });

    test('word order does not matter', () {
      expect(tokenSortSimilarity('runner blade', 'Blade Runner'), 100);
    });

    test('case and punctuation are ignored', () {
      expect(tokenSortSimilarity('DUNE: part-two!', 'Dune Part Two'), 100);
    });

    test('an empty or separator-only string scores 0', () {
      expect(tokenSortSimilarity('', 'Dune'), 0);
      expect(tokenSortSimilarity('Dune', ''), 0);
      expect(tokenSortSimilarity('', ''), 0);
      expect(tokenSortSimilarity(' - ', 'Dune'), 0);
    });

    test('different strings score lower, closer ones higher', () {
      final exact = tokenSortSimilarity('dune', 'Dune');
      final longer = tokenSortSimilarity('dune', 'Dune: Part Two');
      final unrelated = tokenSortSimilarity('dune', 'Arrival');

      expect(exact, 100);
      expect(longer, lessThan(exact));
      expect(unrelated, lessThan(longer));
      expect(unrelated, inInclusiveRange(0, 99));
    });

    test('Cyrillic letters are tokens, not separators', () {
      expect(
        tokenSortSimilarity('ДЮНА часть вторая', 'Часть вторая: Дюна'),
        100,
      );
      expect(tokenSortSimilarity('дюна', 'Прибытие'), lessThan(50));
      expect(tokenSortSimilarity('ёлки', 'Ёлки 2'), lessThan(100));
    });

    test('the edit distance is scaled by the longer string', () {
      expect(tokenSortSimilarity('kitten', 'sitting'), 57);
    });

    test('long strings that differ never score 100', () {
      expect(tokenSortSimilarity('a' * 250, '${'a' * 249}b'), 99);
    });
  });

  group('containsAllTokens', () {
    test('matches every query token regardless of case and punctuation', () {
      expect(containsAllTokens('matrix', 'The Matrix: Reloaded'), isTrue);
      expect(containsAllTokens('dune two', 'Dune: Part Two'), isTrue);
    });

    test('rejects missing tokens and empty queries', () {
      expect(containsAllTokens('matrix', 'Inception'), isFalse);
      expect(containsAllTokens('  ', 'Inception'), isFalse);
    });
  });
}
