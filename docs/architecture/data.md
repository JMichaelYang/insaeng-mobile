# Data layer (`lib/data/`)

- The data layer implements the repository interfaces from `domain/`. It may import `domain/` and `utils/`, but never `ui/`, `routing/`, `config/`, or the entrypoints.

## Repository implementations (`data/repositories/`)

- `<Feature>RepositoryImpl implements <Feature>Repository`, and only the composition root refers to it by name.
- Every method returns a `Result`. Catch service exceptions and convert each one to that feature's `Failure` subclass, so repositories never throw.
- Repositories are the single source of truth for their data. They own caching, mapping service data to domain models, and combining several services.
- A repository may depend on several services, but never on another repository's implementation.

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

## Services (`data/services/`)

- Each service is a stateless wrapper around one external source, such as an HTTP API, local storage, or a platform plugin.
- Services expose thin methods that return raw data or DTOs and let exceptions propagate.
- They contain no business logic, no caching, and no `Result`.
- Services receive their clients, such as an HTTP client or database, through the constructor, so tests can swap them.
