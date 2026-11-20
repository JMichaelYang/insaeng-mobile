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

    final box = find.byType(IconButton);
    final unchecked = find.byIcon(Icons.check_box_outline_blank);
    final check = find.byIcon(Icons.check_box);
    final cross = find.byIcon(Icons.disabled_by_default);

    Color? iconColor(WidgetTester tester, Finder icon) => IconTheme.of(tester.element(icon)).color;
    ColorScheme colorScheme(WidgetTester tester) => ColorScheme.of(tester.element(box));

    testWidgets('never draws the built-in Checkbox', (tester) async {
      for (final mark in AppCheckboxMark.values) {
        for (final checked in [false, true]) {
          await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: checked, mark: mark, onChanged: (_) {}));

          expect(find.byType(Checkbox), findsNothing);
          expect(box, findsOneWidget);
        }
      }
    });

    testWidgets('shows the title and an unchecked box', (tester) async {
      await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: false, onChanged: (_) {}));

      expect(find.text('Stretch'), findsOneWidget);
      expect(unchecked, findsOneWidget);
      expect(iconColor(tester, unchecked), colorScheme(tester).onSurfaceVariant);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows a primary check when checked', (tester) async {
      await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: true, onChanged: (_) {}));

      expect(check, findsOneWidget);
      expect(unchecked, findsNothing);
      expect(iconColor(tester, check), colorScheme(tester).primary);
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
              hasEnabledState: true,
              isEnabled: true,
              hasTapAction: true,
            ),
          );
          handle.dispose();
        });
      }
    }

    group('with the cross mark', () {
      testWidgets('shows an error-colored cross when checked', (tester) async {
        await pumpTile(
          tester,
          AppCheckboxTile(title: 'Stretch', checked: true, mark: AppCheckboxMark.cross, onChanged: (_) {}),
        );

        expect(cross, findsOneWidget);
        expect(check, findsNothing);
        expect(iconColor(tester, cross), colorScheme(tester).error);
      });

      testWidgets('shows a plain box when unchecked', (tester) async {
        await pumpTile(
          tester,
          AppCheckboxTile(title: 'Stretch', checked: false, mark: AppCheckboxMark.cross, onChanged: (_) {}),
        );

        expect(cross, findsNothing);
        expect(unchecked, findsOneWidget);
      });

      testWidgets('lines up with the check', (tester) async {
        await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: true, onChanged: (_) {}));
        final checkRect = tester.getRect(box);

        await pumpTile(
          tester,
          AppCheckboxTile(title: 'Stretch', checked: true, mark: AppCheckboxMark.cross, onChanged: (_) {}),
        );

        expect(tester.getRect(box), checkRect);
      });
    });

    for (final mark in AppCheckboxMark.values) {
      testWidgets('shows a spinner, greys out the ${mark.name} and ignores taps while busy', (tester) async {
        final values = <bool>[];
        await pumpTile(
          tester,
          AppCheckboxTile(title: 'Stretch', checked: true, busy: true, mark: mark, onChanged: values.add),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(tester.widget<IconButton>(box).onPressed, isNull);
        final icon = mark == AppCheckboxMark.cross ? cross : check;
        expect(iconColor(tester, icon), isSameColorAs(colorScheme(tester).onSurface.withValues(alpha: 0.38)));

        await tester.tap(find.text('Stretch'), warnIfMissed: false);
        await tester.tap(box, warnIfMissed: false);
        expect(values, isEmpty);
      });
    }

    testWidgets('is disabled when onChanged is null', (tester) async {
      await pumpTile(tester, const AppCheckboxTile(title: 'Stretch', checked: false, onChanged: null));

      expect(tester.widget<IconButton>(box).onPressed, isNull);
      expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isFalse);
    });
  });
}
