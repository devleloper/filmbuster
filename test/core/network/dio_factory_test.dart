import 'package:filmbuster/core/network/dio_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an unreachable backend fails within seconds, not minutes', () {
    final options = DioFactory.create(
      baseUrl: 'https://api.example.com',
    ).options;

    expect(
      options.connectTimeout,
      lessThanOrEqualTo(const Duration(seconds: 10)),
    );
    expect(
      options.receiveTimeout,
      lessThanOrEqualTo(const Duration(seconds: 20)),
    );
  });
}
