import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/app_bar_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

void main() {
  group(AppBarItem, () {
    late GenericCubit cubit;

    setUp(() {
      cubit = _MockGenericCubit();
      when(() => cubit.dispatch(any())).thenAnswer((_) async {});
    });

    Future<void> pumpItem(WidgetTester tester, AppBarNode node, {GenericValues? values}) {
      when(() => cubit.state)
          .thenReturn(GenericState(status: GenericStatus.success, values: values ?? GenericValues()));
      return tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: Scaffold(body: AppBarItem(node: node)),
        ),
      );
    }

    testWidgets('shows a literal title', (tester) async {
      await pumpItem(tester, const AppBarNode(id: 'appBar', title: Literal('Counter')));

      expect(find.text('Counter'), findsOneWidget);
    });

    testWidgets('shows a bound title from the values', (tester) async {
      await pumpItem(
        tester,
        const AppBarNode(id: 'appBar', title: Binding('user.name')),
        values: GenericValues(const {
          'user': {'name': 'Jae'},
        }),
      );

      expect(find.text('Jae'), findsOneWidget);
    });

    testWidgets('shows no title when it has none', (tester) async {
      await pumpItem(tester, const AppBarNode(id: 'appBar'));

      expect(tester.widget<AppBar>(find.byType(AppBar)).title, isNull);
    });

    testWidgets('shows no leading button by default', (tester) async {
      await pumpItem(tester, const AppBarNode(id: 'appBar'));

      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(CloseButton), findsNothing);
    });

    const leadings = {AppBarLeading.back: BackButton, AppBarLeading.close: CloseButton};

    for (final MapEntry(key: leading, value: buttonType) in leadings.entries) {
      testWidgets('${leading.name} leading shows a $buttonType that dispatches back', (tester) async {
        await pumpItem(tester, AppBarNode(id: 'appBar', leading: Literal(leading)));

        await tester.tap(find.byType(buttonType));

        verify(() => cubit.dispatch(const [BackAction()])).called(1);
      });
    }
  });
}
