import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/design_system/theme/theme.dart';
import 'package:insaeng/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meta/meta.dart';

@isTestGroup
void goldenVariantsTest(
  String description, {
  required String fileName,
  required Map<String, Widget> variants,
  int? columns,
  BoxConstraints constraints = const BoxConstraints(maxWidth: 360),
  PumpAction pumpBeforeTest = onlyPumpAndSettle,
}) {
  final runsHere = AlchemistConfig.current().platformGoldensConfig.platforms.contains(HostPlatform.current());
  for (final (themeName, theme) in [('light', AppTheme.light), ('dark', AppTheme.dark)]) {
    unawaited(
      goldenTest(
        '$description in $themeName',
        fileName: '${fileName}_$themeName',
        skip: !runsHere,
        pumpBeforeTest: pumpBeforeTest,
        builder: () => GoldenTestGroup(
          columns: columns,
          scenarioConstraints: constraints,
          children: [
            for (final MapEntry(key: name, value: variant) in variants.entries)
              GoldenTestScenario(
                name: name,
                child: _ThemedVariant(theme: theme, child: variant),
              ),
          ],
        ),
      ),
    );
  }
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
