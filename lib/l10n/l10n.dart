import 'package:insaeng/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

export 'package:insaeng/l10n/gen/app_localizations.dart';

/// Localization delegates for the app.
///
/// Use this instead of the generated `AppLocalizations.localizationsDelegates`,
/// which wires the legacy `flutter_localizations` Material delegate rather than
/// the one from `material_ui`.
const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
