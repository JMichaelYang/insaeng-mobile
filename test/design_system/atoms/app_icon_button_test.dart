import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/atoms/app_icon_button.dart';
import 'package:insaeng/design_system/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group(AppIconButton, () {
    Future<void> pumpButton(WidgetTester tester, AppIconButton button) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: Center(child: button)),
        ),
      );
    }

    IconButton iconButton(WidgetTester tester) => tester.widget<IconButton>(find.byType(IconButton));

    testWidgets('renders an unfilled primary icon button that handles taps', (tester) async {
      var taps = 0;
      await pumpButton(tester, AppIconButton(icon: Icons.edit, label: 'Edit', onPressed: () => taps++));

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(iconButton(tester).color, AppTheme.light.colorScheme.primary);
      expect(iconButton(tester).style, isNull);

      await tester.tap(find.byType(AppIconButton));
      expect(taps, 1);
    });

    testWidgets('uses the label only as its accessibility label', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpButton(tester, AppIconButton(icon: Icons.edit, label: 'Open Claude', onPressed: () {}));

      expect(find.text('Open Claude'), findsNothing);
      expect(iconButton(tester).tooltip, isNull);
      expect(
        tester.getSemantics(find.byType(AppIconButton)),
        matchesSemantics(
          label: 'Open Claude',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('swaps the icon for a primary spinner and ignores taps while loading', (tester) async {
      var taps = 0;
      await pumpButton(
        tester,
        AppIconButton(icon: Icons.edit, label: 'Edit', isLoading: true, onPressed: () => taps++),
      );

      expect(find.byIcon(Icons.edit), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).color,
        AppTheme.light.colorScheme.primary,
      );
      expect(find.bySemanticsLabel('Edit'), findsOneWidget);

      await tester.tap(find.byType(AppIconButton), warnIfMissed: false);
      expect(taps, 0);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await pumpButton(tester, const AppIconButton(icon: Icons.edit, label: 'Edit', onPressed: null));

      expect(iconButton(tester).onPressed, isNull);
    });

    testWidgets('keeps its size while loading', (tester) async {
      await pumpButton(tester, AppIconButton(icon: Icons.edit, label: 'Edit', onPressed: () {}));
      final idleSize = tester.getSize(find.byType(AppIconButton));

      await pumpButton(tester, AppIconButton(icon: Icons.edit, label: 'Edit', isLoading: true, onPressed: () {}));

      expect(tester.getSize(find.byType(AppIconButton)), idleSize);
    });
  });
}
