# Architecture overview

MVVM in three layers. Read this first, then [ui.md](ui.md), [data.md](data.md), and [di_and_testing.md](di_and_testing.md). `ui/home/` is the reference feature.

## Layers and the dependency rule

- **UI → repositories → services.** Cubits call repositories, repositories call services, and nothing calls upward.
- `domain/` is shared by every layer: models, repository interfaces, `Result<T>`, and `Failure`. It is pure Dart with no Flutter imports.
- `ui/` depends on repository **interfaces** in `domain/`, never on `data/`.
- `data/` implements those interfaces and never imports `ui/`, `routing/`, or `config/`.
- `config/` and `routing/` are the composition root. They are the only places that bring implementations and screens together.
- The `layer_lint` analyzer plugin in `tools/layer_lint/` enforces these rules, so `fvm flutter analyze` reports a `layer_boundary` warning for any violation.

## Folder map

```
lib/
  main_dev.dart, main_prod.dart  entrypoints, one per flavor
  bootstrap.dart                 binding, error handler, DI, runApp
  app.dart                       MaterialApp.router, theme, l10n
  config/                        flavor.dart, dependencies.dart (get_it)
  routing/                       routes.dart (paths), router.dart (GoRouter)
  domain/
    models/                      immutable @MappableClass entities
    repositories/                abstract repository interfaces
    result.dart, failure.dart
  data/
    repositories/                repository implementations
    services/                    stateless wrappers over APIs, storage, platform
  ui/
    core/theme/                  AppTheme, AppColors.seed, Dimens
    core/widgets/                widgets shared by several features
    <feature>/view_models/       <feature>_cubit.dart, <feature>_state.dart
    <feature>/widgets/           <feature>_screen.dart and private parts
  l10n/arb/                      app_en.arb (template), app_ko.arb
  utils/                         BuildContext extensions and helpers
test/                            mirrors lib/, plus helpers/
```

## Add a feature checklist

1. Add models to `domain/models/` and a sealed `Failure` family for the feature.
2. Declare `<Feature>Repository` in `domain/repositories/`, with every method returning `Future<Result<T>>`.
3. Add any new service to `data/services/` and `<Feature>RepositoryImpl` to `data/repositories/`.
4. Register the service and repository as lazy singletons in `config/dependencies.dart`.
5. Add `<feature>_state.dart` and `<feature>_cubit.dart` under `ui/<feature>/view_models/`.
6. Add `<feature>_screen.dart` under `ui/<feature>/widgets/`.
7. Add the path to `Routes`, then add a `GoRoute` whose `BlocProvider` builds the cubit with `getIt<...Repository>()`.
8. Add every new string to both `app_en.arb` and `app_ko.arb`.
9. Run `fvm dart run build_runner build --delete-conflicting-outputs`.
10. Add tests under the mirrored `test/` paths, then run `fvm dart format .`, `fvm flutter analyze`, and `fvm flutter test`.

## Flavors

- `Flavor { dev, prod }` lives in `config/flavor.dart`. Each `main_<flavor>.dart` calls `bootstrap(Flavor.<flavor>)`.
- `configureDependencies(flavor)` registers the `Flavor` and is the only place that branches on it, for example to pick base URLs or fake services. UI code never checks the flavor.
- To run a flavor, use `fvm flutter run --flavor dev -t lib/main_dev.dart`. Building works the same way with `--flavor prod -t lib/main_prod.dart`.
