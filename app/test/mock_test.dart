import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mock Test', () {
    test('should add two numbers', () {
      final result = 2 + 3;
      expect(result, 5);
    });

    test('should return true for equality', () {
      expect('hostr', equals('hostr'));
    });
  });
}
