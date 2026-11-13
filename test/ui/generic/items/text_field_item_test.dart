import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/atoms/app_text_field.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/ui/generic/items/text_field_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

class _MockGenericPageRepository extends Mock implements GenericPageRepository;

const _onChanged = [UpdateStateAction(path: 'edits', op: Literal(UpdateOp.increment))];
const _onSubmit = [ShowMessageAction(text: Binding('name'))];

const _node = TextFieldNode(
  id: 'name',
  bind: 'name',
  label: Literal('Name'),
  hint: Literal('Enter your name'),
  onChanged: _onChanged,
  onSubmit: _onSubmit,
);

void main() {
  group(TextFieldItem, () {
    Future<void> pumpItem(WidgetTester tester, GenericCubit cubit, TextFieldNode node) => tester.pumpApp(
      BlocProvider.value(
        value: cubit,
        child: Scaffold(body: TextFieldItem(node: node)),
      ),
    );

    AppTextField field(WidgetTester tester) => tester.widget<AppTextField>(find.byType(AppTextField));

    group('with a mock cubit', () {
      late GenericCubit cubit;

      setUp(() {
        cubit = _MockGenericCubit();
        when(() => cubit.dispatch(any())).thenAnswer((_) async {});
      });

      Future<void> pump(WidgetTester tester, TextFieldNode node, {Map<String, Object?> values = const {}}) {
        when(() => cubit.state).thenReturn(GenericState(status: GenericStatus.success, values: GenericValues(values)));
        return pumpItem(tester, cubit, node);
      }

      testWidgets('shows the label, hint, and bound value', (tester) async {
        await pump(tester, _node, values: {'name': 'Ada'});

        expect(field(tester).label, 'Name');
        expect(field(tester).hint, 'Enter your name');
        expect(field(tester).value, 'Ada');
        expect(find.text('Ada'), findsOneWidget);
      });

      testWidgets('shows an empty value when the bound path is missing', (tester) async {
        await pump(tester, const TextFieldNode(id: 'name', bind: 'name'));

        expect(field(tester).value, '');
        expect(field(tester).label, isNull);
        expect(field(tester).hint, isNull);
      });

      testWidgets('shows a bound number as text', (tester) async {
        await pump(
          tester,
          const TextFieldNode(id: 'age', bind: 'form.age'),
          values: {
            'form': {'age': 36},
          },
        );

        expect(field(tester).value, '36');
      });

      testWidgets('resolves bound label and hint from the values', (tester) async {
        await pump(
          tester,
          const TextFieldNode(id: 'name', bind: 'name', label: Binding('labels.name'), hint: Binding('hints.name')),
          values: {
            'labels': {'name': 'Name'},
            'hints': {'name': 'Enter your name'},
          },
        );

        expect(field(tester).label, 'Name');
        expect(field(tester).hint, 'Enter your name');
      });

      testWidgets('writes the bound path and then runs onChanged when typing', (tester) async {
        await pump(tester, _node);

        await tester.enterText(find.byType(TextField), 'Ada');

        verify(() => cubit.dispatch(const [UpdateStateAction(path: 'name', value: Literal('Ada')), ..._onChanged]))
            .called(1);
      });

      testWidgets('runs onSubmit when submitted', (tester) async {
        await pump(tester, _node);
        await tester.enterText(find.byType(TextField), 'Ada');
        clearInteractions(cubit);

        await tester.testTextInput.receiveAction(TextInputAction.done);

        verify(() => cubit.dispatch(_onSubmit)).called(1);
      });
    });

    group('with a real cubit', () {
      late GenericPageRepository repository;
      late GenericCubit cubit;

      setUp(() async {
        repository = _MockGenericPageRepository();
        when(() => repository.fetch('form', const {})).thenAnswer(
          (_) async => Result.ok(GenericPage(id: 'form', root: _node, state: GenericValues(const {'edits': 0}))),
        );
        cubit = GenericCubit(repository, pageId: 'form');
        await cubit.load();
      });

      tearDown(() => cubit.close());

      testWidgets('typing updates the bound path and fires onChanged', (tester) async {
        await pumpItem(tester, cubit, _node);

        await tester.enterText(find.byType(TextField), 'Ada');
        await tester.pump();

        expect(cubit.state.values.get('name'), 'Ada');
        expect(cubit.state.values.get('edits'), 1);
        expect(find.text('Ada'), findsOneWidget);
      });

      testWidgets('submitting fires onSubmit with the typed value', (tester) async {
        await pumpItem(tester, cubit, _node);
        final effects = <GenericEffect>[];
        final subscription = cubit.effects.listen(effects.add);
        addTearDown(subscription.cancel);

        await tester.enterText(find.byType(TextField), 'Ada');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(effects, [const ShowMessageEffect(text: 'Ada')]);
      });

      testWidgets('shows a value written to the bound path elsewhere', (tester) async {
        await pumpItem(tester, cubit, _node);
        await tester.enterText(find.byType(TextField), 'Ada');

        await cubit.dispatch(const [UpdateStateAction(path: 'name', value: Literal(''))]);
        await tester.pump();

        expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
      });
    });
  });
}
