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

    const icons = {IconToken.edit: Icons.edit};

    for (final MapEntry(key: token, value: icon) in icons.entries) {
      testWidgets('maps the ${token.name} icon to its Material icon', (tester) async {
        await pumpItem(tester, IconButtonNode(id: 'open', icon: Literal(token), label: const Literal('Open')));

        expect(button(tester).icon, icon);
      });
    }

    testWidgets('passes the label and is not loading by default', (tester) async {
      await pumpItem(tester, const IconButtonNode(id: 'open', icon: Literal(IconToken.edit), label: Literal('Open')));

      expect(button(tester).label, 'Open');
      expect(button(tester).isLoading, isFalse);
    });

    testWidgets('resolves bound icon, label, and loading from the values', (tester) async {
      await pumpItem(
        tester,
        const IconButtonNode(
          id: 'refresh',
          icon: Binding('icon', fallback: IconToken.edit),
          label: Binding('label'),
          loading: Binding('refreshing'),
        ),
        values: {'label': 'Refresh', 'refreshing': true},
      );

      expect(button(tester).icon, Icons.edit);
      expect(button(tester).label, 'Refresh');
      expect(button(tester).isLoading, isTrue);
    });

    testWidgets('dispatches its onTap actions when tapped', (tester) async {
      const onTap = [UpdateStateAction(path: 'opened', value: Literal(true))];
      await pumpItem(
        tester,
        const IconButtonNode(id: 'open', icon: Literal(IconToken.edit), label: Literal('Open'), onTap: onTap),
      );

      await tester.tap(find.byType(AppIconButton));

      verify(() => cubit.dispatch(onTap)).called(1);
    });

    testWidgets('does not dispatch while loading', (tester) async {
      await pumpItem(
        tester,
        const IconButtonNode(
          id: 'open',
          icon: Literal(IconToken.edit),
          label: Literal('Open'),
          loading: Literal(true),
          onTap: [BackAction()],
        ),
      );

      await tester.tap(find.byType(AppIconButton), warnIfMissed: false);

      verifyNever(() => cubit.dispatch(any()));
    });
  });
}
