import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/l10n/l10n.dart';
import 'package:insaeng/utils/context_extensions.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

void main() {
  group('ContextExtensions', () {
    testWidgets('exposes theme and strings from context', (tester) async {
      late BuildContext context;
      await tester.pumpApp(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );

      expect(context.textTheme, Theme.of(context).textTheme);
      expect(context.colorScheme, Theme.of(context).colorScheme);
      expect(context.strings, AppLocalizations.of(context));
    });
  });
}
