import 'package:insaeng/domain/app_exception.dart';
import 'package:meta/meta.dart';

export 'package:insaeng/domain/app_exception.dart';

@immutable
sealed class Result<T> {
  const new();

  const factory ok(T value) = Ok<T>;

  const factory error(AppException error) = Err<T>;
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
  const new(this.error);

  final AppException error;

  @override
  bool operator ==(Object other) => other is Err<T> && other.error == error;

  @override
  int get hashCode => Object.hash(Err<T>, error);

  @override
  String toString() => 'Result<$T>.error($error)';
}
