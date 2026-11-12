# Insaeng Mobile

My life in a nutshell, on mobile.

## Getting started

The Flutter SDK version is pinned with [FVM](https://fvm.app) in `.fvmrc`.

```sh
fvm install                    # install the pinned Flutter SDK
git config core.hooksPath .githooks  # enable the pre-commit fix/format/analyze hook
fvm flutter pub get            # fetch packages (also runs gen-l10n)
fvm dart run build_runner build --delete-conflicting-outputs  # dart_mappable
fvm flutter run                # run the app on a connected device or simulator
```
