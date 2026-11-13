# Design system (`lib/design_system/`)

`design_system/` is a self-contained atomic design system, and feature screens in `ui/` are assembled from it. Bias toward building reusable, configurable components here rather than one-off widgets inside a feature.

| Level | Folder | Examples |
| --- | --- | --- |
| Tokens | `design_system/theme/` | `AppTheme`, `AppColors.seed`, `AppFonts.family`, `Dimens` |
| Atoms | `design_system/atoms/` | `AppButton`, `AppTextField`, `AppAvatar` |
| Molecules | `design_system/molecules/` | `AppSearchField`, `AppListTile` |
| Organisms | `design_system/organisms/` | `AppEmptyState`, `AppErrorView`, `AppForm` |
| Templates | `design_system/templates/` | `AppScaffold`, page layouts with slots |
| Pages | `ui/<feature>/widgets/` | `<Feature>Screen` |

## Rules

- `design_system/` imports only itself and outside packages, never another app folder, `flutter_bloc`, `get_it`, or `go_router`.
- Only `ui/` and `app.dart` import it, and `layer_lint` enforces both rules.
- Each level composes only from the levels below it. Atoms style themselves with tokens only, read through `context.colorScheme` and `context.textTheme` from `theme/theme_extensions.dart` plus `Dimens`.
- Check `design_system/` before writing a widget. Extend an existing component with a parameter rather than copying it.
- If a widget could appear on a second screen, build it in `design_system/` from the start. Feature folders keep only widgets bound to that feature's cubit or models.
- Make components configurable through their constructors: content as strings, children, or slots, plus callbacks and sizes. Express variants with an enum rather than piling up booleans.
- Callers pass in localized strings and plain values. Components never take domain models.
- Prefix every component with `App`, and give each one a widget test that covers its variants.
- Every `design_system/` component also gets a golden test that renders each variant in light and dark themes with `goldenVariantsTest`. See [testing.md](testing.md#golden-tests) for the update command.

## Typography

- The app font is Pretendard, bundled from `assets/fonts/pretendard/` and set once as `AppFonts.family` in `AppTheme`. Its OFL license is registered in `bootstrap.dart`.
- Style text only with `context.textTheme` styles. Adjust them with `copyWith` for weight or color, never `fontFamily`.
- Only weights 400 to 700 are bundled, so use `FontWeight.w400` through `FontWeight.w700`. Bundle a new weight in `pubspec.yaml` before using it.

```dart
enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final child = Text(label);
    return switch (variant) {
      AppButtonVariant.primary => FilledButton(onPressed: onPressed, child: child),
      AppButtonVariant.secondary => OutlinedButton(onPressed: onPressed, child: child),
      AppButtonVariant.text => TextButton(onPressed: onPressed, child: child),
    };
  }
}
```
