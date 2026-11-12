# Insaeng Mobile

My life in a nutshell, on mobile.

## Getting started

The Flutter SDK version is pinned with [FVM](https://fvm.app) in `.fvmrc`.

```sh
fvm install                    # install the pinned Flutter SDK
fvm flutter pub get            # fetch packages (also runs gen-l10n)
fvm dart run build_runner build --delete-conflicting-outputs  # dart_mappable
fvm flutter run                # run the app on a connected device or simulator
```

## Architecture

Follows the [Flutter app architecture guide](https://docs.flutter.dev/app-architecture/guide)
(MVVM), with a `Cubit` as each screen's view model:

- `lib/bootstrap.dart` / `lib/app.dart` — startup and the root `MaterialApp.router`
- `lib/config/dependencies.dart` — manual `get_it` registration
- `lib/routing/` — `go_router` config; routes provide their screen's cubit
- `lib/ui/core/theme/` — Material 3 theme tokens
- `lib/ui/<feature>/view_models/` — cubits that hold a screen's state
- `lib/ui/<feature>/widgets/` — screens and widgets that render that state
- `lib/utils/` — `Result<T>` for fallible operations and `BuildContext` helpers

```sh
fvm flutter analyze && fvm flutter test
```
