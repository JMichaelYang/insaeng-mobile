import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/app_bar_item.dart';
import 'package:insaeng/ui/generic/items/button_item.dart';
import 'package:insaeng/ui/generic/items/column_item.dart';
import 'package:insaeng/ui/generic/items/node_view.dart';
import 'package:insaeng/ui/generic/items/text_field_item.dart';
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
      const TextFieldNode(id: 'textField', bind: 'name'): TextFieldItem,
      const UnknownNode(id: 'unknown'): UnknownItem,
    };

    for (final MapEntry(key: node, value: itemType) in cases.entries) {
      testWidgets('renders a ${node.runtimeType} as a $itemType keyed by its id', (tester) async {
        await pumpNode(tester, node);

        final view = find.byKey(ValueKey(node.id));
        expect(view, findsOneWidget);
        expect(tester.widget(view), isA<NodeView>());
        expect(find.descendant(of: view, matching: find.byType(itemType)), findsOneWidget);
      });
    }

    testWidgets('keeps each child element when siblings are reordered', (tester) async {
      const first = TextNode(id: 'first', text: Literal('One'));
      const second = TextNode(id: 'second', text: Literal('Two'));
      await pumpNode(tester, const ColumnNode(id: 'column', children: [first, second]));
      final firstElement = tester.element(find.byKey(const ValueKey('first')));
      final secondElement = tester.element(find.byKey(const ValueKey('second')));

      await pumpNode(tester, const ColumnNode(id: 'column', children: [second, first]));

      expect(tester.element(find.byKey(const ValueKey('first'))), same(firstElement));
      expect(tester.element(find.byKey(const ValueKey('second'))), same(secondElement));
      expect(tester.getTopLeft(find.text('Two')).dy, lessThan(tester.getTopLeft(find.text('One')).dy));
    });

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
