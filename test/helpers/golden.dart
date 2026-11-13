import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/design_system/theme/theme.dart';
import 'package:insaeng/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meta/meta.dart';

const _obscuredFontFamily = 'Ahem';

@isTestGroup
void goldenVariantsTest(
  String description, {
  required String fileName,
  required Map<String, Widget> variants,
  int? columns,
  BoxConstraints constraints = const BoxConstraints(maxWidth: 360),
}) {
  final config = AlchemistConfig.current();
  final platformConfig = config.platformGoldensConfig;
  final runsPlatform = platformConfig.enabled && platformConfig.platforms.contains(HostPlatform.current());
  final platformOnly = config.copyWith(ciGoldensConfig: config.ciGoldensConfig.copyWith(enabled: false));
  final frame = config.goldenTestTheme ?? GoldenTestTheme.standard();
  final ciOnly = config.copyWith(
    platformGoldensConfig: config.platformGoldensConfig.copyWith(enabled: false),
    goldenTestTheme: GoldenTestTheme(
      backgroundColor: frame.backgroundColor,
      borderColor: frame.borderColor,
      padding: frame.padding,
      nameTextStyle: frame.nameTextStyle.copyWith(fontFamily: _obscuredFontFamily, letterSpacing: 0),
    ),
  );

  for (final (themeName, theme) in [('light', AppTheme.light), ('dark', AppTheme.dark)]) {
    final runs = [
      if (runsPlatform) (platformOnly, theme),
      if (config.ciGoldensConfig.enabled) (ciOnly, _obscureFonts(theme)),
    ];
    for (final (variantConfig, variantTheme) in runs) {
      AlchemistConfig.runWithConfig(
        config: variantConfig,
        run: () => unawaited(
          goldenTest(
            '$description in $themeName',
            fileName: '${fileName}_$themeName',
            builder: () => GoldenTestGroup(
              columns: columns,
              scenarioConstraints: constraints,
              children: [
                for (final MapEntry(key: name, value: variant) in variants.entries)
                  GoldenTestScenario(
                    name: name,
                    child: _ThemedVariant(theme: variantTheme, child: variant),
                  ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

ThemeData _obscureFonts(ThemeData theme) {
  return theme.copyWith(
    textTheme: _obscureTextTheme(theme.textTheme),
    primaryTextTheme: _obscureTextTheme(theme.primaryTextTheme),
  );
}

TextTheme _obscureTextTheme(TextTheme textTheme) {
  TextStyle? obscure(TextStyle? style) => style?.copyWith(fontFamily: _obscuredFontFamily, letterSpacing: 0);
  return textTheme.copyWith(
    displayLarge: obscure(textTheme.displayLarge),
    displayMedium: obscure(textTheme.displayMedium),
    displaySmall: obscure(textTheme.displaySmall),
    headlineLarge: obscure(textTheme.headlineLarge),
    headlineMedium: obscure(textTheme.headlineMedium),
    headlineSmall: obscure(textTheme.headlineSmall),
    titleLarge: obscure(textTheme.titleLarge),
    titleMedium: obscure(textTheme.titleMedium),
    titleSmall: obscure(textTheme.titleSmall),
    bodyLarge: obscure(textTheme.bodyLarge),
    bodyMedium: obscure(textTheme.bodyMedium),
    bodySmall: obscure(textTheme.bodySmall),
    labelLarge: obscure(textTheme.labelLarge),
    labelMedium: obscure(textTheme.labelMedium),
    labelSmall: obscure(textTheme.labelSmall),
  );
}

class _ThemedVariant extends StatelessWidget {
  const new({required this.theme, required this.child});

  final ThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en'),
      delegates: localizationsDelegates,
      child: Theme(
        data: theme,
        child: Material(
          color: theme.colorScheme.surface,
          child: Padding(padding: const EdgeInsets.all(Dimens.spaceMd), child: child),
        ),
      ),
    );
  }
}
