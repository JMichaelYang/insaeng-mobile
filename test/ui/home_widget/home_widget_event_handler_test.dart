import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable_json.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/models/home_widget/widget_snapshot.dart';
import 'package:insaeng/domain/models/home_widget/widget_snapshot_resolver.dart';
import 'package:insaeng/domain/repositories/generic_action_repository.dart';
import 'package:insaeng/domain/repositories/generic_page_repository.dart';
import 'package:insaeng/domain/repositories/widget_snapshot_repository.dart';
import 'package:insaeng/domain/result.dart';
import 'package:insaeng/ui/home_widget/home_widget_event_handler.dart';
import 'package:mocktail/mocktail.dart';

class _MockGenericPageRepository extends Mock implements GenericPageRepository;

class _MockGenericActionRepository extends Mock implements GenericActionRepository;

class _MockWidgetSnapshotRepository extends Mock implements WidgetSnapshotRepository;

const String _pageId = 'myDayWidget';

CheckboxTileNode _tile(String id) => CheckboxTileNode(
  id: 'task-$id',
  bind: 'tasks.$id.done',
  title: Literal(id),
  busy: Binding('tasks.$id.saving', fallback: false),
  onChanged: [
    UpdateStateAction(path: 'tasks.$id.saving', value: const Literal(true)),
    RequestAction(
      method: const Literal(RequestMethod.patch),
      endpoint: Literal('/my-day/tasks/$id'),
      body: JsonObject({'done': JsonBinding(Binding('tasks.$id.done'))}),
      onError: [UpdateStateAction(path: 'tasks.$id.done', op: const Literal(UpdateOp.toggle))],
      onComplete: [UpdateStateAction(path: 'tasks.$id.saving', value: const Literal(false))],
    ),
  ],
);

final GenericPage _page = GenericPage(
  id: _pageId,
  root: ColumnNode(
    id: 'root',
    children: [
      _tile('a'),
      _tile('b'),
      const ButtonNode(
        id: 'save',
        label: Literal('Save'),
        onTap: [UpdateStateAction(path: 'saved', value: Literal(true))],
      ),
    ],
  ),
);

final GenericValues _values = GenericValues(const {
  'saved': false,
  'tasks': {
    'a': {'done': false, 'saving': false},
    'b': {'done': true, 'saving': false},
  },
});

final GenericPage _sortedPage = GenericPage(
  id: _pageId,
  root: ColumnNode(id: 'root', children: [_tile('b'), _tile('a')]),
  state: GenericValues(const {
    'tasks': {
      'b': {'done': false, 'saving': false},
      'a': {'done': true, 'saving': false},
    },
  }),
);

const IconButtonNode _refresh = IconButtonNode(
  id: 'refresh',
  icon: Literal(IconToken.refresh),
  label: Literal('Refresh'),
  loading: Binding('refreshing', fallback: false),
  onTap: [
    UpdateStateAction(path: 'refreshing', value: Literal(true)),
    ReloadAction(
      onComplete: [UpdateStateAction(path: 'refreshing', value: Literal(false))],
    ),
  ],
);

final GenericPage _refreshPage = GenericPage(
  id: _pageId,
  root: ColumnNode(id: 'root', children: [_tile('a'), _tile('b'), _refresh]),
);

final GenericPage _refreshedPage = GenericPage(
  id: _pageId,
  root: ColumnNode(id: 'root', children: [_tile('b'), _tile('a'), _refresh]),
  state: _sortedPage.state,
);

Uri _uri({required String node, String page = _pageId, String event = 'onChanged'}) => Uri(
  scheme: 'insaeng',
  host: 'widget',
  path: '/event',
  queryParameters: {'flavor': 'dev', 'page': page, 'node': node, 'event': event},
);

