# UI layer (`lib/ui/`)

- The UI layer depends on `domain/`, `utils/`, `l10n/`, and `Routes`, but never on `data/`, `config/`, or go_router.
- Each feature lives in `ui/<feature>/`, with `view_models/` and `widgets/` subfolders.
- Everything visual that isn't bound to one feature belongs in the `ui/core/` design system, described in [design_system.md](design_system.md). Default to building reusable components there and keep feature widgets thin.

## Cubits and states (`view_models/`)

- Use a `Cubit` by default. Reach for a `Bloc` only when you need event transformers such as debounce or droppable.
- Each screen gets one cubit, `<Feature>Cubit`, and its file exports its state.
- Cubits take repository interfaces or use cases through their constructor and `switch` on the returned `Result`. They never touch services, `getIt`, or widgets.
- States are immutable dart_mappable classes, which gives them `copyWith` and value equality.
  - By default each screen has one `@MappableClass()` state. It holds a `@MappableEnum()` status (`initial`, `loading`, `success`, `failure`), the loaded data, and an optional `Failure`. Content stays on screen during refreshes and inline errors, and there is a single `copyWith`.
  - Use a `sealed` base with one `@MappableClass()` subclass per phase only when the phases share no data, such as an auth gate.

```dart
@MappableEnum()
enum NotesStatus { initial, loading, success, failure }

@MappableClass()
class NotesState with NotesStateMappable {
  const new({
    this.status = NotesStatus.initial,
    this.notes = const [],
    this.failure,
  });

  final NotesStatus status;
  final List<Note> notes;
  final Failure? failure;
}

class NotesCubit extends Cubit<NotesState> {
  new(this._repository) : super(const NotesState());

  final NoteRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: NotesStatus.loading));
    emit(switch (await _repository.fetchAll()) {
      Ok(:final value) => state.copyWith(
        status: NotesStatus.success,
        notes: value,
        failure: null,
      ),
      Err(:final failure) => state.copyWith(
        status: NotesStatus.failure,
        failure: failure,
      ),
    });
  }
}
```

## Screens (`widgets/`)

- Screens are named `<Feature>Screen` and get their cubit from the route's `BlocProvider`. They read it with `BlocBuilder`, `BlocListener`, or `context.read`.
- Widgets render state and forward user intents to cubit methods. Split large builds into small private widget classes rather than helper methods.
- Import `package:material_ui/material_ui.dart`, not `package:flutter/material.dart`.
- Navigate with `context.goTo(Routes.x)`, `context.pushTo(Routes.x)`, and `context.back()` from `utils/navigation_extensions.dart`. Never import go_router here, and never hard-code path strings.

## Theme and strings

- Use Material 3 tokens only: `context.colorScheme`, `context.textTheme`, and `Dimens` for spacing and radii.
- Never hard-code `Color`, `TextStyle`, font sizes, or spacing numbers. `AppColors.seed` is read only by `AppTheme`.
- Every user-facing string goes through `AppLocalizations`, read with `context.strings.<key>`.
- Add each key to both `l10n/arb/app_en.arb` (the template) and `app_ko.arb`, then run `fvm flutter pub get` to regenerate. Never edit `l10n/gen/` by hand.
