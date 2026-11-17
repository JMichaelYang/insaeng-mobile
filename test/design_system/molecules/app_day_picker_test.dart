import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/atoms/app_icon_button.dart';
import 'package:insaeng/design_system/molecules/app_day_picker.dart';
import 'package:insaeng/design_system/theme/theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group(AppDayPicker, () {
    Future<void> pumpPicker(WidgetTester tester, AppDayPicker picker) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: Center(child: picker)),
        ),
      );
    }

    AppIconButton chevron(WidgetTester tester, IconData icon) =>
        tester.widget<AppIconButton>(find.ancestor(of: find.byIcon(icon), matching: find.byType(AppIconButton)));

    testWidgets('shows the label between a previous and a next chevron', (tester) async {
      await pumpPicker(
        tester,
        AppDayPicker(
          label: 'Mon, Jan 12',
          previousLabel: 'Previous day',
          nextLabel: 'Next day',
          onPrevious: () {},
          onNext: () {},
        ),
      );

      final label = find.text('Mon, Jan 12');
      expect(label, findsOneWidget);
      expect(tester.widget<Text>(label).style, TextTheme.of(tester.element(label)).titleMedium);
      expect(chevron(tester, Icons.chevron_left).label, 'Previous day');
      expect(chevron(tester, Icons.chevron_right).label, 'Next day');
      expect(tester.getCenter(find.byIcon(Icons.chevron_left)).dx, lessThan(tester.getCenter(label).dx));
      expect(tester.getCenter(find.byIcon(Icons.chevron_right)).dx, greaterThan(tester.getCenter(label).dx));
    });

    testWidgets('calls onPrevious and onNext from their chevrons', (tester) async {
      var previous = 0;
      var next = 0;
      await pumpPicker(
        tester,
        AppDayPicker(
          label: 'Mon, Jan 12',
          previousLabel: 'Previous day',
          nextLabel: 'Next day',
          onPrevious: () => previous++,
          onNext: () => next++,
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_left));
      expect((previous, next), (1, 0));

      await tester.tap(find.byIcon(Icons.chevron_right));
      expect((previous, next), (1, 1));
    });

    testWidgets('disables a chevron whose callback is null', (tester) async {
      await pumpPicker(
        tester,
        AppDayPicker(
          label: 'Mon, Jan 12',
          previousLabel: 'Previous day',
          nextLabel: 'Next day',
          onPrevious: null,
          onNext: () {},
        ),
      );

      expect(chevron(tester, Icons.chevron_left).onPressed, isNull);
      expect(chevron(tester, Icons.chevron_right).onPressed, isNotNull);
    });

    testWidgets('fills the width and keeps the chevrons in place for any label', (tester) async {
      await pumpPicker(
        tester,
        AppDayPicker(
          label: 'Mon, Jan 12',
          previousLabel: 'Previous',
          nextLabel: 'Next',
          onPrevious: () {},
          onNext: () {},
        ),
      );
      final short = (
        tester.getCenter(find.byIcon(Icons.chevron_left)),
        tester.getCenter(find.byIcon(Icons.chevron_right)),
      );

      await pumpPicker(
        tester,
        AppDayPicker(
          label: 'Wednesday, September 30',
          previousLabel: 'Previous',
          nextLabel: 'Next',
          onPrevious: () {},
          onNext: () {},
        ),
      );

      expect(
        tester.getSize(find.byType(AppDayPicker)).width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      );
      expect((
        tester.getCenter(find.byIcon(Icons.chevron_left)),
        tester.getCenter(find.byIcon(Icons.chevron_right)),
      ), short);
    });

    testWidgets('truncates a label too long for one line', (tester) async {
      await pumpPicker(
        tester,
        AppDayPicker(
          label: 'Wednesday, September 30 ' * 5,
          previousLabel: 'Previous',
          nextLabel: 'Next',
          onPrevious: () {},
          onNext: () {},
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });
  });
}
