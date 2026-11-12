# Architecture overview

MVVM in three layers wired by a composition root.

| Doc | Covers |
| --- | --- |
| [domain.md](domain.md) | `lib/domain/`: models, repository interfaces, `Result`, `Failure` |
| [data.md](data.md) | `lib/data/`: repository implementations and services |
| [ui.md](ui.md) | `lib/ui/`: cubits, states, screens, theme, and strings |
| [composition_root.md](composition_root.md) | `bootstrap.dart`, `config/`, `routing/`: DI, flavors, and routes |
| [testing.md](testing.md) | `test/`: layout, mocks, cubit tests, and widget tests |

## Layers and the dependency rule

- **UI → repositories → services.** Cubits call repositories, repositories call services, and nothing calls upward.
- `domain/` is pure Dart and imports only `domain/`. Every other layer may import it.
- `ui/` depends on repository **interfaces** from `domain/` and never imports `data/` or `config/`.
- `data/` implements those interfaces and never imports `ui/`, `routing/`, `config/`, or the entrypoints.
- `utils/` holds small helpers and never imports `data/`, `ui/`, `routing/`, or `config/`.
- The composition root (`bootstrap.dart`, `config/`, `routing/`) is the only code that brings implementations and screens together.
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

1. **Domain:** add models, a sealed `<Feature>Failure` family, and the `<Feature>Repository` interface.
2. **Data:** add any new service, then `<Feature>RepositoryImpl`.
3. **UI:** add `<feature>_state.dart` and `<feature>_cubit.dart`, then `<feature>_screen.dart`, and put strings in both ARB files.
4. **Composition root:** register the service and repository, add the path to `Routes`, and add a `GoRoute` whose `BlocProvider` builds the cubit.
5. Run `fvm dart run build_runner build --delete-conflicting-outputs`.
6. Add tests under the mirrored `test/` paths, then run `fvm dart format .`, `fvm flutter analyze`, and `fvm flutter test`.
