import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/utils/result.dart';

void main() {
  group(Result, () {
    test('ok holds its value', () {
      const result = Result.ok(42);

      expect(result, isA<Ok<int>>().having((r) => r.value, 'value', 42));
    });

    test('error holds its exception', () {
      final exception = Exception('boom');
      final result = Result<int>.error(exception);

      expect(
        result,
        isA<Err<int>>().having((r) => r.error, 'error', same(exception)),
      );
    });

    test('switch is exhaustive over Ok and Err', () {
      String describe(Result<int> result) => switch (result) {
        Ok(:final value) => 'ok $value',
        Err(:final error) => 'error $error',
      };

      expect(describe(const Result.ok(1)), 'ok 1');
      expect(describe(Result.error(Exception('x'))), 'error Exception: x');
    });

    test('supports value equality', () {
      final exception = Exception('boom');

      expect(const Result.ok(1), const Result.ok(1));
      expect(const Result.ok(1), isNot(const Result.ok(2)));
      expect(Result<int>.error(exception), Result<int>.error(exception));
      expect(const Result.ok(1).hashCode, const Result.ok(1).hashCode);
    });
  });
}
