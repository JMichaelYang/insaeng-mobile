import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/scroll_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

void main() {
  group(ScrollItem, () {
    late GenericCubit cubit;

    setUp(() {
      cubit = _MockGenericCubit();
      when(() => cubit.state).thenReturn(const GenericState(status: GenericStatus.success));
    });

    Future<void> pumpItem(WidgetTester tester, ScrollNode node) => tester.pumpApp(
      BlocProvider.value(
        value: cubit,
        child: Scaffold(body: ScrollItem(node: node)),
      ),
    );

    testWidgets('renders without a child', (tester) async {
      await pumpItem(tester, const ScrollNode(id: 'scroll'));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('scrolls a child taller than the screen into view', (tester) async {
      await pumpItem(
        tester,
        ScrollNode(
          id: 'scroll',
          child: ColumnNode(
            id: 'list',
            children: [
              for (var i = 0; i < 50; i++)
                TextNode(id: 'line$i', text: Literal('Line $i'), style: const Literal(TextStyleToken.displayLarge)),
            ],
          ),
        ),
      );
      expect(find.byKey(const ValueKey('list')), findsOneWidget);
      expect(find.text('Line 49').hitTestable(), findsNothing);

      await tester.scrollUntilVisible(find.text('Line 49'), 200);

      expect(find.text('Line 49').hitTestable(), findsOneWidget);
    });
  });
}
