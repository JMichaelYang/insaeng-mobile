import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/theme/theme.dart';
import 'package:insaeng/design_system/theme/theme_extensions.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('ThemeExtensions', () {
    testWidgets('exposes the text theme and color scheme', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(context.textTheme, Theme.of(context).textTheme);
      expect(context.colorScheme, Theme.of(context).colorScheme);
      expect(context.colorScheme, AppTheme.light.colorScheme);
    });
  });
}
