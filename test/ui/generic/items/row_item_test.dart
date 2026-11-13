import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/row_item.dart';
import 'package:insaeng/ui/generic/items/scroll_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

void main() {
  group(RowItem, () {
    late GenericCubit cubit;

    setUp(() => cubit = _MockGenericCubit());

    Future<void> pumpItem(WidgetTester tester, RowNode node, {GenericValues? values}) {
      when(() => cubit.state)
          .thenReturn(GenericState(status: GenericStatus.success, values: values ?? GenericValues()));
      return tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: Scaffold(body: RowItem(node: node)),
        ),
      );
    }

    Row row(WidgetTester tester) =>
        tester.widget<Row>(find.descendant(of: find.byType(RowItem), matching: find.byType(Row)).first);

    testWidgets('renders its children left to right, keyed by their ids', (tester) async {
      await pumpItem(
        tester,
        const RowNode(
          id: 'row',
          children: [
            TextNode(id: 'first', text: Literal('One')),
            TextNode(id: 'second', text: Literal('Two')),
          ],
        ),
      );

      expect(find.byKey(const ValueKey('first')), findsOneWidget);
      expect(find.byKey(const ValueKey('second')), findsOneWidget);
      expect(tester.getTopLeft(find.text('One')).dx, lessThan(tester.getTopLeft(find.text('Two')).dx));
    });

    testWidgets('defaults to no spacing and start alignment', (tester) async {
      await pumpItem(tester, const RowNode(id: 'row'));

      expect(row(tester).spacing, 0);
      expect(row(tester).crossAxisAlignment, CrossAxisAlignment.start);
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
        await pumpItem(tester, RowNode(id: 'row', spacing: Literal(token)));

        expect(row(tester).spacing, size);
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
        await pumpItem(tester, RowNode(id: 'row', alignment: Literal(token)));

        expect(row(tester).crossAxisAlignment, alignment);
      });
    }

    testWidgets('expands a spacer to push later children to the end', (tester) async {
      await pumpItem(
        tester,
        const RowNode(
          id: 'row',
          children: [
            TextNode(id: 'start', text: Literal('Start')),
            SpacerNode(id: 'gap'),
            TextNode(id: 'end', text: Literal('End')),
          ],
        ),
      );

      final screenWidth = tester.getSize(find.byType(Scaffold)).width;
      expect(tester.getTopRight(find.text('End')).dx, screenWidth);
    });

    testWidgets('does not expand a vertical scroll child', (tester) async {
      await pumpItem(
        tester,
        const RowNode(
          id: 'row',
          children: [ScrollNode(id: 'scroll')],
        ),
      );

      expect(find.ancestor(of: find.byType(ScrollItem), matching: find.byType(Expanded)), findsNothing);
    });

    testWidgets('does not expand children when its width is unbounded', (tester) async {
      when(() => cubit.state).thenReturn(const GenericState(status: GenericStatus.success));
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: RowItem(
                node: RowNode(
                  id: 'row',
                  children: [
                    TextNode(id: 'start', text: Literal('Start')),
                    SpacerNode(id: 'gap'),
                    TextNode(id: 'end', text: Literal('End')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Expanded), findsNothing);
      expect(tester.getTopLeft(find.text('End')).dx, tester.getTopRight(find.text('Start')).dx);
    });

    testWidgets('resolves bound spacing and alignment from the values', (tester) async {
      await pumpItem(
        tester,
        const RowNode(id: 'row', spacing: Binding('layout.spacing'), alignment: Binding('layout.alignment')),
        values: GenericValues(const {
          'layout': {'spacing': SpacingToken.sm, 'alignment': AlignmentToken.end},
        }),
      );

      expect(row(tester).spacing, Dimens.spaceSm);
      expect(row(tester).crossAxisAlignment, CrossAxisAlignment.end);
    });
  });
}
