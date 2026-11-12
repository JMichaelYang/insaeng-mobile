import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/result.dart';

sealed class _FeatureFailure extends Failure {
  const new();
}

final class _NotFound extends _FeatureFailure {
  const new();
}

final class _Conflict extends _FeatureFailure {
  const new();
}

final class _OtherFailure extends Failure {
  const new();
}

void main() {
  group(Result, () {
    test('ok holds its value', () {
      const result = Result.ok(42);

      expect(result, isA<Ok<int>>().having((r) => r.value, 'value', 42));
    });

    test('err holds its failure', () {
      const failure = _NotFound();
      const result = Result<int>.err(failure);

      expect(result, isA<Err<int>>().having((r) => r.failure, 'failure', same(failure)));
    });

    test('switch is exhaustive over Ok and Err', () {
      String describe(Result<int> result) => switch (result) {
        Ok(:final value) => 'ok $value',
        Err() => 'err',
      };

      expect(describe(const Result.ok(1)), 'ok 1');
      expect(describe(const Result.err(_NotFound())), 'err');
    });

    test('failures switch on feature families with a default branch', () {
      String describe(Failure failure) => switch (failure) {
        _NotFound() => 'not found',
        _Conflict() => 'conflict',
        _ => 'unknown',
      };

      expect(describe(const _NotFound()), 'not found');
      expect(describe(const _Conflict()), 'conflict');
      expect(describe(const _OtherFailure()), 'unknown');
    });

    test('supports value equality', () {
      expect(const Result.ok(1), const Result.ok(1));
      expect(const Result.ok(1), isNot(const Result.ok(2)));
      expect(const Result<int>.err(_NotFound()), const Result<int>.err(_NotFound()));
      expect(const Result.ok(1).hashCode, const Result.ok(1).hashCode);
    });
  });
}
