# Domain layer (`lib/domain/`)

- The domain layer is pure Dart and imports only `domain/`.
- Everything here is shared by the data, UI, and composition-root code, so keep it free of I/O and framework types.

## Models (`domain/models/`)

- Models are immutable `@MappableClass()` classes with `const` constructors.
- They hold data and simple derived getters only.
- Run `fvm dart run build_runner build --delete-conflicting-outputs` after any change. The `*.mapper.dart` files are generated and gitignored.

## Repository interfaces (`domain/repositories/`)

- Each type of data gets one repository, named after its model, as in `abstract interface class NoteRepository`. Never name a repository after a feature or screen.
- Every method returns `Result<T>` or `Future<Result<T>>`, and none of them throw.
- Cubits and use cases depend on these interfaces, and `data/` implements them.

## Use cases (`domain/use_cases/`)

- Add a use case only when logic combines several repositories, or when several cubits share the same multi-step logic. Otherwise cubits call repositories directly.
- Name each one `<Verb><Noun>UseCase`. It does one action through a single `call` method that returns `Future<Result<T>>`.
- Use cases are stateless and depend only on repository interfaces.

## `Result` and `Failure`

- `Result<T>` in `result.dart` is sealed, with `Ok(value)` and `Err(failure)`. Build one with `Result.ok(value)` or `Result.err(failure)`, and consume it with an exhaustive `switch`.
- `result.dart` re-exports `failure.dart`, so one import covers both.
- Each repository defines a `sealed class <Model>Failure extends Failure` with `final` subclasses.
- A `switch` on one family can be exhaustive. A `switch` on plain `Failure`, such as one passed through by a use case, needs a `_` branch.

```dart
sealed class NoteFailure extends Failure {
  const new();
}

final class NoteNotFound extends NoteFailure {
  const new();
}

final class NoteOffline extends NoteFailure {
  const new();
}

abstract interface class NoteRepository {
  Future<Result<List<Note>>> fetchAll();
}

class LoadFeedUseCase {
  new(this._notes, this._users);

  final NoteRepository _notes;
  final UserRepository _users;

  Future<Result<Feed>> call() async {
    switch (await _users.current()) {
      case Err(:final failure):
        return Result.err(failure);
      case Ok(value: final user):
        return switch (await _notes.fetchAll()) {
          Ok(value: final notes) => Result.ok(Feed.forUser(user, notes)),
          Err(:final failure) => Result.err(failure),
        };
    }
  }
}
```
