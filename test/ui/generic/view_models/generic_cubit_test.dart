import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable_json.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/ui/generic/view_models/generic_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockGenericActionRepository extends Mock implements GenericActionRepository;

class _MockGenericPageRepository extends Mock implements GenericPageRepository;

const _root = ColumnNode(id: 'root');
const _params = {'from': 'test'};

void main() {
  setUpAll(() => registerFallbackValue(RequestMethod.post));

  group(GenericCubit, () {
    late GenericPageRepository repository;
    late GenericActionRepository actions;

    setUp(() {
      repository = _MockGenericPageRepository();
      actions = _MockGenericActionRepository();
    });

    GenericCubit build() => GenericCubit(repository, actions, pageId: 'counter', params: _params);

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

    group('retry', () {
      final page = GenericPage(id: 'counter', root: _root, state: GenericValues(const {'count': 0}));

      blocTest<GenericCubit, GenericState>(
        'emits loading without the failure, then the loaded page',
        setUp: () => when(() => repository.fetch('counter', _params)).thenAnswer((_) async => Result.ok(page)),
        build: build,
        seed: () => const GenericState(status: GenericStatus.failure, failure: GenericPageOffline()),
        act: (cubit) => cubit.retry(),
        expect: () => [
          const GenericState(),
          GenericState(status: GenericStatus.success, page: page, values: GenericValues(const {'count': 0})),
        ],
      );
    });

    group('dispatch reload', () {
      const reloaded = GenericPage(
        id: 'counter',
        root: ColumnNode(id: 'reloaded'),
      );

      blocTest<GenericCubit, GenericState>(
        'replaces the page with the same params and keeps values',
        setUp: () =>
            when(() => repository.fetch('counter', _params)).thenAnswer((_) async => const Result.ok(reloaded)),
        build: build,
        seed: () => loaded(const {'count': 3}),
        act: (cubit) => cubit.dispatch(const [ReloadAction()]),
        expect: () => [
          GenericState(status: GenericStatus.success, page: reloaded, values: GenericValues(const {'count': 3})),
        ],
        verify: (_) => verify(() => repository.fetch('counter', _params)).called(1),
      );

      blocTest<GenericCubit, GenericState>(
        'replaces values when the new page sends state',
        setUp: () =>
            when(() => repository.fetch('counter', _params))
                .thenAnswer((_) async => Result.ok(reloaded.copyWith(state: GenericValues(const {'count': 0})))),
        build: build,
        seed: () => loaded(const {'count': 3, 'draft': 'x'}),
        act: (cubit) => cubit.dispatch(const [ReloadAction()]),
        expect: () => [
          isA<GenericState>().having((state) => state.values, 'values', GenericValues(const {'count': 0})),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'does not rerun onLoad and continues the list',
        setUp: () => when(() => repository.fetch('counter', _params)).thenAnswer(
          (_) async => Result.ok(
            reloaded.copyWith(
              onLoad: const [UpdateStateAction(path: 'loaded', value: Literal(true))],
            ),
          ),
        ),
        build: build,
        seed: () => loaded(const {'count': 0}),
        act: (cubit) =>
            cubit.dispatch(const [ReloadAction(), UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment))]),
        skip: 1,
        expect: () => [
          isA<GenericState>().having((state) => state.values, 'values', GenericValues(const {'count': 1})),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'a failed fetch keeps the page and skips the rest of the list',
        setUp: () =>
            when(() => repository.fetch('counter', _params))
                .thenAnswer((_) async => const Result.err(GenericPageOffline())),
        build: build,
        seed: () => loaded(const {'count': 0}),
        act: (cubit) =>
            cubit.dispatch(const [ReloadAction(), UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment))]),
        expect: () => const <GenericState>[],
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
        act: (cubit) =>
            cubit.dispatch(const [UnknownAction(), UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment))]),
        expect: () => [
          loaded(const {'count': 1}),
        ],
      );
    });

    group('dispatch request', () {
      void stubPerform(Result<List<GenericAction>> result) => when(
        () => actions.perform(
          method: any(named: 'method'),
          endpoint: any(named: 'endpoint'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => result);

      blocTest<GenericCubit, GenericState>(
        'performs the resolved method, endpoint, and body',
        setUp: () => stubPerform(const Result.ok([])),
        build: build,
        seed: () => loaded(const {
          'form': {'email': 'a@b.c', 'password': 'pw'},
          'route': '/auth/login',
        }),
        act: (cubit) => cubit.dispatch(const [
          RequestAction(
            method: Literal(RequestMethod.put),
            endpoint: Binding('route'),
            body: JsonObject({
              'email': JsonBinding(Binding('form.email')),
              'password': JsonBinding(Binding('form.password')),
              'remember': JsonLiteral(true),
            }),
          ),
        ]),
        expect: () => const <GenericState>[],
        verify: (_) => verify(
          () => actions.perform(
            method: RequestMethod.put,
            endpoint: '/auth/login',
            body: {'email': 'a@b.c', 'password': 'pw', 'remember': true},
          ),
        ).called(1),
      );

      blocTest<GenericCubit, GenericState>(
        'defaults to POST with an empty body',
        setUp: () => stubPerform(const Result.ok([])),
        build: build,
        seed: () => loaded(const {}),
        act: (cubit) => cubit.dispatch(const [RequestAction(endpoint: Literal('/ping'))]),
        verify: (_) => verify(() => actions.perform(method: RequestMethod.post, endpoint: '/ping')).called(1),
      );

      blocTest<GenericCubit, GenericState>(
        'resolves a bound body from state',
        setUp: () => stubPerform(const Result.ok([])),
        build: build,
        seed: () => loaded(const {
          'form': {'email': 'a@b.c'},
        }),
        act: (cubit) =>
            cubit.dispatch(const [RequestAction(endpoint: Literal('/save'), body: JsonBinding(Binding('form')))]),
        verify: (_) =>
            verify(() => actions.perform(method: RequestMethod.post, endpoint: '/save', body: {'email': 'a@b.c'}))
                .called(1),
      );

      blocTest<GenericCubit, GenericState>(
        'sends an empty body when the body is bound to something other than an object',
        setUp: () => stubPerform(const Result.ok([])),
        build: build,
        seed: () => loaded(const {'name': 'Ana'}),
        act: (cubit) =>
            cubit.dispatch(const [RequestAction(endpoint: Literal('/save'), body: JsonBinding(Binding('name')))]),
        verify: (_) => verify(() => actions.perform(method: RequestMethod.post, endpoint: '/save')).called(1),
      );

      blocTest<GenericCubit, GenericState>(
        'runs the returned actions in place of the request, then the rest of the list',
        setUp: () => stubPerform(
          const Result.ok([
            UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment)),
            UpdateStateAction(path: 'saved', value: Literal(true)),
          ]),
        ),
        build: build,
        seed: () => loaded(const {'count': 0}),
        act: (cubit) => cubit.dispatch(const [
          RequestAction(endpoint: Literal('/save')),
          UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment)),
        ]),
        expect: () => [
          loaded(const {'count': 1}),
          loaded(const {'count': 1, 'saved': true}),
          loaded(const {'count': 2, 'saved': true}),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'a failed returned action skips the rest of the list',
        setUp: () => stubPerform(
          const Result.ok([UpdateStateAction(path: 'missing', op: Literal(UpdateOp.removeAt), value: Literal(0))]),
        ),
        build: build,
        seed: () => loaded(const {'count': 0}),
        act: (cubit) => cubit.dispatch(const [
          RequestAction(endpoint: Literal('/save')),
          UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment)),
        ]),
        expect: () => const <GenericState>[],
      );

      blocTest<GenericCubit, GenericState>(
        'a failure emits no effect and skips the rest of the list',
        setUp: () => stubPerform(const Result.err(GenericActionOffline())),
        build: build,
        seed: () => loaded(const {'count': 0}),
        act: (cubit) async {
          final effects = expectLater(cubit.effects, emitsDone);
          await cubit.dispatch(const [
            RequestAction(endpoint: Literal('/save')),
            BackAction(),
            UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment)),
          ]);
          await cubit.close();
          await effects;
        },
        expect: () => const <GenericState>[],
      );

      blocTest<GenericCubit, GenericState>(
        'on success runs the returned actions, then onComplete, then the rest of the list',
        setUp: () => stubPerform(
          const Result.ok([UpdateStateAction(path: 'log', op: Literal(UpdateOp.append), value: Literal('ok'))]),
        ),
        build: build,
        seed: () => loaded(const {'log': <Object?>[]}),
        act: (cubit) => cubit.dispatch(const [
          RequestAction(
            endpoint: Literal('/save'),
            onError: [UpdateStateAction(path: 'log', op: Literal(UpdateOp.append), value: Literal('error'))],
            onComplete: [UpdateStateAction(path: 'log', op: Literal(UpdateOp.append), value: Literal('complete'))],
          ),
          UpdateStateAction(path: 'log', op: Literal(UpdateOp.append), value: Literal('next')),
        ]),
        expect: () => [
          loaded(const {
            'log': ['ok'],
          }),
          loaded(const {
            'log': ['ok', 'complete'],
          }),
          loaded(const {
            'log': ['ok', 'complete', 'next'],
          }),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'on failure runs onError, then onComplete, and skips the rest of the list',
        setUp: () => stubPerform(const Result.err(GenericActionOffline())),
        build: build,
        seed: () => loaded(const {'log': <Object?>[]}),
        act: (cubit) => cubit.dispatch(const [
          RequestAction(
            endpoint: Literal('/save'),
            onError: [UpdateStateAction(path: 'log', op: Literal(UpdateOp.append), value: Literal('error'))],
            onComplete: [UpdateStateAction(path: 'log', op: Literal(UpdateOp.append), value: Literal('complete'))],
          ),
          UpdateStateAction(path: 'log', op: Literal(UpdateOp.append), value: Literal('next')),
        ]),
        expect: () => [
          loaded(const {
            'log': ['error'],
          }),
          loaded(const {
            'log': ['error', 'complete'],
          }),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'clears a busy flag set before the request when it fails',
        setUp: () => stubPerform(const Result.err(GenericActionOffline())),
        build: build,
        seed: () => loaded(const {'busy': false}),
        act: (cubit) => cubit.dispatch(const [
          UpdateStateAction(path: 'busy', value: Literal(true)),
          RequestAction(
            endpoint: Literal('/save'),
            onComplete: [UpdateStateAction(path: 'busy', value: Literal(false))],
          ),
        ]),
        expect: () => [
          loaded(const {'busy': true}),
          loaded(const {'busy': false}),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'runs onComplete when a returned action fails, then skips the rest of the list',
        setUp: () => stubPerform(
          const Result.ok([UpdateStateAction(path: 'missing', op: Literal(UpdateOp.removeAt), value: Literal(0))]),
        ),
        build: build,
        seed: () => loaded(const {'count': 0}),
        act: (cubit) => cubit.dispatch(const [
          RequestAction(
            endpoint: Literal('/save'),
            onComplete: [UpdateStateAction(path: 'done', value: Literal(true))],
          ),
          UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment)),
        ]),
        expect: () => [
          loaded(const {'count': 0, 'done': true}),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'runs onComplete when onError fails',
        setUp: () => stubPerform(const Result.err(GenericActionOffline())),
        build: build,
        seed: () => loaded(const {'count': 0}),
        act: (cubit) => cubit.dispatch(const [
          RequestAction(
            endpoint: Literal('/save'),
            onError: [UpdateStateAction(path: 'missing', op: Literal(UpdateOp.removeAt), value: Literal(0))],
            onComplete: [UpdateStateAction(path: 'done', value: Literal(true))],
          ),
        ]),
        expect: () => [
          loaded(const {'count': 0, 'done': true}),
        ],
      );

      blocTest<GenericCubit, GenericState>(
        'a failed onComplete skips the rest of the list after a success',
        setUp: () => stubPerform(const Result.ok([])),
        build: build,
        seed: () => loaded(const {'count': 0}),
        act: (cubit) => cubit.dispatch(const [
          RequestAction(
            endpoint: Literal('/save'),
            onComplete: [UpdateStateAction(path: 'missing', op: Literal(UpdateOp.removeAt), value: Literal(0))],
          ),
          UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment)),
        ]),
        expect: () => const <GenericState>[],
      );

      blocTest<GenericCubit, GenericState>(
        'unresolved bindings fall back to their fallback, POST, or null',
        setUp: () => stubPerform(const Result.ok([])),
        build: build,
        seed: () => loaded(const {}),
        act: (cubit) => cubit.dispatch(const [
          RequestAction(
            method: Binding('missing.method'),
            endpoint: Literal('/save'),
            body: JsonObject({
              'name': JsonBinding(Binding('missing.name', fallback: 'Guest')),
              'email': JsonBinding(Binding('missing.email')),
            }),
          ),
        ]),
        verify: (_) => verify(
          () => actions.perform(method: RequestMethod.post, endpoint: '/save', body: {'name': 'Guest', 'email': null}),
        ).called(1),
      );

      blocTest<GenericCubit, GenericState>(
        'an unresolved endpoint skips the request, onError, and onComplete, and continues',
        build: build,
        seed: () => loaded(const {'count': 0}),
        act: (cubit) => cubit.dispatch(const [
          RequestAction(
            endpoint: Binding('missing'),
            onError: [UpdateStateAction(path: 'error', value: Literal(true))],
            onComplete: [UpdateStateAction(path: 'complete', value: Literal(true))],
          ),
          UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment)),
        ]),
        expect: () => [
          loaded(const {'count': 1}),
        ],
        verify: (_) => verifyNever(
          () => actions.perform(
            method: any(named: 'method'),
            endpoint: any(named: 'endpoint'),
            body: any(named: 'body'),
          ),
        ),
      );
    });

    group('effects', () {
      late GenericCubit cubit;

      setUp(() => cubit = build()..emit(loaded(const {'target': 'detail', 'id': '7', 'name': 'Ana', 'count': 0})));

      tearDown(() => cubit.close());

      test('navigate emits a navigate effect with defaults', () async {
        final effects = expectLater(cubit.effects, emits(const NavigateEffect(pageId: 'home')));
        await cubit.dispatch(const [NavigateAction(pageId: Literal('home'))]);
        await effects;
      });

      test('navigate resolves the page id, params, and replace', () async {
        final effects = expectLater(
          cubit.effects,
          emits(const NavigateEffect(pageId: 'detail', params: {'id': '7', 'tab': 'info'}, replace: true)),
        );
        await cubit.dispatch(const [
          NavigateAction(
            pageId: Binding('target'),
            params: Literal({'id': '7', 'tab': 'info'}),
            replace: Literal(true),
          ),
        ]);
        await effects;
      });

      test('navigate without a resolved page id emits nothing and continues', () async {
        final effects = expectLater(cubit.effects, emits(const BackEffect()));
        await cubit.dispatch(const [NavigateAction(pageId: Binding('missing')), BackAction()]);
        await effects;
      });

      test('back emits a back effect', () async {
        final effects = expectLater(cubit.effects, emits(const BackEffect()));
        await cubit.dispatch(const [BackAction()]);
        await effects;
      });

      test('showMessage emits the resolved text', () async {
        final effects = expectLater(
          cubit.effects,
          emitsInOrder(const [ShowMessageEffect(text: 'saved'), ShowMessageEffect(text: 'Ana')]),
        );
        await cubit.dispatch(const [
          ShowMessageAction(text: Literal('saved')),
          ShowMessageAction(text: Binding('name')),
        ]);
        await effects;
      });

      test('showMessage without resolved text emits nothing and continues', () async {
        final effects = expectLater(cubit.effects, emits(const BackEffect()));
        await cubit.dispatch(const [ShowMessageAction(text: Binding('missing')), BackAction()]);
        await effects;
      });

      test('effects run in order with state updates', () async {
        final effects = expectLater(
          cubit.effects,
          emitsInOrder(const [ShowMessageEffect(text: '1'), NavigateEffect(pageId: 'detail', replace: true)]),
        );
        await cubit.dispatch(const [
          UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment)),
          ShowMessageAction(text: Binding('count')),
          NavigateAction(pageId: Binding('target'), replace: Literal(true)),
        ]);
        await effects;
        expect(cubit.state.values.get('count'), 1);
      });

      test('a failed action stops later effects', () async {
        final effects = expectLater(cubit.effects, emitsInOrder([const BackEffect(), emitsDone]));
        await cubit.dispatch(const [
          BackAction(),
          UpdateStateAction(path: 'name', op: Literal(UpdateOp.increment)),
          ShowMessageAction(text: Literal('unreachable')),
        ]);
        await cubit.close();
        await effects;
      });

      test('the stream is broadcast', () async {
        final first = expectLater(cubit.effects, emits(const BackEffect()));
        final second = expectLater(cubit.effects, emits(const BackEffect()));
        await cubit.dispatch(const [BackAction()]);
        await Future.wait([first, second]);
      });

      test('close closes the stream', () async {
        final effects = expectLater(cubit.effects, emitsDone);
        await cubit.close();
        await effects;
      });
    });
  });
}
