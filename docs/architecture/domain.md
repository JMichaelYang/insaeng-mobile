# Domain layer (`lib/domain/`)

- The domain layer is pure Dart and imports only `domain/`.
- Everything here is shared by the data, UI, and composition-root code, so keep it free of I/O and framework types.

## Models (`domain/models/`)

- Models are immutable `@MappableClass()` classes with `const` constructors.
- They hold data and simple derived getters only.
- Run `fvm dart run build_runner build --delete-conflicting-outputs` after any change. The `*.mapper.dart` files are generated and gitignored.

## Repository interfaces (`domain/repositories/`)

- Declare `abstract interface class <Feature>Repository`. Cubits depend on this interface, and `data/` implements it.
- Every method returns `Result<T>` or `Future<Result<T>>`, and none of them throw.

## `Result` and `Failure`

- `Result<T>` in `result.dart` is sealed, with `Ok(value)` and `Err(failure)`. Build one with `Result.ok(value)` or `Result.err(failure)`, and consume it with an exhaustive `switch`.
- `result.dart` re-exports `failure.dart`, so one import covers both.
- Each feature defines a `sealed class <Feature>Failure extends Failure` with `final` subclasses.
- A `switch` on a feature family can be exhaustive. A `switch` on plain `Failure` needs a `_` branch.

```dart
sealed class NotesFailure extends Failure {
  const new();
}

final class NotesNotFound extends NotesFailure {
  const new();
}

final class NotesOffline extends NotesFailure {
  const new();
}

abstract interface class NotesRepository {
  Future<Result<List<Note>>> fetchAll();
}
```
