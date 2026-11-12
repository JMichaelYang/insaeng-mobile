# UI layer

## State management

- Use a `Cubit` by default. Reach for a `Bloc` only when you need event transformers such as debounce or droppable.
- Each screen gets one cubit, `<Feature>Cubit`, in `ui/<feature>/view_models/`. That file exports its state.
- Cubits take repository interfaces through their constructor, call them, and `switch` on the returned `Result`. They never touch services or Flutter widgets.
- States are immutable dart_mappable classes. Use `copyWith` for the generated value equality.
  - A single `@MappableClass()` with defaults, like `HomeState`, fits screens that only change values.
  - A `sealed` base with one `@MappableClass()` subclass per phase (`Loading`, `Loaded`, `Failed`) fits screens with distinct phases, and gives widgets an exhaustive `switch`.
- Provide the cubit with a `BlocProvider` in the route builder (`routing/router.dart`), never inside the screen. Screens read it with `BlocBuilder`, `BlocListener`, or `context.read`.

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

## Widgets

- Screens are `<Feature>Screen` in `ui/<feature>/widgets/`. Split large builds into small private widget classes rather than helper methods.
- Import `package:material_ui/material_ui.dart`, not `package:flutter/material.dart`.
- Widgets stay dumb. They render state and forward user intents to cubit methods.

## Routing

- Each route has a `static const String` path on `Routes` in `routing/routes.dart`, named after the feature in lowerCamelCase.
- Navigate with `context.go(Routes.x)` or `context.push(Routes.x)`. Never hard-code path strings.
- Route builders in `routing/router.dart` wrap the screen in its `BlocProvider`.

## Theme and strings

- Use Material 3 tokens only: `context.colorScheme`, `context.textTheme`, and `Dimens` for spacing and radii.
- Never hard-code `Color`, `TextStyle`, font sizes, or spacing numbers. `AppColors.seed` is read only by `AppTheme`.
- Every user-facing string goes through `AppLocalizations`, read with `context.strings.<key>`.
- Add each key to both `l10n/arb/app_en.arb` (the template) and `app_ko.arb`, then run `fvm flutter pub get` to regenerate. Never edit `l10n/gen/` by hand.
