import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/atoms/app_button.dart';
import 'package:insaeng/design_system/organisms/app_error_view.dart';
import 'package:insaeng/design_system/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group(AppErrorView, () {
    Future<void> pumpView(WidgetTester tester, AppErrorView view) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: Center(child: view)),
        ),
      );
    }

    testWidgets('shows the message and a retry button that handles taps', (tester) async {
      var retries = 0;
      await pumpView(
        tester,
        AppErrorView(message: 'Something went wrong.', retryLabel: 'Try again', onRetry: () => retries++),
      );

      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('disables the retry button when onRetry is null', (tester) async {
      await pumpView(
        tester,
        const AppErrorView(message: 'Something went wrong.', retryLabel: 'Try again', onRetry: null),
      );

      expect(tester.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);
    });
  });
}
