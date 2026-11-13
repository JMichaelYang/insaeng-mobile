import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/column_item.dart';
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
