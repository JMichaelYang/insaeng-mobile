# Insaeng Mobile

My life in a nutshell.

## Getting started

The Flutter SDK version is pinned with [FVM](https://fvm.app) in `.fvmrc`.

```sh
fvm install                    # install the pinned Flutter SDK
git config core.hooksPath .githooks  # enable the pre-commit fix/format/analyze hook
fvm flutter pub get            # fetch packages (also runs gen-l10n)
fvm dart run build_runner build --delete-conflicting-outputs  # dart_mappable
fvm flutter run --flavor dev -t lib/main_dev.dart  # run the app on a connected device or simulator
```

## Flavors

| Flavor | Entrypoint           | Application / bundle ID | Display name |
| ------ | -------------------- | ----------------------- | ------------ |
| `dev`  | `lib/main_dev.dart`  | `com.jae.insaeng.dev`   | insaeng dev  |
| `prod` | `lib/main_prod.dart` | `com.jae.insaeng`       | insaeng      |

Both flavors install side by side. Pass `--flavor <f> -t lib/main_<f>.dart` to `run` and `build`.

## Icons and splash

The artwork lives in `assets/branding/`, set in Pretendard Bold with the web palette. Each flavor has a `flutter_launcher_icons-<f>.yaml` and a `flutter_native_splash-<f>.yaml`. After changing the artwork or configs, regenerate the native resources:

```sh
fvm dart run flutter_launcher_icons
fvm dart run flutter_native_splash:create --all-flavors
```

The splash generator also rewrites `ios/Runner/Info.plist`. Revert that change and keep `UILaunchStoryboardName` set to `$(LAUNCH_SCREEN_STORYBOARD)`; each Xcode build configuration sets `LAUNCH_SCREEN_STORYBOARD` and `ASSETCATALOG_COMPILER_APPICON_NAME` for its flavor.
