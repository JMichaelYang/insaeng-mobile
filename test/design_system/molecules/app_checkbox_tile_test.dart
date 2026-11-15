import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/molecules/app_checkbox_tile.dart';
import 'package:insaeng/design_system/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group(AppCheckboxTile, () {
    Future<void> pumpTile(WidgetTester tester, AppCheckboxTile tile) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: Center(child: tile)),
        ),
      );
    }

    Checkbox checkbox(WidgetTester tester) => tester.widget<Checkbox>(find.byType(Checkbox));

    testWidgets('shows the title and an unchecked box', (tester) async {
      await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: false, onChanged: (_) {}));

      expect(find.text('Stretch'), findsOneWidget);
      expect(checkbox(tester).value, isFalse);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows a checked box when checked', (tester) async {
      await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: true, onChanged: (_) {}));

      expect(checkbox(tester).value, isTrue);
    });

    testWidgets('shows the subtitle when given', (tester) async {
      await pumpTile(
        tester,
        AppCheckboxTile(title: 'Stretch', subtitle: '10 minutes', checked: false, onChanged: (_) {}),
      );

      expect(find.text('10 minutes'), findsOneWidget);
    });

    for (final checked in [false, true]) {
      testWidgets('reports ${!checked} when tapped while ${checked ? 'checked' : 'unchecked'}', (tester) async {
        final values = <bool>[];
        await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: checked, onChanged: values.add));

        await tester.tap(find.text('Stretch'));
        expect(values, [!checked]);
      });
    }

    testWidgets('shows a spinner and ignores taps while busy', (tester) async {
      final values = <bool>[];
      await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: false, busy: true, onChanged: values.add));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(checkbox(tester).onChanged, isNull);

      await tester.tap(find.text('Stretch'), warnIfMissed: false);
      expect(values, isEmpty);
    });

    testWidgets('is disabled when onChanged is null', (tester) async {
      await pumpTile(tester, const AppCheckboxTile(title: 'Stretch', checked: false, onChanged: null));

      expect(checkbox(tester).onChanged, isNull);
    });
  });
}
