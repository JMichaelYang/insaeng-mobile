# Testing (`test/`)

- `test/` mirrors `lib/`, so `lib/ui/notes/view_models/notes_cubit.dart` is tested in `test/ui/notes/view_models/notes_cubit_test.dart`.
- Name groups after the type under test, as in `group(NotesCubit, () { ... })`.
- Mock with mocktail, using private mock classes: `class _MockNoteRepository extends Mock implements NoteRepository {}`.

## By layer

- **Domain:** use plain unit tests for models, `Result`, and `Failure`. Test use cases against mocked repository interfaces.
- **Data:** mock the services and cover both the `Ok` path and each exception-to-`Failure` conversion.
- **UI cubits:** use `blocTest` with mocked repositories or use cases, and assert on the emitted states.
- **UI widgets:** put a `MockCubit<State>` behind `BlocProvider.value` and pump with `tester.pumpApp` from `test/helpers/pump_app.dart`. It wires the l10n delegates.
- **Composition root:** tests that call `configureDependencies` call `tearDown(getIt.reset)`.

```dart
class _MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  group(NotesCubit, () {
    late NoteRepository repository;

    setUp(() => repository = _MockNoteRepository());

    blocTest<NotesCubit, NotesState>(
      'load emits loading, then the loaded notes',
      setUp: () => when(() => repository.fetchAll())
          .thenAnswer((_) async => const Result.ok([Note(title: 'a')])),
      build: () => NotesCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => const [
        NotesState(status: NotesStatus.loading),
        NotesState(status: NotesStatus.success, notes: [Note(title: 'a')]),
      ],
    );
  });
}
```
