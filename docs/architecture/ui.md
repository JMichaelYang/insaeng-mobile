# UI layer (`lib/ui/`)

- The UI layer depends on `domain/`, `utils/`, `l10n/`, and `Routes`, but never on `data/` or `config/`.
- Each feature lives in `ui/<feature>/`, with `view_models/` and `widgets/` subfolders. Shared pieces go in `ui/core/`.

## Cubits and states (`view_models/`)

- Use a `Cubit` by default. Reach for a `Bloc` only when you need event transformers such as debounce or droppable.
- Each screen gets one cubit, `<Feature>Cubit`, and its file exports its state.
- Cubits take repository interfaces through their constructor and `switch` on the returned `Result`. They never touch services, `getIt`, or widgets.
- States are immutable dart_mappable classes, which gives them `copyWith` and value equality.
  - A single `@MappableClass()` with defaults, like `HomeState`, fits screens that only change values.
  - A `sealed` base with one `@MappableClass()` subclass per phase fits screens with distinct phases, and gives widgets an exhaustive `switch`.

```dart
@MappableClass()
sealed class NotesState with NotesStateMappable {
  const new();
}

@MappableClass()
final class NotesLoading extends NotesState with NotesLoadingMappable {
  const new();
}

@MappableClass()
final class NotesLoaded extends NotesState with NotesLoadedMappable {
  const new(this.notes);
  final List<Note> notes;
}

@MappableClass()
final class NotesFailed extends NotesState with NotesFailedMappable {
  const new(this.failure);
  final Failure failure;
}

class NotesCubit extends Cubit<NotesState> {
  new(this._repository) : super(const NotesLoading());

  final NotesRepository _repository;

  Future<void> load() async {
    emit(const NotesLoading());
    emit(switch (await _repository.fetchAll()) {
      Ok(:final value) => NotesLoaded(value),
      Err(:final failure) => NotesFailed(failure),
    });
  }
}
```

## Screens (`widgets/`)

- Screens are named `<Feature>Screen` and get their cubit from the route's `BlocProvider`. They read it with `BlocBuilder`, `BlocListener`, or `context.read`.
- Widgets render state and forward user intents to cubit methods. Split large builds into small private widget classes rather than helper methods.
- Import `package:material_ui/material_ui.dart`, not `package:flutter/material.dart`.
- Navigate with `context.go(Routes.x)` or `context.push(Routes.x)`. Never hard-code path strings.

## Theme and strings

- Use Material 3 tokens only: `context.colorScheme`, `context.textTheme`, and `Dimens` for spacing and radii.
- Never hard-code `Color`, `TextStyle`, font sizes, or spacing numbers. `AppColors.seed` is read only by `AppTheme`.
- Every user-facing string goes through `AppLocalizations`, read with `context.strings.<key>`.
- Add each key to both `l10n/arb/app_en.arb` (the template) and `app_ko.arb`, then run `fvm flutter pub get` to regenerate. Never edit `l10n/gen/` by hand.
