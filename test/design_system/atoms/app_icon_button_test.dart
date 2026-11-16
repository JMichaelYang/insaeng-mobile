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

    testWidgets('renders an IconButton with the icon and handles taps', (tester) async {
      var taps = 0;
      await pumpButton(tester, AppIconButton(icon: Icons.refresh, onPressed: () => taps++));

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.byType(AppIconButton));
      expect(taps, 1);
    });

    testWidgets('shows the tooltip on long press', (tester) async {
      await pumpButton(tester, AppIconButton(icon: Icons.refresh, tooltip: 'Reload', onPressed: () {}));

      await tester.longPress(find.byType(AppIconButton));
      await tester.pumpAndSettle();

      expect(find.text('Reload'), findsOneWidget);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await pumpButton(tester, const AppIconButton(icon: Icons.refresh, onPressed: null));

      expect(tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
    });
  });
}
