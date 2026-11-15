import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/column_item.dart';
import 'package:insaeng/ui/generic/items/scroll_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

void main() {
  group(ColumnItem, () {
    late GenericCubit cubit;

    setUp(() => cubit = _MockGenericCubit());

    Future<void> pumpItem(WidgetTester tester, ColumnNode node, {GenericValues? values}) {
      when(() => cubit.state)
          .thenReturn(GenericState(status: GenericStatus.success, values: values ?? GenericValues()));
      return tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: Scaffold(body: ColumnItem(node: node)),
        ),
      );
    }

    Column column(WidgetTester tester) =>
        tester.widget<Column>(find.descendant(of: find.byType(ColumnItem), matching: find.byType(Column)).first);

    testWidgets('renders its children in order, keyed by their ids', (tester) async {
      await pumpItem(
        tester,
        const ColumnNode(
          id: 'column',
          children: [
            TextNode(id: 'first', text: Literal('One')),
            TextNode(id: 'second', text: Literal('Two')),
          ],
        ),
      );

      expect(find.byKey(const ValueKey('first')), findsOneWidget);
      expect(find.byKey(const ValueKey('second')), findsOneWidget);
      expect(tester.getTopLeft(find.text('One')).dy, lessThan(tester.getTopLeft(find.text('Two')).dy));
    });

    testWidgets('defaults to no spacing and start alignment', (tester) async {
      await pumpItem(tester, const ColumnNode(id: 'column'));

      expect(column(tester).spacing, 0);
      expect(column(tester).crossAxisAlignment, CrossAxisAlignment.start);
    });

    const spacings = {
      SpacingToken.none: 0.0,
      SpacingToken.xs: Dimens.spaceXs,
      SpacingToken.sm: Dimens.spaceSm,
      SpacingToken.md: Dimens.spaceMd,
      SpacingToken.lg: Dimens.spaceLg,
      SpacingToken.xl: Dimens.spaceXl,
    };

    for (final MapEntry(key: token, value: size) in spacings.entries) {
      testWidgets('maps ${token.name} spacing to $size', (tester) async {
        await pumpItem(tester, ColumnNode(id: 'column', spacing: Literal(token)));

        expect(column(tester).spacing, size);
      });
    }

    const alignments = {
      AlignmentToken.start: CrossAxisAlignment.start,
      AlignmentToken.center: CrossAxisAlignment.center,
      AlignmentToken.end: CrossAxisAlignment.end,
      AlignmentToken.stretch: CrossAxisAlignment.stretch,
    };

    for (final MapEntry(key: token, value: alignment) in alignments.entries) {
      testWidgets('maps ${token.name} alignment to $alignment', (tester) async {
        await pumpItem(tester, ColumnNode(id: 'column', alignment: Literal(token)));

        expect(column(tester).crossAxisAlignment, alignment);
      });
    }

    double screenHeight(WidgetTester tester) => tester.getSize(find.byType(Scaffold)).height;

    testWidgets('grows an expanded child into the remaining height', (tester) async {
      await pumpItem(
        tester,
        const ColumnNode(
          id: 'column',
          children: [
            TextNode(id: 'title', text: Literal('Title')),
            ExpandedNode(
              id: 'body',
              child: ScrollNode(id: 'scroll'),
            ),
          ],
        ),
      );

      expect(find.ancestor(of: find.byType(ScrollItem), matching: find.byType(Expanded)), findsOneWidget);
      expect(tester.getTopLeft(find.byType(ScrollItem)).dy, tester.getBottomLeft(find.text('Title')).dy);
      expect(tester.getBottomLeft(find.byType(ScrollItem)).dy, screenHeight(tester));
    });

    testWidgets('pushes later children to the bottom past an empty expanded', (tester) async {
      await pumpItem(
        tester,
        const ColumnNode(
          id: 'column',
          children: [
            TextNode(id: 'top', text: Literal('Top')),
            ExpandedNode(id: 'gap'),
            TextNode(id: 'bottom', text: Literal('Bottom')),
          ],
        ),
      );

      expect(tester.getBottomLeft(find.text('Bottom')).dy, screenHeight(tester));
    });

    testWidgets('shares the remaining height by flex', (tester) async {
      await pumpItem(
        tester,
        const ColumnNode(
          id: 'column',
          children: [
            ExpandedNode(id: 'one'),
            ExpandedNode(id: 'three', flex: 3),
          ],
        ),
      );

      expect(tester.getSize(find.byKey(const ValueKey('one'))).height, screenHeight(tester) / 4);
      expect(tester.getSize(find.byKey(const ValueKey('three'))).height, screenHeight(tester) * 3 / 4);
    });

    testWidgets('does not grow an expanded with a flex below one', (tester) async {
      await pumpItem(
        tester,
        const ColumnNode(
          id: 'column',
          children: [ExpandedNode(id: 'gap', flex: 0)],
        ),
      );

      expect(find.byType(Expanded), findsNothing);
      expect(tester.getSize(find.byKey(const ValueKey('gap'))).height, 0);
    });

    testWidgets('does not grow a scroll that is not wrapped in an expanded', (tester) async {
      await pumpItem(
        tester,
        const ColumnNode(
          id: 'column',
          children: [
            ScrollNode(
              id: 'scroll',
              child: TextNode(id: 'hello', text: Literal('Hello')),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Expanded), findsNothing);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('keeps each expanded child element when siblings are reordered', (tester) async {
      const first = ExpandedNode(
        id: 'first',
        child: ScrollNode(id: 'firstScroll'),
      );
      const second = ExpandedNode(
        id: 'second',
        child: ScrollNode(id: 'secondScroll'),
      );
      await pumpItem(tester, const ColumnNode(id: 'column', children: [first, second]));
      final firstElement = tester.element(find.byKey(const ValueKey('firstScroll')));
      final secondElement = tester.element(find.byKey(const ValueKey('secondScroll')));

      await pumpItem(tester, const ColumnNode(id: 'column', children: [second, first]));

      expect(tester.element(find.byKey(const ValueKey('firstScroll'))), same(firstElement));
      expect(tester.element(find.byKey(const ValueKey('secondScroll'))), same(secondElement));
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('second'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey('first'))).dy),
      );
    });

    testWidgets('does not grow expanded children when its height is unbounded', (tester) async {
      when(() => cubit.state).thenReturn(const GenericState(status: GenericStatus.success));
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: ColumnItem(
                node: ColumnNode(
                  id: 'column',
                  children: [
                    TextNode(id: 'top', text: Literal('Top')),
                    ExpandedNode(id: 'gap'),
                    TextNode(id: 'bottom', text: Literal('Bottom')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Expanded), findsNothing);
      expect(tester.getTopLeft(find.text('Bottom')).dy, tester.getBottomLeft(find.text('Top')).dy);
    });

    testWidgets('resolves bound spacing and alignment from the values', (tester) async {
      await pumpItem(
        tester,
        const ColumnNode(id: 'column', spacing: Binding('layout.spacing'), alignment: Binding('layout.alignment')),
        values: GenericValues(const {
          'layout': {'spacing': SpacingToken.lg, 'alignment': AlignmentToken.center},
        }),
      );

      expect(column(tester).spacing, Dimens.spaceLg);
      expect(column(tester).crossAxisAlignment, CrossAxisAlignment.center);
    });
  });
}
