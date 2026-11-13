import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/text_item.dart';
import 'package:insaeng/ui/generic/items/unknown_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

void main() {
  group(UnknownItem, () {
    late GenericCubit cubit;

    setUp(() {
      cubit = _MockGenericCubit();
      when(() => cubit.state).thenReturn(const GenericState(status: GenericStatus.success));
    });

    Future<void> pumpItem(WidgetTester tester, UnknownNode node) => tester.pumpApp(
      BlocProvider.value(
        value: cubit,
        child: Scaffold(body: UnknownItem(node: node)),
      ),
    );

    testWidgets('renders its fallback keyed by the fallback id', (tester) async {
      await pumpItem(
        tester,
        const UnknownNode(
          id: 'chart',
          fallback: TextNode(id: 'chartFallback', text: Literal('Update the app')),
        ),
      );

      expect(find.text('Update the app'), findsOneWidget);
      expect(find.byKey(const ValueKey('chartFallback')), findsOneWidget);
      expect(find.byType(TextItem), findsOneWidget);
    });

    testWidgets('renders nothing without a fallback', (tester) async {
      await pumpItem(tester, const UnknownNode(id: 'chart'));

      final box = find.descendant(of: find.byType(UnknownItem), matching: find.byType(SizedBox));
      expect(tester.getSize(box), Size.zero);
      expect(find.byType(Text), findsNothing);
    });
  });
}
