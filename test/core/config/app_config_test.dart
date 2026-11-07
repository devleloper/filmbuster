import 'package:filmbuster/core/config/app_config.dart';
import 'package:filmbuster/core/config/data_source_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.normalizeBaseUrl', () {
    test('keeps a non-blank value', () {
      expect(
        AppConfig.normalizeBaseUrl('https://api.example.com'),
        'https://api.example.com',
      );
    });

    test('is null for an empty value', () {
      expect(AppConfig.normalizeBaseUrl(''), isNull);
    });

    test('is null for a blank value', () {
      expect(AppConfig.normalizeBaseUrl('   '), isNull);
    });

    test('trims surrounding whitespace', () {
      expect(
        AppConfig.normalizeBaseUrl(' http://192.0.2.10:3000 '),
        'http://192.0.2.10:3000',
      );
    });
  });

  test('without --dart-define the app runs in demo mode', () {
    expect(AppConfig.baseUrl, isNull);
    expect(AppConfig.dataSource, DataSourceMode.demo);
  });

  test('without --dart-define the layout follows the device', () {
    expect(AppConfig.forceLeanback, isFalse);
  });
}
