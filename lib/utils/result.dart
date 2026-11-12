import 'package:flutter/foundation.dart' show immutable;

/// The outcome of an operation that can fail.
///
/// Repositories and services return a [Result] instead of throwing, so
/// callers handle failure explicitly with an exhaustive `switch`:
///
/// ```dart
/// switch (await repository.fetch()) {
///   case Ok(:final value):
///     emit(state.copyWith(item: value));
///   case Err(:final error):
///     emit(state.copyWith(error: error));
/// }
/// ```
@immutable
sealed class Result<T> {
  const new();

  /// Creates a successful [Result] holding [value].
  const factory ok(T value) = Ok<T>;

  /// Creates a failed [Result] holding [error].
  const factory error(Exception error) = Err<T>;
}

/// A successful [Result].
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

/// A failed [Result].
final class Err<T> extends Result<T> {
  const new(this.error);

  final Exception error;

  @override
  bool operator ==(Object other) => other is Err<T> && other.error == error;

  @override
  int get hashCode => Object.hash(Err<T>, error);

  @override
  String toString() => 'Result<$T>.error($error)';
}
