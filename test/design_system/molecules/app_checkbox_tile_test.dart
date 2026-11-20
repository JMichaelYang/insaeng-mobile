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

    testWidgets('shows the emoji before the title and the box after it', (tester) async {
      await pumpTile(tester, AppCheckboxTile(title: 'Stretch', emoji: '🧘', checked: false, onChanged: (_) {}));

      final emoji = tester.getCenter(find.text('🧘')).dx;
      final title = tester.getCenter(find.text('Stretch')).dx;
      final box = tester.getCenter(find.byType(Checkbox)).dx;
      expect(emoji, lessThan(title));
      expect(title, lessThan(box));
    });

    testWidgets('shows no emoji when none is given', (tester) async {
      await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: false, onChanged: (_) {}));

      expect(find.byType(Text), findsOneWidget);
    });

    for (final checked in [false, true]) {
      testWidgets('reports ${!checked} when the box is tapped while ${checked ? 'checked' : 'unchecked'}', (
        tester,
      ) async {
        final values = <bool>[];
        await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: checked, onChanged: values.add));

        await tester.tap(find.byType(Checkbox));
        expect(values, [!checked]);
      });

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
      await tester.tap(find.byType(Checkbox), warnIfMissed: false);
      expect(values, isEmpty);
    });

    group('with the cross mark', () {
      Finder cross() => find.byIcon(Icons.disabled_by_default);

      testWidgets('shows an error-colored cross and no box when checked', (tester) async {
        await pumpTile(
          tester,
          AppCheckboxTile(title: 'Stretch', checked: true, mark: AppCheckboxMark.cross, onChanged: (_) {}),
        );

        expect(find.byType(Checkbox), findsNothing);
        expect(cross(), findsOneWidget);
        final context = tester.element(cross());
        expect(IconTheme.of(context).color, ColorScheme.of(context).error);
      });

      testWidgets('shows a plain box when unchecked', (tester) async {
        await pumpTile(
          tester,
          AppCheckboxTile(title: 'Stretch', checked: false, mark: AppCheckboxMark.cross, onChanged: (_) {}),
        );

        expect(cross(), findsNothing);
        expect(checkbox(tester).value, isFalse);
      });

      testWidgets('lines up with the box', (tester) async {
        await pumpTile(tester, AppCheckboxTile(title: 'Stretch', checked: true, onChanged: (_) {}));
        final box = tester.getRect(find.byType(Checkbox));

        await pumpTile(
          tester,
          AppCheckboxTile(title: 'Stretch', checked: true, mark: AppCheckboxMark.cross, onChanged: (_) {}),
        );

        expect(tester.getRect(find.byType(IconButton)), box);
      });

      testWidgets('reports false when the cross is tapped', (tester) async {
        final values = <bool>[];
        await pumpTile(
          tester,
          AppCheckboxTile(title: 'Stretch', checked: true, mark: AppCheckboxMark.cross, onChanged: values.add),
        );

        await tester.tap(cross());
        await tester.tap(find.text('Stretch'));
        expect(values, [false, false]);
      });

      testWidgets('reads as a checked box', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpTile(
          tester,
          AppCheckboxTile(title: 'Stretch', checked: true, mark: AppCheckboxMark.cross, onChanged: (_) {}),
        );

        expect(
          tester.getSemantics(find.byType(ListTile)),
          isSemantics(label: 'Stretch', hasCheckedState: true, isChecked: true, isEnabled: true, hasTapAction: true),
        );
        handle.dispose();
      });

      testWidgets('shows a spinner, greys out the cross and ignores taps while busy', (tester) async {
        final values = <bool>[];
        await pumpTile(
          tester,
          AppCheckboxTile(
            title: 'Stretch',
            checked: true,
            busy: true,
            mark: AppCheckboxMark.cross,
            onChanged: values.add,
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
        final context = tester.element(cross());
        expect(IconTheme.of(context).color, isSameColorAs(ColorScheme.of(context).onSurface.withValues(alpha: 0.38)));

        await tester.tap(cross(), warnIfMissed: false);
        await tester.tap(find.text('Stretch'), warnIfMissed: false);
        expect(values, isEmpty);
      });
    });

    testWidgets('is disabled when onChanged is null', (tester) async {
      await pumpTile(tester, const AppCheckboxTile(title: 'Stretch', checked: false, onChanged: null));

      expect(checkbox(tester).onChanged, isNull);
      expect(tester.widget<ListTile>(find.byType(ListTile)).enabled, isFalse);
    });
  });
}
