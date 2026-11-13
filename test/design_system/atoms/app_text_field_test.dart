import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/atoms/app_text_field.dart';
import 'package:insaeng/design_system/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group(AppTextField, () {
    Future<void> pumpField(WidgetTester tester, AppTextField field) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: Center(child: field)),
        ),
      );
    }

    TextEditingController controller(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller!;

    testWidgets('shows the label and the initial value', (tester) async {
      await pumpField(tester, const AppTextField(label: 'Name', value: 'Ada'));

      expect(find.text('Name'), findsOneWidget);
      expect(controller(tester).text, 'Ada');
    });

    testWidgets('shows the hint while empty and focused', (tester) async {
      await pumpField(tester, const AppTextField(label: 'Name', hint: 'Enter your name'));

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(find.text('Enter your name'), findsOneWidget);
    });

    testWidgets('reports changes and submissions', (tester) async {
      final changes = <String>[];
      final submissions = <String>[];
      await pumpField(tester, AppTextField(onChanged: changes.add, onSubmitted: submissions.add));

      await tester.enterText(find.byType(TextField), 'Ada');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(changes, ['Ada']);
      expect(submissions, ['Ada']);
    });

    testWidgets('replaces its text when the value changes', (tester) async {
      await pumpField(tester, const AppTextField(value: 'Ada'));

      await pumpField(tester, const AppTextField(value: 'Grace'));

      expect(controller(tester).text, 'Grace');
      expect(controller(tester).selection, const TextSelection.collapsed(offset: 5));
    });

    testWidgets('keeps the cursor when the value matches what was typed', (tester) async {
      await pumpField(tester, const AppTextField(value: ''));
      await tester.enterText(find.byType(TextField), 'Ada');
      controller(tester).selection = const TextSelection.collapsed(offset: 1);

      await pumpField(tester, const AppTextField(value: 'Ada'));

      expect(controller(tester).text, 'Ada');
      expect(controller(tester).selection, const TextSelection.collapsed(offset: 1));
    });

    testWidgets('keeps typed text when it has no value', (tester) async {
      await pumpField(tester, const AppTextField());
      await tester.enterText(find.byType(TextField), 'Ada');

      await pumpField(tester, const AppTextField(label: 'Name'));

      expect(controller(tester).text, 'Ada');
    });
  });
}
