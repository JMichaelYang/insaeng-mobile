import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/design_system/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/golden.dart';

void main() {
  goldenVariantsTest(
    'AppTheme text styles',
    fileName: 'app_theme_text_styles',
    columns: 3,
    variants: {
      'displayLarge': _TextSample((t) => t.displayLarge),
      'displayMedium': _TextSample((t) => t.displayMedium),
      'displaySmall': _TextSample((t) => t.displaySmall),
      'headlineLarge': _TextSample((t) => t.headlineLarge),
      'headlineMedium': _TextSample((t) => t.headlineMedium),
      'headlineSmall': _TextSample((t) => t.headlineSmall),
      'titleLarge': _TextSample((t) => t.titleLarge),
      'titleMedium': _TextSample((t) => t.titleMedium),
      'titleSmall': _TextSample((t) => t.titleSmall),
      'bodyLarge': _TextSample((t) => t.bodyLarge),
      'bodyMedium': _TextSample((t) => t.bodyMedium),
      'bodySmall': _TextSample((t) => t.bodySmall),
      'labelLarge': _TextSample((t) => t.labelLarge),
      'labelMedium': _TextSample((t) => t.labelMedium),
      'labelSmall': _TextSample((t) => t.labelSmall),
    },
  );

  goldenVariantsTest(
    'AppTheme color roles',
    fileName: 'app_theme_color_roles',
    columns: 3,
    constraints: const BoxConstraints.tightFor(width: 200),
    variants: {
      'primary': _ColorSample((c) => (c.primary, c.onPrimary)),
      'primaryContainer': _ColorSample((c) => (c.primaryContainer, c.onPrimaryContainer)),
      'secondary': _ColorSample((c) => (c.secondary, c.onSecondary)),
      'secondaryContainer': _ColorSample((c) => (c.secondaryContainer, c.onSecondaryContainer)),
      'tertiary': _ColorSample((c) => (c.tertiary, c.onTertiary)),
      'tertiaryContainer': _ColorSample((c) => (c.tertiaryContainer, c.onTertiaryContainer)),
      'error': _ColorSample((c) => (c.error, c.onError)),
      'errorContainer': _ColorSample((c) => (c.errorContainer, c.onErrorContainer)),
      'surfaceContainer': _ColorSample((c) => (c.surfaceContainer, c.onSurface)),
    },
  );
}

class _TextSample extends StatelessWidget {
  const new(this.select);

  final TextStyle? Function(TextTheme) select;

  @override
  Widget build(BuildContext context) => Text('인생 Aa 123', style: select(context.textTheme));
}

class _ColorSample extends StatelessWidget {
  const new(this.select);

  final (Color, Color) Function(ColorScheme) select;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = select(context.colorScheme);
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(Dimens.radiusMd)),
      child: Padding(
        padding: const EdgeInsets.all(Dimens.spaceMd),
        child: Text('인생 Aa', style: context.textTheme.titleMedium?.copyWith(color: foreground)),
      ),
    );
  }
}