void main() {
  group(HomeWidgetEventHandler, () {
    late GenericPageRepository pages;
    late GenericActionRepository actions;
    late WidgetSnapshotRepository snapshots;
    late HomeWidgetEventHandler handler;

    setUpAll(() {
      registerFallbackValue(
        const WidgetSnapshot(
          pageId: _pageId,
          root: WidgetNode(type: 'column', id: 'root'),
        ),
      );
      registerFallbackValue(_page);
      registerFallbackValue(GenericValues.empty);
      registerFallbackValue(RequestMethod.post);
    });

    setUp(() {
      pages = _MockGenericPageRepository();
      actions = _MockGenericActionRepository();
      snapshots = _MockWidgetSnapshotRepository();
      handler = HomeWidgetEventHandler(pages, actions, snapshots);
      when(() => snapshots.load(_pageId)).thenAnswer((_) async => Result.ok((page: _page, values: _values)));
      when(() => snapshots.load(any(that: isNot(_pageId))))
          .thenAnswer((_) async => const Result.err(WidgetSnapshotNotFound()));
      when(
        () => snapshots.save(
          any(),
          page: any(named: 'page'),
          values: any(named: 'values'),
        ),
      ).thenAnswer((_) async => const Result.ok(null));
      when(() => snapshots.update()).thenAnswer((_) async => const Result.ok(null));
      when(
        () => actions.perform(
          method: any(named: 'method'),
          endpoint: any(named: 'endpoint'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => const Result.ok([]));
      when(() => pages.fetch(any(), any())).thenAnswer((_) async => const Result.err(GenericPageOffline()));
    });

    (GenericPage, GenericValues) lastSaved() {
      final [..., page, values] = verify(
        () => snapshots.save(
          any(),
          page: captureAny(named: 'page'),
          values: captureAny(named: 'values'),
        ),
      ).captured;
      return (page as GenericPage, values as GenericValues);
    }

    List<GenericValues> savedValues() => verify(
      () => snapshots.save(
        any(),
        page: any(named: 'page'),
        values: captureAny(named: 'values'),
      ),
    ).captured.cast<GenericValues>();

    GenericValues valuesWith(Map<String, Object?> a, Map<String, Object?> b, {bool saved = false}) => GenericValues({
      'saved': saved,
      'tasks': {'a': a, 'b': b},
    });

    test('checks an unchecked task, saves every state, and updates the widget after each save', () async {
      await handler.handle(_uri(node: 'task-a'));

      verify(() => actions.perform(method: RequestMethod.patch, endpoint: '/my-day/tasks/a', body: {'done': true}))
          .called(1);
      expect(savedValues(), [
        valuesWith({'done': true, 'saving': false}, {'done': true, 'saving': false}),
        valuesWith({'done': true, 'saving': true}, {'done': true, 'saving': false}),
        valuesWith({'done': true, 'saving': false}, {'done': true, 'saving': false}),
      ]);
      verify(() => snapshots.update()).called(3);
    });

    test('saves the snapshot resolved from the page and values', () async {
      await handler.handle(_uri(node: 'task-b'));

      final [..., snapshot, page] = verify(
        () => snapshots.save(
          captureAny(),
          page: captureAny(named: 'page'),
          values: any(named: 'values'),
        ),
      ).captured;
      expect(page, _page);
      expect(
        snapshot,
        WidgetSnapshotResolver.resolve(
          _page,
          valuesWith({'done': false, 'saving': false}, {'done': false, 'saving': false}),
        ),
      );
    });

    test('reverts the check when the request fails', () async {
      when(
        () => actions.perform(
          method: any(named: 'method'),
          endpoint: any(named: 'endpoint'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => const Result.err(GenericActionOffline()));

      await handler.handle(_uri(node: 'task-a'));

      expect(savedValues(), [
        valuesWith({'done': true, 'saving': false}, {'done': true, 'saving': false}),
        valuesWith({'done': true, 'saving': true}, {'done': true, 'saving': false}),
        valuesWith({'done': false, 'saving': true}, {'done': true, 'saving': false}),
        valuesWith({'done': false, 'saving': false}, {'done': true, 'saving': false}),
      ]);
    });

    test('shares one cubit between rapid taps on different tasks', () async {
      final requests = {'/my-day/tasks/a': Completer<void>(), '/my-day/tasks/b': Completer<void>()};
      when(
        () => actions.perform(
          method: any(named: 'method'),
          endpoint: any(named: 'endpoint'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((invocation) async {
        await requests[invocation.namedArguments[#endpoint]]!.future;
        return const Result.ok([]);
      });

      final first = handler.handle(_uri(node: 'task-a'));
      final second = handler.handle(_uri(node: 'task-b'));
      await pumpEventQueue();

      verify(() => snapshots.load(_pageId)).called(1);
      verify(() => actions.perform(method: RequestMethod.patch, endpoint: '/my-day/tasks/a', body: {'done': true}))
          .called(1);
      verify(() => actions.perform(method: RequestMethod.patch, endpoint: '/my-day/tasks/b', body: {'done': false}))
          .called(1);

      requests['/my-day/tasks/b']!.complete();
      requests['/my-day/tasks/a']!.complete();
      await Future.wait([first, second]);

      expect(savedValues().last, valuesWith({'done': true, 'saving': false}, {'done': false, 'saving': false}));
    });

    test('reloads the page once the tap finishes and saves the re-sorted page', () async {
      when(() => pages.fetch(_pageId, const {})).thenAnswer((_) async => Result.ok(_sortedPage));

      await handler.handle(_uri(node: 'task-a'));

      verify(() => pages.fetch(_pageId, const {})).called(1);
      expect(lastSaved(), (_sortedPage, _sortedPage.state));
      verify(() => snapshots.update()).called(4);
    });

    test('keeps the tapped state when the reload fails', () async {
      await handler.handle(_uri(node: 'task-a'));

      verify(() => pages.fetch(_pageId, const {})).called(1);
      expect(lastSaved(), (_page, valuesWith({'done': true, 'saving': false}, {'done': true, 'saving': false})));
    });

    test('reloads once after rapid taps on different tasks have all finished', () async {
      final requests = {'/my-day/tasks/a': Completer<void>(), '/my-day/tasks/b': Completer<void>()};
      when(
        () => actions.perform(
          method: any(named: 'method'),
          endpoint: any(named: 'endpoint'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((invocation) async {
        await requests[invocation.namedArguments[#endpoint]]!.future;
        return const Result.ok([]);
      });

      final first = handler.handle(_uri(node: 'task-a'));
      final second = handler.handle(_uri(node: 'task-b'));
      await pumpEventQueue();
      requests['/my-day/tasks/a']!.complete();
      await pumpEventQueue();

      verifyNever(() => pages.fetch(any(), any()));

      requests['/my-day/tasks/b']!.complete();
      await Future.wait([first, second]);

      verify(() => pages.fetch(_pageId, const {})).called(1);
    });

    test('runs a tap that arrives during a reload against the reloaded page', () async {
      final reload = Completer<Result<GenericPage>>();
      when(() => pages.fetch(_pageId, const {})).thenAnswer((_) => reload.future);

      final first = handler.handle(_uri(node: 'task-a'));
      await pumpEventQueue();
      final second = handler.handle(_uri(node: 'task-b'));
      await pumpEventQueue();

      verifyNever(
        () => actions.perform(
          method: RequestMethod.patch,
          endpoint: '/my-day/tasks/b',
          body: any(named: 'body'),
        ),
      );

      when(() => pages.fetch(_pageId, const {})).thenAnswer((_) async => const Result.err(GenericPageOffline()));
      reload.complete(Result.ok(_sortedPage));
      await Future.wait([first, second]);

      verify(() => actions.perform(method: RequestMethod.patch, endpoint: '/my-day/tasks/b', body: {'done': true}))
          .called(1);
      verify(() => snapshots.load(_pageId)).called(1);
      verify(() => pages.fetch(_pageId, const {})).called(2);
      expect(lastSaved(), (
        _sortedPage,
        GenericValues(const {
          'tasks': {
            'b': {'done': true, 'saving': false},
            'a': {'done': true, 'saving': false},
          },
        }),
      ));
    });

    test('ignores a second tap on a task that is still saving', () async {
      final request = Completer<void>();
      when(
        () => actions.perform(
          method: any(named: 'method'),
          endpoint: any(named: 'endpoint'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async {
        await request.future;
        return const Result.ok([]);
      });

      final first = handler.handle(_uri(node: 'task-a'));
      await pumpEventQueue();
      await handler.handle(_uri(node: 'task-a'));
      request.complete();
      await first;

      verify(
        () => actions.perform(
          method: any(named: 'method'),
          endpoint: any(named: 'endpoint'),
          body: any(named: 'body'),
        ),
      ).called(1);
      expect(savedValues().last, valuesWith({'done': true, 'saving': false}, {'done': true, 'saving': false}));
    });

    test('accepts a tap on a task stored as saving when nothing is in flight', () async {
      when(() => snapshots.load(_pageId)).thenAnswer(
        (_) async => Result.ok((
          page: _page,
          values: valuesWith({'done': false, 'saving': true}, {'done': true, 'saving': false}),
        )),
      );

      await handler.handle(_uri(node: 'task-a'));

      verify(() => actions.perform(method: RequestMethod.patch, endpoint: '/my-day/tasks/a', body: {'done': true}))
          .called(1);
    });

    test('loads the stored page again once earlier taps have finished', () async {
      await handler.handle(_uri(node: 'task-a'));
      await handler.handle(_uri(node: 'task-a'));

      verify(() => snapshots.load(_pageId)).called(2);
    });

    test('dispatches the onTap actions of a button', () async {
      await handler.handle(_uri(node: 'save', event: 'onTap'));

      expect(savedValues(), [
        valuesWith({'done': false, 'saving': false}, {'done': true, 'saving': false}, saved: true),
      ]);
    });

    group('refresh button', () {
      setUp(() {
        when(() => snapshots.load(_pageId)).thenAnswer((_) async => Result.ok((page: _refreshPage, values: _values)));
      });

      List<(GenericPage, bool?)> saves() {
        final captured = verify(
          () => snapshots.save(
            any(),
            page: captureAny(named: 'page'),
            values: captureAny(named: 'values'),
          ),
        ).captured;
        return [
          for (var i = 0; i < captured.length; i += 2)
            (captured[i] as GenericPage, _refresh.loading.resolve(captured[i + 1] as GenericValues)),
        ];
      }

      test('shows loading, then saves the reloaded page with loading cleared', () async {
        when(() => pages.fetch(_pageId, const {})).thenAnswer((_) async => Result.ok(_refreshedPage));

        await handler.handle(_uri(node: 'refresh', event: 'onTap'));

        final [first, ...rest] = saves();
        expect(first, (_refreshPage, true));
        expect(rest, isNotEmpty);
        expect(rest, everyElement((_refreshedPage, false)));
        verify(() => snapshots.update()).called(1 + rest.length);
      });

      test('clears loading when the reload fails', () async {
        await handler.handle(_uri(node: 'refresh', event: 'onTap'));

        expect(saves(), [(_refreshPage, true), (_refreshPage, false)]);
      });

      test('ignores a second tap while the refresh is still loading', () async {
        final reload = Completer<Result<GenericPage>>();
        when(() => pages.fetch(_pageId, const {})).thenAnswer((_) => reload.future);

        final first = handler.handle(_uri(node: 'refresh', event: 'onTap'));
        await pumpEventQueue();
        await handler.handle(_uri(node: 'refresh', event: 'onTap'));

        verify(() => pages.fetch(_pageId, const {})).called(1);

        reload.complete(Result.ok(_refreshedPage));
        await first;

        final loading = [for (final (_, loading) in saves()) loading];
        expect(loading.where((loading) => loading ?? false), hasLength(1));
        expect(loading.last, isFalse);
      });

      test('accepts a tap on a refresh stored as loading when nothing is in flight', () async {
        when(() => snapshots.load(_pageId)).thenAnswer(
          (_) async => Result.ok((page: _refreshPage, values: GenericValues({..._values.values, 'refreshing': true}))),
        );

        await handler.handle(_uri(node: 'refresh', event: 'onTap'));

        verify(() => pages.fetch(_pageId, const {})).called(2);
        expect(saves().last, (_refreshPage, false));
      });
    });

    for (final (event, offset) in [('onPrevious', -1), ('onNext', 1), ('onLabelTap', 7)]) {
      test('dispatches the $event actions of a day picker', () async {
        const page = GenericPage(
          id: _pageId,
          root: DayPickerNode(
            id: 'day',
            label: Literal('Mon, Jan 12'),
            previousLabel: Literal('Previous day'),
            nextLabel: Literal('Next day'),
            onPrevious: [UpdateStateAction(path: 'offset', op: Literal(UpdateOp.increment), value: Literal(-1))],
            onNext: [UpdateStateAction(path: 'offset', op: Literal(UpdateOp.increment))],
            onLabelTap: [UpdateStateAction(path: 'offset', value: Literal(7))],
          ),
        );
        when(() => snapshots.load(_pageId))
            .thenAnswer((_) async => Result.ok((page: page, values: GenericValues(const {'offset': 0}))));

        await handler.handle(_uri(node: 'day', event: event));

        expect(savedValues(), [
          GenericValues({'offset': offset}),
        ]);
      });
    }

    test('does nothing for an unknown node', () async {
      await handler.handle(_uri(node: 'missing'));

      verifyNever(() => pages.fetch(any(), any()));
      verifyNever(
        () => snapshots.save(
          any(),
          page: any(named: 'page'),
          values: any(named: 'values'),
        ),
      );
      verifyNever(() => snapshots.update());
    });

    test('does nothing for an event the node does not have', () async {
      await handler.handle(_uri(node: 'task-a', event: 'onTap'));

      verifyNever(() => snapshots.update());
    });

    test('does nothing for a page without a stored snapshot', () async {
      await handler.handle(_uri(page: 'other', node: 'task-a'));

      verify(() => snapshots.load('other')).called(1);
      verifyNever(() => snapshots.update());
      verifyNever(
        () => actions.perform(
          method: any(named: 'method'),
          endpoint: any(named: 'endpoint'),
          body: any(named: 'body'),
        ),
      );
    });

    test('does nothing for a URI missing the page, node, or event', () async {
      await handler.handle(null);
      await handler.handle(Uri.parse('insaeng://widget/event?page=$_pageId&node=task-a'));

      verifyNever(() => snapshots.load(any()));
    });
  });
}
