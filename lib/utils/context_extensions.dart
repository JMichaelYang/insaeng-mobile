import 'package:insaeng/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

extension ContextExtensions on BuildContext {
  AppLocalizations get strings => l10n;
}
