# Data layer

## Models (`domain/models/`)

- Models are immutable `@MappableClass()` classes in pure Dart, shared by every layer.
- They hold data and simple derived getters only, with no I/O.
- Run `fvm dart run build_runner build --delete-conflicting-outputs` after any change. The `*.mapper.dart` files are generated and gitignored.

## Repositories

- Declare the interface `abstract interface class <Feature>Repository` in `domain/repositories/`. The implementation, `<Feature>RepositoryImpl`, goes in `data/repositories/`.
- Every public method returns `Result<T>` or `Future<Result<T>>`, built with `Result.ok(value)` or `Result.err(failure)`.
- Repositories never throw. They catch service exceptions and convert them to a `Failure`.
- Each feature defines a `sealed class <Feature>Failure extends Failure` with `final` subclasses such as `NotesNotFound` and `NotesOffline`, so callers can `switch` exhaustively.
- Repositories are the single source of truth for their data. They own caching, mapping service data to domain models, and combining several services.
- A repository may depend on several services, but never on another repository's implementation.

## Services (`data/services/`)

- Each service is a stateless wrapper around one external source, such as an HTTP API, local storage, or a platform plugin.
- Services expose thin methods that return raw data or DTOs and let exceptions propagate.
- They contain no business logic, no caching, and no `Result`.
- Services receive their clients, such as an HTTP client or database, through the constructor, so tests can swap them.

```dart
final class NotesRepositoryImpl implements NotesRepository {
  new(this._api);

  final NotesApiService _api;

  @override
  Future<Result<List<Note>>> fetchAll() async {
    try {
      final rows = await _api.getNotes();
      return Result.ok(rows.map(NoteMapper.fromMap).toList());
    } on NotFoundException {
      return const Result.err(NotesNotFound());
    } on IOException {
      return const Result.err(NotesOffline());
    }
  }
}
```
