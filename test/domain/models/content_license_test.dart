import 'package:filmbuster/domain/models/content_license.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContentLicense.fromJson', () {
    test('parses the license deed as an absolute URL', () {
      final license = ContentLicense.fromJson(const {
        'spdxId': 'CC-BY-3.0',
        'name': 'CC BY 3.0',
        'url': 'https://creativecommons.org/licenses/by/3.0/',
      });

      expect(
        license.url,
        Uri.parse('https://creativecommons.org/licenses/by/3.0/'),
      );
    });

    test('keeps an http license deed, which the contract allows', () {
      final license = ContentLicense.fromJson(const {
        'spdxId': 'CC-BY-3.0',
        'name': 'CC BY 3.0',
        'url': 'http://creativecommons.org/licenses/by/3.0/',
      });

      expect(
        license.url,
        Uri.parse('http://creativecommons.org/licenses/by/3.0/'),
      );
    });

    test('rejects a relative license URL', () {
      expect(
        () => ContentLicense.fromJson(const {
          'spdxId': 'CC-BY-3.0',
          'name': 'CC BY 3.0',
          'url': 'creativecommons.org/licenses/by/3.0/',
        }),
        throwsFormatException,
      );
    });
  });
}
