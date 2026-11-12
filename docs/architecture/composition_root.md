# Composition root (`bootstrap.dart`, `config/`, `routing/`)

- This is the only code that knows about concrete implementations, screens, and `getIt`, and it may import any layer.
- Everything else receives its dependencies through constructors.

## Startup and flavors

- `Flavor { dev, prod }` lives in `config/flavor.dart`. Each `main_<flavor>.dart` calls `bootstrap(Flavor.<flavor>)`.
- `bootstrap` initializes the binding, sets `FlutterError.onError`, calls `configureDependencies(flavor)`, and runs `App` with `getIt<GoRouter>()`.
- `configureDependencies` is the only place that branches on the flavor, for example to pick base URLs or fake services.
- To run a flavor, use `fvm flutter run --flavor dev -t lib/main_dev.dart`. Building works the same way with `--flavor prod -t lib/main_prod.dart`.

## Dependency injection (`config/dependencies.dart`)

- DI is manual get_it, with no code generation.
- Register services and repositories with `registerLazySingleton`, keyed by the repository **interface**: `..registerLazySingleton<NotesRepository>(() => NotesRepositoryImpl(getIt()))`.
- Register services before the repositories that use them.
- **Never register cubits.** The route's `BlocProvider` creates each cubit and closes it with the route, so the cubit's lifetime matches the screen and nothing can pull a stray instance out of get_it.

## Routing (`routing/`)

- Each route has a `static const String` path on `Routes` in `routes.dart`, named after the feature in lowerCamelCase.
- `router(getIt)` in `router.dart` builds the `GoRouter`. Each `GoRoute` wraps its screen in a `BlocProvider` that builds the cubit from repositories in get_it.

```dart
GoRoute(
  path: Routes.notes,
  builder: (context, state) => BlocProvider(
    create: (_) => NotesCubit(getIt<NotesRepository>())..load(),
    child: const NotesScreen(),
  ),
),
```
