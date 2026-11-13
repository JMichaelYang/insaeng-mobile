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
- **Design system:** every `design_system/` component gets a widget test and a golden test. See [Golden tests](#golden-tests).

## Golden tests

Golden tests use [alchemist](https://pub.dev/packages/alchemist), configured once in `test/flutter_test_config.dart`.

- Write them with `goldenVariantsTest` from `test/helpers/golden.dart`. It renders each named variant on its own `AppTheme` surface in both light and dark themes, with Pretendard loaded. It writes one image per theme.
- Name the file `<component>_golden_test.dart`, next to the component's widget test, and cover every variant and state in the map.
- Each test writes two kinds of goldens next to the test file:
  - `goldens/ci/`: platform-agnostic. Text is laid out in the bundled Pretendard but drawn as solid blocks, and shadows are off, so these images match on macOS and on the Ubuntu CI runner. CI compares only these.
  - `goldens/macos/`: real Pretendard text, meant for people reading diffs. They are compared only on macOS machines outside CI, because font rasterization differs between platforms.
- `TolerantGoldenComparator` treats a pixel as unchanged when every channel is within `channelTolerance` of the golden. This absorbs anti-aliasing differences between machines, while any real visual change still fails.
- Commit both folders. Failed comparisons write diffs to `failures/`, which is gitignored and uploaded as the `golden-failures` artifact when CI fails.
- After a deliberate visual change, regenerate the goldens with `fvm flutter test --update-goldens --tags golden`, then review the changed images before committing.

```dart
void main() {
  goldenVariantsTest(
    'AppButton',
    fileName: 'app_button',
    variants: {
      'primary': AppButton(label: 'Save', onPressed: () {}),
      'secondary': AppButton(label: 'Save', onPressed: () {}, variant: AppButtonVariant.secondary),
      'disabled': const AppButton(label: 'Save', onPressed: null),
    },
  );
}
```

```dart
class _MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  group(NotesCubit, () {
    late NoteRepository repository;

    setUp(() => repository = _MockNoteRepository());

    blocTest<NotesCubit, NotesState>(
      'load emits the loaded notes',
      setUp: () => when(() => repository.fetchAll())
          .thenAnswer((_) async => const Result.ok([Note(title: 'a')])),
      build: () => NotesCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => const [
        NotesState(status: NotesStatus.success, notes: [Note(title: 'a')]),
      ],
    );
  });
}
```
