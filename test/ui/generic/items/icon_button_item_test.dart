import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/atoms/app_icon_button.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/icon_button_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

void main() {
  group(IconButtonItem, () {
    late GenericCubit cubit;

    setUp(() {
      cubit = _MockGenericCubit();
      when(() => cubit.dispatch(any())).thenAnswer((_) async {});
    });

    Future<void> pumpItem(WidgetTester tester, IconButtonNode node, {Map<String, Object?> values = const {}}) {
      when(() => cubit.state).thenReturn(GenericState(status: GenericStatus.success, values: GenericValues(values)));
      return tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: Scaffold(
            body: Center(child: IconButtonItem(node: node)),
          ),
        ),
      );
    }

    AppIconButton button(WidgetTester tester) => tester.widget<AppIconButton>(find.byType(AppIconButton));

    testWidgets('shows the refresh icon without a tooltip by default', (tester) async {
      await pumpItem(tester, const IconButtonNode(id: 'reload', icon: Literal(IconButtonIcon.refresh)));

      expect(button(tester).icon, Icons.refresh);
      expect(button(tester).tooltip, isNull);
    });

    testWidgets('resolves a bound label as the tooltip', (tester) async {
      await pumpItem(
        tester,
        const IconButtonNode(id: 'reload', icon: Literal(IconButtonIcon.refresh), label: Binding('label')),
        values: {'label': 'Reload'},
      );

      expect(button(tester).tooltip, 'Reload');
    });

    testWidgets('dispatches its onTap actions when tapped', (tester) async {
      const onTap = [ReloadAction()];
      await pumpItem(tester, const IconButtonNode(id: 'reload', icon: Literal(IconButtonIcon.refresh), onTap: onTap));

      await tester.tap(find.byType(AppIconButton));

      verify(() => cubit.dispatch(onTap)).called(1);
    });
  });
}
