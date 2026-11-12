import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget, {Locale locale = const Locale('en')}) {
    return pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: widget,
      ),
    );
  }
}
