import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/molecules/app_checkbox_tile.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/ui/generic/items/checkbox_tile_item.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/pump_app.dart';

class _MockGenericCubit extends MockCubit<GenericState> implements GenericCubit;

class _MockGenericPageRepository extends Mock implements GenericPageRepository;

class _MockGenericActionRepository extends Mock implements GenericActionRepository;

const _onChanged = [UpdateStateAction(path: 'changes', op: Literal(UpdateOp.increment))];

const _node = CheckboxTileNode(
  id: 'done',
  bind: 'todo.done',
  title: Literal('Stretch'),
  subtitle: Literal('10 minutes'),
  emoji: Literal('🧘'),
  onChanged: _onChanged,
);

void main() {
  group(CheckboxTileItem, () {
    Future<void> pumpItem(WidgetTester tester, GenericCubit cubit, CheckboxTileNode node) => tester.pumpApp(
      BlocProvider.value(
        value: cubit,
        child: Scaffold(body: CheckboxTileItem(node: node)),
      ),
    );

    AppCheckboxTile tile(WidgetTester tester) => tester.widget<AppCheckboxTile>(find.byType(AppCheckboxTile));

    group('with a mock cubit', () {
      late GenericCubit cubit;

      setUp(() {
        cubit = _MockGenericCubit();
        when(() => cubit.dispatch(any())).thenAnswer((_) async {});
      });

      Future<void> pump(WidgetTester tester, CheckboxTileNode node, {Map<String, Object?> values = const {}}) {
        when(() => cubit.state).thenReturn(GenericState(status: GenericStatus.success, values: GenericValues(values)));
        return pumpItem(tester, cubit, node);
      }

      testWidgets('shows the emoji, title, subtitle, and bound value', (tester) async {
        await pump(
          tester,
          _node,
          values: {
            'todo': {'done': true},
          },
        );

        expect(tile(tester).title, 'Stretch');
        expect(tile(tester).subtitle, '10 minutes');
        expect(tile(tester).emoji, '🧘');
        expect(tile(tester).checked, isTrue);
        expect(tile(tester).busy, isFalse);
        expect(find.text('Stretch'), findsOneWidget);
        expect(find.text('10 minutes'), findsOneWidget);
      });

      testWidgets('is unchecked when the bound path is missing', (tester) async {
        await pump(tester, const CheckboxTileNode(id: 'done', bind: 'todo.done', title: Literal('Stretch')));

        expect(tile(tester).checked, isFalse);
        expect(tile(tester).subtitle, isNull);
        expect(tile(tester).emoji, isNull);
      });

      testWidgets('is unchecked when the bound path is not a bool', (tester) async {
        await pump(
          tester,
          const CheckboxTileNode(id: 'done', bind: 'todo.done', title: Literal('Stretch')),
          values: {
            'todo': {'done': 'yes'},
          },
        );

        expect(tile(tester).checked, isFalse);
      });

      testWidgets('resolves bound title, subtitle, emoji, and busy from the values', (tester) async {
        await pump(
          tester,
          const CheckboxTileNode(
            id: 'done',
            bind: 'todo.done',
            title: Binding('todo.title'),
            subtitle: Binding('todo.due'),
            emoji: Binding('todo.emoji'),
            busy: Binding('saving'),
          ),
          values: {
            'todo': {'title': 'Stretch', 'due': 'Today', 'emoji': '🧘'},
            'saving': true,
          },
        );

        expect(tile(tester).title, 'Stretch');
        expect(tile(tester).subtitle, 'Today');
        expect(tile(tester).emoji, '🧘');
        expect(tile(tester).busy, isTrue);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('defaults to the check mark', (tester) async {
        await pump(tester, _node);

        expect(tile(tester).mark, AppCheckboxMark.check);
      });

      const marks = {CheckboxMarkToken.check: AppCheckboxMark.check, CheckboxMarkToken.dash: AppCheckboxMark.dash};

      for (final MapEntry(key: mark, value: appMark) in marks.entries) {
        testWidgets('maps the literal ${mark.name} mark to $appMark', (tester) async {
          await pump(
            tester,
            CheckboxTileNode(id: 'done', bind: 'todo.done', title: const Literal('Stretch'), mark: Literal(mark)),
          );

          expect(tile(tester).mark, appMark);
        });
      }

      testWidgets('resolves a bound dash mark from the values', (tester) async {
        await pump(
          tester,
          const CheckboxTileNode(id: 'done', bind: 'todo.done', title: Literal('Stretch'), mark: Binding('todo.mark')),
          values: {
            'todo': {'done': true, 'mark': CheckboxMarkToken.dash},
          },
        );

        expect(tile(tester).mark, AppCheckboxMark.dash);
      });

      testWidgets('falls back to the check mark when the bound mark is missing', (tester) async {
        await pump(
          tester,
          const CheckboxTileNode(id: 'done', bind: 'todo.done', title: Literal('Stretch'), mark: Binding('todo.mark')),
        );

        expect(tile(tester).mark, AppCheckboxMark.check);
      });

      for (final checked in [false, true]) {
        testWidgets('writes ${!checked} to the bound path and then runs onChanged when tapped', (tester) async {
          await pump(
            tester,
            _node,
            values: {
              'todo': {'done': checked},
            },
          );

          await tester.tap(find.text('Stretch'));

          verify(() => cubit.dispatch([UpdateStateAction(path: 'todo.done', value: Literal(!checked)), ..._onChanged]))
              .called(1);
        });
      }

      testWidgets('dispatches nothing when tapped while busy', (tester) async {
        await pump(
          tester,
          const CheckboxTileNode(id: 'done', bind: 'todo.done', title: Literal('Stretch'), busy: Literal(true)),
        );

        await tester.tap(find.text('Stretch'), warnIfMissed: false);

        verifyNever(() => cubit.dispatch(any()));
      });
    });

    group('with a real cubit', () {
      late GenericPageRepository repository;
      late GenericCubit cubit;

      setUp(() async {
        repository = _MockGenericPageRepository();
        when(() => repository.fetch('todos', const {})).thenAnswer(
          (_) async => Result.ok(
            GenericPage(
              id: 'todos',
              root: _node,
              state: GenericValues(const {
                'todo': {'done': false},
                'changes': 0,
              }),
            ),
          ),
        );
        cubit = GenericCubit(repository, _MockGenericActionRepository(), pageId: 'todos');
        await cubit.load();
      });

      tearDown(() => cubit.close());

      testWidgets('tapping toggles the bound path and fires onChanged', (tester) async {
        await pumpItem(tester, cubit, _node);

        await tester.tap(find.text('Stretch'));
        await tester.pump();

        expect(cubit.state.values.get('todo.done'), isTrue);
        expect(cubit.state.values.get('changes'), 1);
        expect(tile(tester).checked, isTrue);

        await tester.tap(find.text('Stretch'));
        await tester.pump();

        expect(cubit.state.values.get('todo.done'), isFalse);
        expect(cubit.state.values.get('changes'), 2);
        expect(tile(tester).checked, isFalse);
      });

      testWidgets('onChanged sees the toggled value', (tester) async {
        await pumpItem(
          tester,
          cubit,
          const CheckboxTileNode(
            id: 'done',
            bind: 'todo.done',
            title: Literal('Stretch'),
            onChanged: [ShowMessageAction(text: Binding('todo.done'))],
          ),
        );
        final effects = <GenericEffect>[];
        final subscription = cubit.effects.listen(effects.add);
        addTearDown(subscription.cancel);

        await tester.tap(find.text('Stretch'));
        await tester.pump();

        expect(effects, [const ShowMessageEffect(text: 'true')]);
      });

      testWidgets('follows a bound busy flag', (tester) async {
        await pumpItem(
          tester,
          cubit,
          const CheckboxTileNode(id: 'done', bind: 'todo.done', title: Literal('Stretch'), busy: Binding('saving')),
        );

        expect(tile(tester).busy, isFalse);

        await cubit.dispatch(const [UpdateStateAction(path: 'saving', value: Literal(true))]);
        await tester.pump();

        expect(tile(tester).busy, isTrue);
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);

        await tester.tap(find.text('Stretch'), warnIfMissed: false);
        await tester.pump();

        expect(cubit.state.values.get('todo.done'), isFalse);
      });

      testWidgets('shows a value written to the bound path elsewhere', (tester) async {
        await pumpItem(tester, cubit, _node);

        await cubit.dispatch(const [UpdateStateAction(path: 'todo.done', value: Literal(true))]);
        await tester.pump();

        expect(tile(tester).checked, isTrue);
      });
    });
  });
}
