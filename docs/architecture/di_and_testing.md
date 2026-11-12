# Dependency injection and testing

## Dependency injection

- DI is manual get_it in `config/dependencies.dart`, with no code generation. `bootstrap` calls `configureDependencies(flavor)` once.
- Register services and repositories with `registerLazySingleton`, keyed by the repository **interface**: `..registerLazySingleton<NotesRepository>(() => NotesRepositoryImpl(getIt()))`.
- Register services before the repositories that use them. Branch on `flavor` here and nowhere else.
- **Never register cubits.** Route builders create them through `BlocProvider(create: (_) => NotesCubit(getIt<NotesRepository>()))`, so each cubit lives exactly as long as its route.
- Only the composition root (`bootstrap.dart`, `config/`, `routing/`) reads `getIt`. Every other class takes its dependencies through its constructor.

## Tests

- `test/` mirrors `lib/`, so `lib/ui/notes/view_models/notes_cubit.dart` is tested in `test/ui/notes/view_models/notes_cubit_test.dart`.
- Name groups after the type under test, as in `group(NotesCubit, () { ... })`.
- Mock with mocktail, using private mock classes: `class _MockNotesRepository extends Mock implements NotesRepository {}`.
- **Cubit tests** use `blocTest` with a mocked repository and assert on the emitted states.
- **Repository tests** mock the services and cover both the `Ok` path and each exception-to-`Failure` conversion.
- **Widget tests** use `MockCubit<State>` behind `BlocProvider.value` and pump with `tester.pumpApp` from `test/helpers/pump_app.dart`. It wires the l10n delegates, and you pass `locale: Locale('ko')` to check the Korean strings.
- Tests that call `configureDependencies` call `tearDown(getIt.reset)`.

```dart
class _MockNotesRepository extends Mock implements NotesRepository {}

void main() {
  group(NotesCubit, () {
    late NotesRepository repository;

    setUp(() => repository = _MockNotesRepository());

    blocTest<NotesCubit, NotesState>(
      'load emits loaded notes',
      setUp: () => when(() => repository.fetchAll())
          .thenAnswer((_) async => const Result.ok([Note(title: 'a')])),
      build: () => NotesCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => const [NotesLoading(), NotesLoaded([Note(title: 'a')])],
    );
  });
}
```
