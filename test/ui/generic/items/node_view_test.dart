import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/app_bar_item.dart';
import 'package:insaeng/ui/generic/items/button_item.dart';
import 'package:insaeng/ui/generic/items/column_item.dart';
import 'package:insaeng/ui/generic/items/node_view.dart';
import 'package:insaeng/ui/generic/items/text_item.dart';
import 'package:insaeng/ui/generic/items/unknown_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

void main() {
  group(NodeView, () {
    late GenericCubit cubit;

    setUp(() {
      cubit = _MockGenericCubit();
      when(() => cubit.state).thenReturn(const GenericState(status: GenericStatus.success));
    });

    Future<void> pumpNode(WidgetTester tester, GenericNode node) => tester.pumpApp(
      BlocProvider.value(
        value: cubit,
        child: Scaffold(body: NodeView(node: node)),
      ),
    );

    final cases = <GenericNode, Type>{
      const ColumnNode(id: 'column'): ColumnItem,
      const AppBarNode(id: 'appBar'): AppBarItem,
      const TextNode(id: 'text', text: Literal('Hi')): TextItem,
      const ButtonNode(id: 'button', label: Literal('Add')): ButtonItem,
      const UnknownNode(id: 'unknown'): UnknownItem,
    };

    for (final MapEntry(key: node, value: itemType) in cases.entries) {
      testWidgets('renders a ${node.runtimeType} as a $itemType keyed by its id', (tester) async {
        await pumpNode(tester, node);

        final item = find.byKey(ValueKey(node.id));
        expect(item, findsOneWidget);
        expect(tester.widget(item).runtimeType, itemType);
      });
    }

    testWidgets('renders nested children', (tester) async {
      await pumpNode(
        tester,
        const ColumnNode(
          id: 'root',
          children: [
            AppBarNode(id: 'appBar', title: Literal('Counter')),
            ColumnNode(
              id: 'counter',
              children: [
                TextNode(id: 'count', text: Literal('0')),
                ButtonNode(id: 'add', label: Literal('Add')),
              ],
            ),
          ],
        ),
      );

      expect(find.byKey(const ValueKey('root')), findsOneWidget);
      expect(find.byKey(const ValueKey('counter')), findsOneWidget);
      expect(find.text('Counter'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });
  });
}
