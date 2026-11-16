import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/atoms/app_progress_bar.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/ui/generic/items/progress_bar_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

void main() {
  group(ProgressBarItem, () {
    late GenericCubit cubit;

    setUp(() => cubit = _MockGenericCubit());

    Future<void> pumpItem(WidgetTester tester, ProgressBarNode node, {GenericValues? values}) {
      when(() => cubit.state)
          .thenReturn(GenericState(status: GenericStatus.success, values: values ?? GenericValues()));
      return tester.pumpApp(
        BlocProvider.value(
          value: cubit,
          child: Scaffold(
            body: Column(children: [ProgressBarItem(node: node)]),
          ),
        ),
      );
    }

    double barValue(WidgetTester tester) => tester.widget<AppProgressBar>(find.byType(AppProgressBar)).value;

    testWidgets('fills in proportion to value over max', (tester) async {
      await pumpItem(tester, const ProgressBarNode(id: 'progress', value: Literal(1), max: Literal(4)));

      expect(barValue(tester), 0.25);
    });

    testWidgets('resolves a bound value from the values', (tester) async {
      await pumpItem(
        tester,
        const ProgressBarNode(id: 'progress', value: Binding('progress.done'), max: Literal(3)),
        values: GenericValues(const {
          'progress': {'done': 3},
        }),
      );

      expect(barValue(tester), 1);
    });

    testWidgets('stays empty when max is zero', (tester) async {
      await pumpItem(tester, const ProgressBarNode(id: 'progress', value: Literal(0), max: Literal(0)));

      expect(barValue(tester), 0);
    });

    testWidgets('stays empty when the bound value is missing', (tester) async {
      await pumpItem(tester, const ProgressBarNode(id: 'progress', value: Binding('missing'), max: Literal(2)));

      expect(barValue(tester), 0);
    });
  });
}
