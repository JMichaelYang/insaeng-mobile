import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/molecules/app_day_picker.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/day_picker_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

void main() {
  group(DayPickerItem, () {
    late GenericCubit cubit;

    setUp(() {
      cubit = _MockGenericCubit();
      when(() => cubit.dispatch(any())).thenAnswer((_) async {});
    });

    Future<void> pumpItem(WidgetTester tester, DayPickerNode node, {Map<String, Object?> values = const {}}) {
      when(() => cubit.state).thenReturn(GenericState(status: GenericStatus.success, values: GenericValues(values)));
      return tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: Scaffold(body: DayPickerItem(node: node)),
        ),
      );
    }

    AppDayPicker picker(WidgetTester tester) => tester.widget<AppDayPicker>(find.byType(AppDayPicker));

    testWidgets('passes its literal labels', (tester) async {
      await pumpItem(
        tester,
        const DayPickerNode(
          id: 'day',
          label: Literal('Mon, Jan 12'),
          previousLabel: Literal('Previous day'),
          nextLabel: Literal('Next day'),
        ),
      );

      expect(picker(tester).label, 'Mon, Jan 12');
      expect(picker(tester).previousLabel, 'Previous day');
      expect(picker(tester).nextLabel, 'Next day');
    });

    testWidgets('resolves bound labels from the values', (tester) async {
      await pumpItem(
        tester,
        const DayPickerNode(
          id: 'day',
          label: Binding('day.label'),
          previousLabel: Binding('day.previous'),
          nextLabel: Binding('day.next', fallback: 'Next'),
        ),
        values: {
          'day': {'label': 'Tue, Jan 13', 'previous': 'Previous'},
        },
      );

      expect(picker(tester).label, 'Tue, Jan 13');
      expect(picker(tester).previousLabel, 'Previous');
      expect(picker(tester).nextLabel, 'Next');
    });

    testWidgets('dispatches onPrevious and onNext from their chevrons', (tester) async {
      const onPrevious = [UpdateStateAction(path: 'offset', op: Literal(UpdateOp.increment), value: Literal(-1))];
      const onNext = [UpdateStateAction(path: 'offset', op: Literal(UpdateOp.increment))];
      await pumpItem(
        tester,
        const DayPickerNode(
          id: 'day',
          label: Literal('Mon, Jan 12'),
          previousLabel: Literal('Previous day'),
          nextLabel: Literal('Next day'),
          onPrevious: onPrevious,
          onNext: onNext,
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_left));
      verify(() => cubit.dispatch(onPrevious)).called(1);

      await tester.tap(find.byIcon(Icons.chevron_right));
      verify(() => cubit.dispatch(onNext)).called(1);
    });

    testWidgets('dispatches onLabelTap from the label with its resolved hint', (tester) async {
      const onLabelTap = [UpdateStateAction(path: 'offset', value: Literal(0))];
      await pumpItem(
        tester,
        const DayPickerNode(
          id: 'day',
          label: Literal('Mon, Jan 12'),
          previousLabel: Literal('Previous day'),
          nextLabel: Literal('Next day'),
          labelTapHint: Binding('day.hint'),
          onLabelTap: onLabelTap,
        ),
        values: {
          'day': {'hint': 'Go to today'},
        },
      );

      expect(picker(tester).labelTapHint, 'Go to today');

      await tester.tap(find.text('Mon, Jan 12'));
      verify(() => cubit.dispatch(onLabelTap)).called(1);
    });

    testWidgets('leaves the label untappable when onLabelTap is empty', (tester) async {
      await pumpItem(
        tester,
        const DayPickerNode(
          id: 'day',
          label: Literal('Mon, Jan 12'),
          previousLabel: Literal('Previous day'),
          nextLabel: Literal('Next day'),
          labelTapHint: Literal('Go to today'),
        ),
      );

      expect(picker(tester).onLabelTap, isNull);

      await tester.tap(find.text('Mon, Jan 12'));
      verifyNever(() => cubit.dispatch(any()));
    });

    testWidgets('disables a chevron whose action list is empty', (tester) async {
      const onNext = [UpdateStateAction(path: 'offset', op: Literal(UpdateOp.increment))];
      await pumpItem(
        tester,
        const DayPickerNode(
          id: 'day',
          label: Literal('Mon, Jan 12'),
          previousLabel: Literal('Previous day'),
          nextLabel: Literal('Next day'),
          onNext: onNext,
        ),
      );

      expect(picker(tester).onPrevious, isNull);
      expect(picker(tester).onNext, isNotNull);

      await tester.tap(find.byIcon(Icons.chevron_left));
      verifyNever(() => cubit.dispatch(any()));
    });
  });
}
