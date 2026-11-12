import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/result.dart';

sealed class _FeatureException extends AppException {
  const new();
}

final class _NotFound extends _FeatureException {
  const new();
}

final class _Conflict extends _FeatureException {
  const new();
}

final class _OtherException extends AppException {
  const new();
}

void main() {
  group(Result, () {
    test('ok holds its value', () {
      const result = Result.ok(42);

      expect(result, isA<Ok<int>>().having((r) => r.value, 'value', 42));
    });

    test('error holds its exception', () {
      const exception = _NotFound();
      const result = Result<int>.error(exception);

      expect(
        result,
        isA<Err<int>>().having((r) => r.error, 'error', same(exception)),
      );
    });

    test('switch is exhaustive over Ok and Err', () {
      String describe(Result<int> result) => switch (result) {
        Ok(:final value) => 'ok $value',
        Err() => 'error',
      };

      expect(describe(const Result.ok(1)), 'ok 1');
      expect(describe(const Result.error(_NotFound())), 'error');
    });

    test('errors switch on feature families with a default branch', () {
      String describe(AppException error) => switch (error) {
        _NotFound() => 'not found',
        _Conflict() => 'conflict',
        _ => 'unknown',
      };

      expect(describe(const _NotFound()), 'not found');
      expect(describe(const _Conflict()), 'conflict');
      expect(describe(const _OtherException()), 'unknown');
    });

    test('supports value equality', () {
      expect(const Result.ok(1), const Result.ok(1));
      expect(const Result.ok(1), isNot(const Result.ok(2)));
      expect(
        const Result<int>.error(_NotFound()),
        const Result<int>.error(_NotFound()),
      );
      expect(const Result.ok(1).hashCode, const Result.ok(1).hashCode);
    });
  });
}
