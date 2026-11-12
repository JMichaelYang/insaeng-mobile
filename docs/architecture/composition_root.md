# Composition root (`bootstrap.dart`, `config/`, `routing/`)

- This is the only code that knows about concrete implementations, screens, and `getIt`, and it may import any layer.
- Everything else receives its dependencies through constructors.

## Flavors

- `configureDependencies` is the only place that branches on the flavor, for example to pick base URLs or fake services.

## Dependency injection (`config/dependencies.dart`)

- DI is manual get_it, with no code generation.
- Register services, repositories, and use cases with `registerLazySingleton`. Key repositories by their **interface**: `..registerLazySingleton<NoteRepository>(() => NoteRepositoryImpl(getIt()))`.
- Order registrations by role, following the dependency direction: infrastructure such as clients and databases first, then services, repositories, and use cases. Within each role, sort alphabetically.
- **Never register cubits.** The route's `BlocProvider` creates each cubit and closes it with the route, so the cubit's lifetime matches the screen and nothing can pull a stray instance out of get_it.

## Routing (`routing/`)

- Each route has a `static const String` path on `Routes` in `routes.dart`, named after the feature in lowerCamelCase.
- `router(getIt)` in `router.dart` builds the `GoRouter`. Each `GoRoute` wraps its screen in a `BlocProvider` that builds the cubit from repositories and use cases in get_it.
- Only `routing/` and `utils/navigation_extensions.dart` import go_router, so swapping the router touches nothing else.

```dart
GoRoute(
  path: Routes.notes,
  builder: (context, state) => BlocProvider(
    create: (_) => NotesCubit(getIt<NoteRepository>())..load(),
    child: const NotesScreen(),
  ),
),
```
