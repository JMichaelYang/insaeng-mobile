import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/expanded_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

void main() {
  group(ExpandedItem, () {
    late GenericCubit cubit;

    setUp(() {
      cubit = _MockGenericCubit();
      when(() => cubit.state).thenReturn(const GenericState(status: GenericStatus.success));
    });

    Future<void> pumpItem(WidgetTester tester, ExpandedNode node) => tester.pumpApp(
      BlocProvider.value(
        value: cubit,
        child: Scaffold(
          body: Center(child: ExpandedItem(node: node)),
        ),
      ),
    );

    testWidgets('renders its child as is outside a row or column', (tester) async {
      await pumpItem(
        tester,
        const ExpandedNode(
          id: 'body',
          child: TextNode(id: 'hello', text: Literal('Hello')),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('hello')), findsOneWidget);
      expect(find.byType(Expanded), findsNothing);
      expect(tester.getSize(find.byType(ExpandedItem)), tester.getSize(find.text('Hello')));
    });

    testWidgets('takes no space without a child outside a row or column', (tester) async {
      await pumpItem(tester, const ExpandedNode(id: 'gap'));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ExpandedItem)), Size.zero);
    });
  });
}
