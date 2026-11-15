import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/theme/dimens.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/spacer_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

void main() {
  group(SpacerItem, () {
    late GenericCubit cubit;

    setUp(() => cubit = _MockGenericCubit());

    Future<void> pumpItem(WidgetTester tester, SpacerNode node, {GenericValues? values}) {
      when(() => cubit.state)
          .thenReturn(GenericState(status: GenericStatus.success, values: values ?? GenericValues()));
      return tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: Scaffold(
            body: Center(child: SpacerItem(node: node)),
          ),
        ),
      );
    }

    Size spacerSize(WidgetTester tester) => tester.getSize(find.byType(SpacerItem));

    testWidgets('defaults to an md gap', (tester) async {
      await pumpItem(tester, const SpacerNode(id: 'gap'));

      expect(spacerSize(tester), const Size.square(Dimens.spaceMd));
    });

    const sizes = {
      SpacingToken.none: 0.0,
      SpacingToken.xs: Dimens.spaceXs,
      SpacingToken.sm: Dimens.spaceSm,
      SpacingToken.md: Dimens.spaceMd,
      SpacingToken.lg: Dimens.spaceLg,
      SpacingToken.xl: Dimens.spaceXl,
    };

    for (final MapEntry(key: token, value: size) in sizes.entries) {
      testWidgets('maps the ${token.name} size to a $size gap', (tester) async {
        await pumpItem(tester, SpacerNode(id: 'gap', size: Literal(token)));

        expect(spacerSize(tester), Size.square(size));
      });
    }

    testWidgets('resolves a bound size from the values', (tester) async {
      await pumpItem(
        tester,
        const SpacerNode(id: 'gap', size: Binding('gap')),
        values: GenericValues(const {'gap': SpacingToken.xl}),
      );

      expect(spacerSize(tester), const Size.square(Dimens.spaceXl));
    });
  });
}
