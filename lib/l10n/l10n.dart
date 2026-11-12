import 'package:insaeng/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

export 'package:insaeng/l10n/gen/app_localizations.dart';

const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
