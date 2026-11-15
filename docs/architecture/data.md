# Data layer (`lib/data/`)

- The data layer implements the repository interfaces from `domain/`. It may import `domain/` and `utils/`, but never `ui/`, `routing/`, `config/`, or the entrypoints.

## Repository implementations (`data/repositories/`)

- `<Model>RepositoryImpl implements <Model>Repository`, with one per type of data. Only the composition root refers to an implementation by name.
- Every method returns a `Result`. Catch service exceptions and convert each one to a subclass of that repository's `<Model>Failure`, so repositories never throw.
- Repositories are the single source of truth for their data. They own caching, mapping service data to domain models, and combining several services.
- A repository may depend on several services, but never on another repository, whether through its interface or its implementation. Logic that combines repositories belongs in a use case.

```dart
final class NoteRepositoryImpl implements NoteRepository {
  new(this._api);

  final NoteApiService _api;

  @override
  Future<Result<List<Note>>> fetchAll() async {
    try {
      final rows = await _api.getNotes();
      return Result.ok(rows.map(NoteMapper.fromMap).toList());
    } on NotFoundException {
      return const Result.err(NoteNotFound());
    } on IOException {
      return const Result.err(NoteOffline());
    }
  }
}
```

## Services (`data/services/`)

- Each service is a stateless wrapper around one external source, such as an HTTP API, local storage, or a platform plugin.
- Services expose thin methods that return raw data or DTOs and let exceptions propagate.
- They contain no business logic, no caching, and no `Result`.
- Services receive their clients, such as an HTTP client or database, through the constructor, so tests can swap them.
