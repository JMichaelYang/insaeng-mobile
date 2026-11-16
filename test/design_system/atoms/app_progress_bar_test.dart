import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/atoms/app_progress_bar.dart';
import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/design_system/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group(AppProgressBar, () {
    Future<void> pumpBar(WidgetTester tester, double value) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(children: [AppProgressBar(value: value)]),
        ),
      ),
    );

    LinearProgressIndicator indicator(WidgetTester tester) =>
        tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));

    testWidgets('fills the available width with a determinate bar', (tester) async {
      await pumpBar(tester, 0.4);

      expect(indicator(tester).value, 0.4);
      expect(indicator(tester).minHeight, Dimens.progressHeight);
      expect(tester.getSize(find.byType(AppProgressBar)).width, tester.getSize(find.byType(Scaffold)).width);
    });

    for (final (input, expected) in [(-1.0, 0.0), (2.0, 1.0), (double.nan, 0.0), (double.infinity, 0.0)]) {
      testWidgets('clamps $input to $expected', (tester) async {
        await pumpBar(tester, input);

        expect(indicator(tester).value, expected);
      });
    }

    testWidgets('uses the primary color on a surface container track', (tester) async {
      await pumpBar(tester, 0.5);
      final colors = AppTheme.light.colorScheme;

      expect(indicator(tester).color, colors.primary);
      expect(indicator(tester).backgroundColor, colors.surfaceContainerHighest);
    });
  });
}
