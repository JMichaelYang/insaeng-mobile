import 'package:insaeng/domain/app_failure.dart';
import 'package:meta/meta.dart';

export 'package:insaeng/domain/app_failure.dart';

@immutable
sealed class Result<T> {
  const new();

  const factory ok(T value) = Ok<T>;

  const factory failure(AppFailure failure) = Err<T>;
}

final class Ok<T> extends Result<T> {
  const new(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok<T>, value);

  @override
  String toString() => 'Result<$T>.ok($value)';
}

final class Err<T> extends Result<T> {
  const new(this.failure);

  final AppFailure failure;

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err<T>, failure);

  @override
  String toString() => 'Result<$T>.failure($failure)';
}
