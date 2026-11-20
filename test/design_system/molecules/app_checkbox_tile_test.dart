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

    final box = find.byType(Checkbox);
    Checkbox checkbox(WidgetTester tester) => tester.widget<Checkbox>(box);
    CheckboxThemeData checkboxTheme(WidgetTester tester) => CheckboxTheme.of(tester.element(box));
    ColorScheme colorScheme(WidgetTester tester) => ColorScheme.of(tester.element(box));

    testWidgets('shows the title and an unchecked box', (tester) async {
      await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: false, onChanged: (_) {}));

      expect(find.text('Stretch'), findsOneWidget);
      expect(checkbox(tester).value, isFalse);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows a checked box when checked', (tester) async {
      await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: true, onChanged: (_) {}));

      expect(checkbox(tester).value, isTrue);
      expect(checkbox(tester).tristate, isFalse);
    });

    testWidgets('shows the subtitle when given', (tester) async {
      await pumpTile(
        tester,
        AppCheckboxTile(title: 'Stretch', subtitle: '10 minutes', checked: false, onChanged: (_) {}),
      );

      expect(find.text('10 minutes'), findsOneWidget);
    });

    testWidgets('shows the emoji before the title and the box after it', (tester) async {
      await pumpTile(tester, AppCheckboxTile(title: 'Stretch', emoji: '🧘', checked: false, onChanged: (_) {}));

      final emoji = tester.getCenter(find.text('🧘')).dx;
      final title = tester.getCenter(find.text('Stretch')).dx;
      expect(emoji, lessThan(title));
      expect(title, lessThan(tester.getCenter(box).dx));
    });

    testWidgets('shows no emoji when none is given', (tester) async {
      await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: false, onChanged: (_) {}));

      expect(find.byType(Text), findsOneWidget);
    });

    for (final mark in AppCheckboxMark.values) {
      for (final checked in [false, true]) {
        final state = '${checked ? 'checked' : 'unchecked'} with the ${mark.name} mark';

        testWidgets('reports ${!checked} when the box is tapped while $state', (tester) async {
          final values = <bool>[];
          await pumpTile(
            tester,
            AppCheckboxTile(title: 'Stretch', checked: checked, mark: mark, onChanged: values.add),
          );

          await tester.tap(box);
          expect(values, [!checked]);
        });

        testWidgets('reports ${!checked} when tapped while $state', (tester) async {
          final values = <bool>[];
          await pumpTile(
            tester,
            AppCheckboxTile(title: 'Stretch', checked: checked, mark: mark, onChanged: values.add),
          );

          await tester.tap(find.text('Stretch'));
          expect(values, [!checked]);
        });

        testWidgets('reads as a ${checked ? 'checked' : 'unchecked'} box while $state', (tester) async {
          final handle = tester.ensureSemantics();
          await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: checked, mark: mark, onChanged: (_) {}));

          expect(
            tester.getSemantics(find.byType(ListTile)),
            isSemantics(
              label: 'Stretch',
              hasCheckedState: true,
              isChecked: checked,
              isCheckStateMixed: false,
              hasEnabledState: true,
              isEnabled: true,
              hasTapAction: true,
            ),
          );
          handle.dispose();
        });
      }
    }

    group('with the dash mark', () {
      testWidgets('shows an error-filled dash when checked', (tester) async {
        await pumpTile(
          tester,
          AppCheckboxTile(title: 'Stretch', checked: true, mark: AppCheckboxMark.dash, onChanged: (_) {}),
        );

        expect(box, findsOneWidget);
        expect(checkbox(tester).tristate, isTrue);
        expect(checkbox(tester).value, isNull);
        expect(checkboxTheme(tester).fillColor?.resolve({WidgetState.selected}), colorScheme(tester).error);
        expect(checkboxTheme(tester).checkColor?.resolve({WidgetState.selected}), colorScheme(tester).onError);
      });

      testWidgets('shows a plain box when unchecked', (tester) async {
        await pumpTile(
          tester,
          AppCheckboxTile(title: 'Stretch', checked: false, mark: AppCheckboxMark.dash, onChanged: (_) {}),
        );

        expect(checkbox(tester).value, isFalse);
        expect(checkbox(tester).tristate, isFalse);
        expect(checkboxTheme(tester).fillColor?.resolve({WidgetState.selected}), isNot(colorScheme(tester).error));
      });

      testWidgets('lines up with the check', (tester) async {
        await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: true, onChanged: (_) {}));
        final checkRect = tester.getRect(box);

        await pumpTile(
          tester,
          AppCheckboxTile(title: 'Stretch', checked: true, mark: AppCheckboxMark.dash, onChanged: (_) {}),
        );

        expect(tester.getRect(box), checkRect);
      });

      testWidgets('falls back to the disabled colors while busy', (tester) async {
        await pumpTile(
          tester,
          AppCheckboxTile(title: 'Stretch', checked: true, busy: true, mark: AppCheckboxMark.dash, onChanged: (_) {}),
        );

        const disabled = {WidgetState.selected, WidgetState.disabled};
        expect(checkboxTheme(tester).fillColor?.resolve(disabled), isNull);
        expect(checkboxTheme(tester).checkColor?.resolve(disabled), isNull);
      });
    });

    for (final mark in AppCheckboxMark.values) {
      testWidgets('shows a spinner and ignores taps while busy with the ${mark.name} mark', (tester) async {
        final values = <bool>[];
        await pumpTile(
          tester,
          AppCheckboxTile(title: 'Stretch', checked: true, busy: true, mark: mark, onChanged: values.add),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(checkbox(tester).onChanged, isNull);

        await tester.tap(find.text('Stretch'), warnIfMissed: false);
        await tester.tap(box, warnIfMissed: false);
        expect(values, isEmpty);
      });
    }

    testWidgets('is disabled when onChanged is null', (tester) async {
      await pumpTile(tester, const AppCheckboxTile(title: 'Stretch', checked: false, onChanged: null));

      expect(checkbox(tester).onChanged, isNull);
      expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isFalse);
    });
  });
}
