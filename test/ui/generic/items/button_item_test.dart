import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/atoms/app_button.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/button_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

void main() {
  group(ButtonItem, () {
    late GenericCubit cubit;

    setUp(() {
      cubit = _MockGenericCubit();
      when(() => cubit.dispatch(any())).thenAnswer((_) async {});
    });

    Future<void> pumpItem(WidgetTester tester, ButtonNode node, {Map<String, Object?> values = const {}}) {
      when(() => cubit.state).thenReturn(GenericState(status: GenericStatus.success, values: GenericValues(values)));
      return tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: Scaffold(
            body: Center(child: ButtonItem(node: node)),
          ),
        ),
      );
    }

    AppButton button(WidgetTester tester) => tester.widget<AppButton>(find.byType(AppButton));

    testWidgets('shows a primary button with the label', (tester) async {
      await pumpItem(tester, const ButtonNode(id: 'add', label: Literal('Add')));

      expect(find.text('Add'), findsOneWidget);
      expect(button(tester).variant, AppButtonVariant.primary);
      expect(button(tester).isLoading, isFalse);
    });

    const variants = {
      ButtonVariant.primary: AppButtonVariant.primary,
      ButtonVariant.secondary: AppButtonVariant.secondary,
      ButtonVariant.text: AppButtonVariant.text,
    };

    for (final MapEntry(key: variant, value: appVariant) in variants.entries) {
      testWidgets('maps the ${variant.name} variant to $appVariant', (tester) async {
        await pumpItem(tester, ButtonNode(id: 'add', label: const Literal('Add'), variant: Literal(variant)));

        expect(button(tester).variant, appVariant);
      });
    }

    testWidgets('resolves bound label and loading from the values', (tester) async {
      await pumpItem(
        tester,
        const ButtonNode(id: 'submit', label: Binding('label'), loading: Binding('submitting')),
        values: {'label': 'Log in', 'submitting': true},
      );

      expect(find.text('Log in'), findsOneWidget);
      expect(button(tester).isLoading, isTrue);
    });

    testWidgets('dispatches its onTap actions when tapped', (tester) async {
      const onTap = [UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment))];
      await pumpItem(tester, const ButtonNode(id: 'add', label: Literal('Add'), onTap: onTap));

      await tester.tap(find.byType(AppButton));

      verify(() => cubit.dispatch(onTap)).called(1);
    });

    testWidgets('does not dispatch while loading', (tester) async {
      await pumpItem(
        tester,
        const ButtonNode(id: 'add', label: Literal('Add'), loading: Literal(true), onTap: [BackAction()]),
      );

      await tester.tap(find.byType(AppButton), warnIfMissed: false);

      verifyNever(() => cubit.dispatch(any()));
    });
  });
}
