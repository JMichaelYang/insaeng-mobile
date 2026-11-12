# Testing (`test/`)

- `test/` mirrors `lib/`, so `lib/ui/notes/view_models/notes_cubit.dart` is tested in `test/ui/notes/view_models/notes_cubit_test.dart`.
- Name groups after the type under test, as in `group(NotesCubit, () { ... })`.
- Mock with mocktail, using private mock classes: `class _MockNotesRepository extends Mock implements NotesRepository {}`.

## By layer

- **Domain:** use plain unit tests for model logic and `Result` and `Failure` behavior.
- **Data:** mock the services and cover both the `Ok` path and each exception-to-`Failure` conversion.
- **UI cubits:** use `blocTest` with mocked repository interfaces and assert on the emitted states.
- **UI widgets:** put a `MockCubit<State>` behind `BlocProvider.value` and pump with `tester.pumpApp` from `test/helpers/pump_app.dart`. It wires the l10n delegates.
- **Composition root:** tests that call `configureDependencies` call `tearDown(getIt.reset)`.

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
