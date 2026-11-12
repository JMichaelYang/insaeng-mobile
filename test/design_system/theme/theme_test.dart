import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/theme/fonts.dart';
import 'package:insaeng/design_system/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group(AppTheme, () {
    for (final (name, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      testWidgets('$name uses ${AppFonts.family} at bundled weights', (
        tester,
      ) async {
        late TextTheme textTheme;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            darkTheme: theme,
            home: Builder(
              builder: (context) {
                textTheme = Theme.of(context).textTheme;
                return const SizedBox();
              },
            ),
          ),
        );

        final styles = [
          textTheme.displayLarge,
          textTheme.displayMedium,
          textTheme.displaySmall,
          textTheme.headlineLarge,
          textTheme.headlineMedium,
          textTheme.headlineSmall,
          textTheme.titleLarge,
          textTheme.titleMedium,
          textTheme.titleSmall,
          textTheme.bodyLarge,
          textTheme.bodyMedium,
          textTheme.bodySmall,
          textTheme.labelLarge,
          textTheme.labelMedium,
          textTheme.labelSmall,
        ];

        for (final style in styles) {
          expect(style?.fontFamily, AppFonts.family);
          expect(
            style?.fontWeight?.value,
            inInclusiveRange(FontWeight.w400.value, FontWeight.w700.value),
          );
        }
      });
    }
  });
}
