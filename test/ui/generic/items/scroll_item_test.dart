import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
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

    testWidgets('lays its child out in full when its height is unbounded', (tester) async {
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ScrollItem(
                node: ScrollNode(
                  id: 'inner',
                  child: TextNode(id: 'hello', text: Literal('Hello')),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byKey(const ValueKey('hello')), findsOneWidget);
    });

    testWidgets('takes no space without a child when its height is unbounded', (tester) async {
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ScrollItem(node: ScrollNode(id: 'inner')),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ScrollItem)).height, 0);
    });

    testWidgets('has no refresh indicator without onRefresh', (tester) async {
      await pumpItem(
        tester,
        const ScrollNode(
          id: 'scroll',
          child: TextNode(id: 'hello', text: Literal('Hello')),
        ),
      );

      expect(find.byType(RefreshIndicator), findsNothing);

      await tester.fling(find.text('Hello'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(find.byType(RefreshProgressIndicator), findsNothing);
      verifyNever(() => cubit.dispatch(any()));
    });

    testWidgets('dispatches onRefresh on pull and shows the indicator until it finishes', (tester) async {
      final refresh = Completer<void>();
      when(() => cubit.dispatch(any())).thenAnswer((_) => refresh.future);
      const onRefresh = [ReloadAction()];
      await pumpItem(
        tester,
        const ScrollNode(
          id: 'scroll',
          onRefresh: onRefresh,
          child: TextNode(id: 'hello', text: Literal('Hello')),
        ),
      );

      await tester.fling(find.text('Hello'), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(() => cubit.dispatch(onRefresh)).called(1);
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      refresh.complete();
      await tester.pumpAndSettle();

      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });

    testWidgets('lays its child out in full without refreshing when its height is unbounded', (tester) async {
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ScrollItem(
                node: ScrollNode(
                  id: 'inner',
                  onRefresh: [ReloadAction()],
                  child: TextNode(id: 'hello', text: Literal('Hello')),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(RefreshIndicator), findsNothing);
      expect(find.byKey(const ValueKey('hello')), findsOneWidget);
    });
  });
}
