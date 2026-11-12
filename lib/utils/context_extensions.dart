import 'package:insaeng/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

extension ContextExtensions on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  AppLocalizations get strings => l10n;
}
