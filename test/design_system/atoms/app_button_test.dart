import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/atoms/app_button.dart';
import 'package:insaeng/design_system/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group(AppButton, () {
    Future<void> pumpButton(WidgetTester tester, AppButton button) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: Center(child: button)),
        ),
      );
    }

    const variants = {
      AppButtonVariant.primary: FilledButton,
      AppButtonVariant.secondary: OutlinedButton,
      AppButtonVariant.text: TextButton,
    };

    for (final MapEntry(key: variant, value: buttonType) in variants.entries) {
      testWidgets('${variant.name} renders a $buttonType that shows the label and handles taps', (tester) async {
        var taps = 0;
        await pumpButton(tester, AppButton(label: 'Save', variant: variant, onPressed: () => taps++));

        expect(find.byType(buttonType), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.tap(find.byType(AppButton));
        expect(taps, 1);
      });

      testWidgets('${variant.name} shows a spinner and ignores taps while loading', (tester) async {
        var taps = 0;
        await pumpButton(tester, AppButton(label: 'Save', variant: variant, isLoading: true, onPressed: () => taps++));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
        expect(tester.widget<ButtonStyleButton>(find.byType(buttonType)).enabled, isFalse);

        await tester.tap(find.byType(AppButton), warnIfMissed: false);
        expect(taps, 0);
      });
    }

    testWidgets('defaults to the primary variant', (tester) async {
      await pumpButton(tester, AppButton(label: 'Save', onPressed: () {}));

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await pumpButton(tester, const AppButton(label: 'Save', onPressed: null));

      expect(tester.widget<FilledButton>(find.byType(FilledButton)).enabled, isFalse);
    });

    testWidgets('keeps its size while loading', (tester) async {
      await pumpButton(tester, AppButton(label: 'Save changes', onPressed: () {}));
      final idleSize = tester.getSize(find.byType(AppButton));

      await pumpButton(tester, AppButton(label: 'Save changes', isLoading: true, onPressed: () {}));

      expect(tester.getSize(find.byType(AppButton)), idleSize);
    });
  });
}
