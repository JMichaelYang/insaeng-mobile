# Architecture overview

MVVM in three layers wired by a composition root.

| Doc | Covers |
| --- | --- |
| [domain.md](domain.md) | `lib/domain/`: models, repository interfaces, use cases, `Result`, `Failure` |
| [data.md](data.md) | `lib/data/`: repository implementations and services |
| [ui.md](ui.md) | `lib/ui/`: cubits, states, screens, theme, and strings |
| [design_system.md](design_system.md) | `lib/design_system/`: tokens and atomic components |
| [composition_root.md](composition_root.md) | `bootstrap.dart`, `config/`, `routing/`: DI, flavors, and routes |
| [testing.md](testing.md) | `test/`: layout, mocks, cubit tests, and widget tests |
| [generic_ui.md](generic_ui.md) | The generic UI contract: pages, nodes, bindings, and actions |

## Layers and the dependency rule

- **UI → use cases (optional) → repositories → services.** Cubits call repositories directly, or call a use case when logic spans repositories. Repositories call services.
- Nothing calls upward, and repositories never call each other.
- Each repository is scoped to one type of data and named after its model, as in `NoteRepository`. Screens and cubits are named after features, as in `NotesCubit`.
- `domain/` is pure Dart and imports only `domain/`. Every other layer may import it.
- `ui/` depends on repository **interfaces** and use cases from `domain/`, and never imports `data/`, `config/`, or go_router.
- `data/` implements those interfaces and never imports `ui/`, `design_system/`, `routing/`, `config/`, or the entrypoints.
- `design_system/` is self-contained: it imports only itself and outside packages. Only `ui/` and `app.dart` import it.
- `utils/` is app-agnostic: it holds extensions on SDK, Flutter, and package types, and imports only `utils/` and `l10n/`.
- Helpers for app types never go in `utils/`. Put derived logic on the model in `domain/`, presentation such as `Failure` → message in `ui/`, and mapping in `data/`.
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
    repositories/                abstract repository interfaces, one per model
    use_cases/                   cross-repository logic, one action per class
    result.dart, failure.dart
  data/
    repositories/                repository implementations
    services/                    stateless wrappers over APIs, storage, platform
  design_system/
    theme/                       tokens: AppTheme, AppColors.seed, Dimens, ThemeExtensions
    atoms/, molecules/, organisms/, templates/
  ui/
    <feature>/view_models/       <feature>_cubit.dart, <feature>_state.dart
    <feature>/widgets/           <feature>_screen.dart and private parts
  l10n/arb/                      app_en.arb (template), app_ko.arb
  utils/                         strings and navigation extensions on BuildContext
test/                            mirrors lib/, plus helpers/
```

## Add a feature checklist

1. **Domain:** for each new type of data, add its model, a sealed `<Model>Failure` family, and a `<Model>Repository` interface. Add a use case only if logic spans repositories.
2. **Data:** add any new service, then `<Model>RepositoryImpl`.
3. **UI:** reuse or add `design_system/` components, add `<feature>_state.dart` and `<feature>_cubit.dart`, then `<feature>_screen.dart`, and put strings in both ARB files.
4. **Composition root:** register the new services, repositories, and use cases, add the path to `Routes`, and add a `GoRoute` whose `BlocProvider` builds the cubit.
5. Run `fvm dart run build_runner build --delete-conflicting-outputs`.
6. Add tests under the mirrored `test/` paths, then run `fvm dart format .`, `fvm flutter analyze`, and `fvm flutter test`.
