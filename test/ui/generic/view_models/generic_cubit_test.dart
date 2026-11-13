import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockGenericPageRepository extends Mock implements GenericPageRepository;

const _root = ColumnNode(id: 'root');
const _params = {'from': 'test'};

void main() {
  group(GenericCubit, () {
    late GenericPageRepository repository;

    setUp(() => repository = _MockGenericPageRepository());

    GenericCubit build() => GenericCubit(repository, pageId: 'counter', params: _params);

    GenericState loaded(Map<String, Object?> values) => GenericState(
      status: GenericStatus.success,
      page: const GenericPage(id: 'counter', root: _root),
      values: GenericValues(values),
    );

    test('initial state is loading with empty values', () {
      expect(build().state, const GenericState());
    });

    group('load', () {
      final page = GenericPage(id: 'counter', root: _root, state: GenericValues(const {'count': 0}));

      blocTest<GenericCubit, GenericState>(
        'emits the page and seeds values from its state',
        setUp: () => when(() => repository.fetch('counter', _params)).thenAnswer((_) async => Result.ok(page)),
        build: build,
        act: (cubit) => cubit.load(),
        expect: () => [
          GenericState(status: GenericStatus.success, page: page, values: GenericValues(const {'count': 0})),
        ],
        verify: (_) => verify(() => repository.fetch('counter', _params)).called(1),
      );

      blocTest<GenericCubit, GenericState>(
        'seeds empty values when the page has no state',
        setUp: () =>
            when(() => repository.fetch('counter', _params))
                .thenAnswer((_) async => const Result.ok(GenericPage(id: 'counter', root: _root))),
        build: build,
        act: (cubit) => cubit.load(),
        expect: () => const [
          GenericState(
            status: GenericStatus.success,
            page: GenericPage(id: 'counter', root: _root),
          ),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'runs onLoad after seeding values',
        setUp: () => when(() => repository.fetch('counter', _params)).thenAnswer(
          (_) async => Result.ok(
            page.copyWith(
              onLoad: const [
                UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment)),
                UpdateStateAction(path: 'ready', value: Literal(true)),
              ],
            ),
          ),
        ),
        build: build,
        act: (cubit) => cubit.load(),
        skip: 2,
        expect: () => [
          isA<GenericState>().having(
            (state) => state.values,
            'values',
            GenericValues(const {'count': 1, 'ready': true}),
          ),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'emits the failure when the fetch fails',
        setUp: () =>
            when(() => repository.fetch('counter', _params))
                .thenAnswer((_) async => const Result.err(GenericPageOffline())),
        build: build,
        act: (cubit) => cubit.load(),
        expect: () => const [GenericState(status: GenericStatus.failure, failure: GenericPageOffline())],
      );

      blocTest<GenericCubit, GenericState>(
        'clears a previous failure on success',
        setUp: () => when(() => repository.fetch('counter', _params)).thenAnswer((_) async => Result.ok(page)),
        build: build,
        seed: () => const GenericState(status: GenericStatus.failure, failure: GenericPageOffline()),
        act: (cubit) => cubit.load(),
        expect: () => [
          GenericState(status: GenericStatus.success, page: page, values: GenericValues(const {'count': 0})),
        ],
      );
    });

    group('dispatch updateState', () {
      blocTest<GenericCubit, GenericState>(
        'set replaces the value and creates missing parents',
        build: build,
        seed: () => loaded(const {'count': 0}),
        act: (cubit) => cubit.dispatch(const [
          UpdateStateAction(path: 'count', value: Literal(5)),
          UpdateStateAction(path: 'user.name', value: Literal('Ana')),
        ]),
        expect: () => [
          loaded(const {'count': 5}),
          loaded(const {
            'count': 5,
            'user': {'name': 'Ana'},
          }),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'toggle flips a bool and sets a missing path to true',
        build: build,
        seed: () => loaded(const {'on': true}),
        act: (cubit) => cubit.dispatch(const [
          UpdateStateAction(path: 'on', op: Literal(UpdateOp.toggle)),
          UpdateStateAction(path: 'other', op: Literal(UpdateOp.toggle)),
        ]),
        expect: () => [
          loaded(const {'on': false}),
          loaded(const {'on': false, 'other': true}),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'increment adds the value, defaulting to 1',
        build: build,
        seed: () => loaded(const {'count': 1}),
        act: (cubit) => cubit.dispatch(const [
          UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment)),
          UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment), value: Literal(-3)),
        ]),
        expect: () => [
          loaded(const {'count': 2}),
          loaded(const {'count': -1}),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'append adds to a list and creates a missing one',
        build: build,
        seed: () => loaded(const {
          'todos': ['a'],
        }),
        act: (cubit) => cubit.dispatch(const [
          UpdateStateAction(path: 'todos', op: Literal(UpdateOp.append), value: Literal('b')),
          UpdateStateAction(path: 'tags', op: Literal(UpdateOp.append), value: Literal('x')),
        ]),
        expect: () => [
          loaded(const {
            'todos': ['a', 'b'],
          }),
          loaded(const {
            'todos': ['a', 'b'],
            'tags': ['x'],
          }),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'removeAt removes the item at the index',
        build: build,
        seed: () => loaded(const {
          'todos': ['a', 'b', 'c'],
        }),
        act: (cubit) =>
            cubit.dispatch(const [UpdateStateAction(path: 'todos', op: Literal(UpdateOp.removeAt), value: Literal(1))]),
        expect: () => [
          loaded(const {
            'todos': ['a', 'c'],
          }),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'merge shallow-merges an object and creates a missing one',
        build: build,
        seed: () => loaded(const {
          'form': {'email': 'a', 'password': 'b'},
        }),
        act: (cubit) => cubit.dispatch(const [
          UpdateStateAction(path: 'form', op: Literal(UpdateOp.merge), value: Literal({'password': ''})),
          UpdateStateAction(path: 'user', op: Literal(UpdateOp.merge), value: Literal({'name': 'Ana'})),
        ]),
        expect: () => [
          loaded(const {
            'form': {'email': 'a', 'password': ''},
          }),
          loaded(const {
            'form': {'email': 'a', 'password': ''},
            'user': {'name': 'Ana'},
          }),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'resolves bound fields against the state left by earlier actions',
        build: build,
        seed: () => loaded(const {'step': 2, 'count': 0}),
        act: (cubit) => cubit.dispatch(const [
          UpdateStateAction(path: 'step', op: Literal(UpdateOp.increment)),
          UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment), value: Binding('step')),
        ]),
        expect: () => [
          loaded(const {'step': 3, 'count': 0}),
          loaded(const {'step': 3, 'count': 3}),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'a failed update skips the rest of the list',
        build: build,
        seed: () => loaded(const {
          'todos': ['a'],
          'count': 0,
        }),
        act: (cubit) => cubit.dispatch(const [
          UpdateStateAction(path: 'todos', op: Literal(UpdateOp.removeAt), value: Literal(4)),
          UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment)),
        ]),
        expect: () => const <GenericState>[],
      );

      blocTest<GenericCubit, GenericState>(
        'skips actions it does not handle and continues',
        build: build,
        seed: () => loaded(const {'count': 0}),
        act: (cubit) => cubit.dispatch(const [
          UnknownAction(),
          ShowMessageAction(text: Literal('hi')),
          UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment)),
        ]),
        expect: () => [
          loaded(const {'count': 1}),
        ],
      );
    });
  });
}
