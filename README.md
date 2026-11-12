# Insaeng Mobile

My life in a nutshell, on mobile.

## Getting started

The Flutter SDK version is pinned with [FVM](https://fvm.app) in `.fvmrc`.

```sh
fvm install                    # install the pinned Flutter SDK
fvm flutter pub get            # fetch packages (also runs gen-l10n)
fvm dart run build_runner build --delete-conflicting-outputs  # freezed / json_serializable
fvm flutter run                # run the app on a connected device or simulator
```

Generated code (`lib/l10n/gen/`, `*.freezed.dart`, `*.g.dart`) is gitignored and
must come from the tools above — never edit or hand-write it. Strings live in
`lib/l10n/arb/*.arb`; use `fvm dart run build_runner watch` while developing.

## Architecture

Follows the [Flutter app architecture guide](https://docs.flutter.dev/app-architecture/guide)
(MVVM), with a `Cubit` as each screen's view model:

- `lib/bootstrap.dart` / `lib/app.dart` — startup and the root `MaterialApp.router`
- `lib/config/dependencies.dart` — manual `get_it` registration
- `lib/routing/` — `go_router` config; routes provide their screen's cubit
- `lib/ui/core/theme/` — Material 3 theme tokens
- `lib/ui/<feature>/view_models/` + `widgets/` — `lib/ui/home/` is the reference feature
- `lib/utils/result.dart` — sealed `Result<T>` returned by repositories and services

```sh
fvm flutter analyze && fvm flutter test
```
