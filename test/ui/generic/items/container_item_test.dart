import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/container_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

void main() {
  group(ContainerItem, () {
    late GenericCubit cubit;

    setUp(() => cubit = _MockGenericCubit());

    const child = TextNode(id: 'hello', text: Literal('Hello'));

    Future<void> pumpItem(WidgetTester tester, ContainerNode node, {GenericValues? values}) {
      when(() => cubit.state)
          .thenReturn(GenericState(status: GenericStatus.success, values: values ?? GenericValues()));
      return tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [ContainerItem(node: node)],
            ),
          ),
        ),
      );
    }

    double screenWidth(WidgetTester tester) => tester.getSize(find.byType(Scaffold)).width;

    Rect childRect(WidgetTester tester) => tester.getRect(find.byKey(const ValueKey('hello')));

    testWidgets('renders its child keyed by its id', (tester) async {
      await pumpItem(tester, const ContainerNode(id: 'content', child: child));

      expect(find.byKey(const ValueKey('hello')), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders without a child', (tester) async {
      await pumpItem(tester, const ContainerNode(id: 'content', padding: Literal(SpacingToken.md)));

      expect(tester.getSize(find.byType(ContainerItem)).height, Dimens.spaceMd * 2);
    });

    testWidgets('defaults to no padding and start alignment', (tester) async {
      await pumpItem(tester, const ContainerNode(id: 'content', child: child));

      expect(childRect(tester).topLeft, Offset.zero);
      expect(tester.getSize(find.byType(ContainerItem)).width, screenWidth(tester));
    });

    const paddings = {
      SpacingToken.none: 0.0,
      SpacingToken.xs: Dimens.spaceXs,
      SpacingToken.sm: Dimens.spaceSm,
      SpacingToken.md: Dimens.spaceMd,
      SpacingToken.lg: Dimens.spaceLg,
      SpacingToken.xl: Dimens.spaceXl,
    };

    for (final MapEntry(key: token, value: size) in paddings.entries) {
      testWidgets('maps ${token.name} padding to $size on every side', (tester) async {
        await pumpItem(tester, ContainerNode(id: 'content', child: child, padding: Literal(token)));

        final container = tester.getRect(find.byType(ContainerItem));
        expect(childRect(tester).top - container.top, size);
        expect(container.bottom - childRect(tester).bottom, size);
        expect(childRect(tester).left - container.left, size);
      });
    }

    testWidgets('centers its child horizontally', (tester) async {
      await pumpItem(
        tester,
        const ContainerNode(id: 'content', child: child, alignment: Literal(AlignmentToken.center)),
      );

      expect(childRect(tester).center.dx, screenWidth(tester) / 2);
    });

    testWidgets('aligns its child to the end', (tester) async {
      await pumpItem(tester, const ContainerNode(id: 'content', child: child, alignment: Literal(AlignmentToken.end)));

      expect(childRect(tester).right, screenWidth(tester));
    });

    testWidgets('aligns its child to the end on the left in right-to-left locales', (tester) async {
      when(() => cubit.state).thenReturn(const GenericState(status: GenericStatus.success));
      await tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: const Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Column(
                children: [
                  ContainerItem(
                    node: ContainerNode(id: 'content', child: child, alignment: Literal(AlignmentToken.end)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(childRect(tester).left, 0);
    });

    testWidgets('stretches its child to the full width', (tester) async {
      await pumpItem(
        tester,
        const ContainerNode(
          id: 'content',
          child: child,
          padding: Literal(SpacingToken.md),
          alignment: Literal(AlignmentToken.stretch),
        ),
      );

      expect(childRect(tester).width, screenWidth(tester) - Dimens.spaceMd * 2);
    });

    testWidgets('resolves bound padding and alignment from the values', (tester) async {
      await pumpItem(
        tester,
        const ContainerNode(
          id: 'content',
          child: child,
          padding: Binding('layout.padding'),
          alignment: Binding('layout.alignment'),
        ),
        values: GenericValues(const {
          'layout': {'padding': SpacingToken.lg, 'alignment': AlignmentToken.center},
        }),
      );

      expect(childRect(tester).top, Dimens.spaceLg);
      expect(childRect(tester).center.dx, screenWidth(tester) / 2);
    });
  });
}
