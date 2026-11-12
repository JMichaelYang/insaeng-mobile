# Design system (`lib/ui/core/`)

`ui/core/` is an atomic design system, and feature screens are assembled from it. Bias toward building reusable, configurable components here rather than one-off widgets inside a feature.

| Level | Folder | Examples |
| --- | --- | --- |
| Tokens | `core/theme/` | `AppTheme`, `AppColors.seed`, `Dimens` |
| Atoms | `core/widgets/atoms/` | `AppButton`, `AppTextField`, `AppAvatar` |
| Molecules | `core/widgets/molecules/` | `AppSearchField`, `AppListTile` |
| Organisms | `core/widgets/organisms/` | `AppEmptyState`, `AppErrorView`, `AppForm` |
| Templates | `core/widgets/templates/` | `AppScaffold`, page layouts with slots |
| Pages | `ui/<feature>/widgets/` | `<Feature>Screen` |

## Rules

- Each level composes only from the levels below it. Atoms style themselves with tokens only.
- Check `ui/core/` before writing a widget. Extend an existing component with a parameter rather than copying it.
- If a widget could appear on a second screen, build it in `ui/core/` from the start. Feature folders keep only widgets bound to that feature's cubit or models.
- Make components configurable through their constructors: content as strings, children, or slots, plus callbacks and sizes. Express variants with an enum rather than piling up booleans.
- Core components never read cubits, repositories, `getIt`, `AppLocalizations`, or domain models. Callers pass in localized strings and plain values.
- Prefix every core component with `App`, and give each one a widget test that covers its variants.

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
