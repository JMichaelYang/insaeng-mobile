import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/repositories/my_day_page_mapper.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable_json.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

final _now = DateTime(2026, 11, 15, 12);

Map<String, Object?> _row(
  String id, {
  String? title,
  String? start,
  String? end,
  String? status,
  Map<String, Object?>? icon,
}) => {
  'object': 'page',
  'id': id,
  'icon': icon,
  'properties': {
    'Name': {
      'type': 'title',
      'title': [
        {'type': 'text', 'plain_text': title ?? id},
      ],
    },
    'Date': {
      'type': 'date',
      'date': start == null ? null : {'start': start, 'end': end, 'time_zone': null},
    },
    'Status': {
      'type': 'status',
      'status': status == null ? null : {'name': status},
    },
  },
};

List<GenericAction> _checkActions(String id) => [
  UpdateStateAction(path: 'tasks.$id.saving', value: const Literal(true)),
  RequestAction(
    method: const Literal(RequestMethod.patch),
    endpoint: Literal('/my-day/tasks/$id'),
    body: JsonObject({'done': JsonBinding(Binding('tasks.$id.done'))}),
    onError: [
      UpdateStateAction(path: 'tasks.$id.done', op: const Literal(UpdateOp.toggle)),
      const ShowMessageAction(text: Literal(MyDayPageMapper.saveErrorText)),
    ],
    onComplete: [UpdateStateAction(path: 'tasks.$id.saving', value: const Literal(false))],
  ),
];

String _utc(DateTime local) => local.toUtc().toIso8601String();

String _seoul(DateTime local) {
  final shifted = local.toUtc().add(const Duration(hours: 9)).toIso8601String();
  return '${shifted.substring(0, shifted.length - 1)}+09:00';
}

GenericPage _map(List<Map<String, Object?>> rows) => MyDayPageMapper.fromRows(rows, now: _now);

List<CheckboxTileNode> _tiles(GenericPage page) => page.nodes.whereType<CheckboxTileNode>().toList();

List<String> _ids(GenericPage page) => [for (final tile in _tiles(page)) tile.id];

List<String> _rowIds(GenericPage page) => [
  for (final node in page.nodes)
    if (node is CheckboxTileNode || node is DividerNode) node.id,
];

const _widgetNodeTypes = {
  ColumnNode,
  RowNode,
  ContainerNode,
  ExpandedNode,
  SpacerNode,
  DividerNode,
  TextNode,
  ButtonNode,
  CheckboxTileNode,
  ScrollNode,
};

const _openMyDay = [NavigateAction(pageId: Literal(MyDayPageMapper.pageId))];

GenericPage _mapWidget(List<Map<String, Object?>> rows) => MyDayPageMapper.widgetFromRows(rows, now: _now);

void _expectWidgetSafe(GenericPage page) {
  final ids = [for (final node in page.nodes) node.id];

  expect(ids.toSet(), hasLength(ids.length));
  expect({for (final node in page.nodes) node.runtimeType}.difference(_widgetNodeTypes), isEmpty);
  expect(page.nodes.whereType<ScrollNode>().expand((scroll) => scroll.onRefresh), isEmpty);
  expect(page.actions.whereType<NavigateAction>(), everyElement(_openMyDay.single));
}

Map<String, Bindable<String>?> _subtitles(GenericPage page) => {
  for (final tile in _tiles(page)) tile.id: tile.subtitle,
};

void main() {
  group(MyDayPageMapper, () {
    test('builds an app bar and a refreshable scroll with a tile per row', () {
      expect(
        _map([
          _row('a', title: 'Gym', start: '2026-11-15', icon: {'type': 'emoji', 'emoji': '🏋️'}),
        ]),
        GenericPage(
          id: MyDayPageMapper.pageId,
          state: GenericValues(const {
            'tasks': {
              'a': {'done': false, 'saving': false},
            },
          }),
          root: ColumnNode(
            id: 'root',
            children: [
              const AppBarNode(id: 'appBar', title: Literal(MyDayPageMapper.title)),
              ExpandedNode(
                id: 'body',
                child: ScrollNode(
                  id: 'scroll',
                  onRefresh: const [ReloadAction()],
                  child: ColumnNode(
                    id: 'tasks',
                    children: [
                      CheckboxTileNode(
                        id: 'task-a',
                        bind: 'tasks.a.done',
                        emoji: const Literal('🏋️'),
                        title: const Literal('Gym'),
                        busy: const Binding('tasks.a.saving', fallback: false),
                        onChanged: _checkActions('a'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });

    test('marks each tile saving, patches its done value, and undoes the check with a message on error', () {
      final page = _map([
        _row('a', start: '2026-11-15'),
        _row('b', start: _utc(DateTime(2026, 11, 15, 9)), status: 'Done'),
      ]);

      expect(
        {for (final tile in _tiles(page)) tile.id: tile.onChanged},
        {'task-a': _checkActions('a'), 'task-b': _checkActions('b')},
      );
    });

    test('shows the page emoji and falls back to a task emoji for other icons', () {
      final page = _map([
        _row('emoji', start: '2026-11-15', icon: {'type': 'emoji', 'emoji': '🧘'}),
        _row('noIcon', start: '2026-11-15'),
        _row(
          'file',
          start: '2026-11-15',
          icon: {
            'type': 'file',
            'file': {'url': 'https://example.com/icon.png'},
          },
        ),
        _row(
          'external',
          start: '2026-11-15',
          icon: {
            'type': 'external',
            'external': {'url': 'https://example.com/icon.png'},
          },
        ),
      ]);

      expect(
        {for (final tile in _tiles(page)) tile.id: tile.emoji},
        {
          'task-emoji': const Literal('🧘'),
          'task-noIcon': const Literal(MyDayPageMapper.fallbackEmoji),
          'task-file': const Literal(MyDayPageMapper.fallbackEmoji),
          'task-external': const Literal(MyDayPageMapper.fallbackEmoji),
        },
      );
    });

    test('keeps only all-day rows dated today', () {
      final page = _map([
        _row('yesterday', start: '2026-11-14'),
        _row('today', start: '2026-11-15'),
        _row('tomorrow', start: '2026-11-16'),
        _row('spanning', start: '2026-11-14', end: '2026-11-16'),
      ]);

      expect(_subtitles(page), {'task-today': null});
    });

    test('keeps timed rows that start today in the local time zone', () {
      final page = _map([
        _row('lateYesterday', start: _utc(DateTime(2026, 11, 14, 23, 59))),
        _row('earlyToday', start: _utc(DateTime(2026, 11, 15, 0, 30))),
        _row('lateToday', start: _seoul(DateTime(2026, 11, 15, 23, 30))),
        _row('earlyTomorrow', start: _seoul(DateTime(2026, 11, 16))),
      ]);

      expect(_subtitles(page), {
        'task-earlyToday': const Literal('12:30 AM'),
        'task-lateToday': const Literal('11:30 PM'),
      });
    });

    test('shows the local time range of timed rows', () {
      final page = _map([
        _row('meeting', start: _seoul(DateTime(2026, 11, 15, 9)), end: _utc(DateTime(2026, 11, 15, 10, 30))),
      ]);

      expect(_subtitles(page), {'task-meeting': const Literal('9:00 – 10:30 AM')});
    });

    test('formats times as 12-hour and repeats the period only when a range crosses it', () {
      final page = _map([
        _row('midnight', start: _utc(DateTime(2026, 11, 15)), end: _utc(DateTime(2026, 11, 15, 0, 45))),
        _row('morning', start: _utc(DateTime(2026, 11, 15, 8, 10)), end: _utc(DateTime(2026, 11, 15, 8, 15))),
        _row('crossNoon', start: _utc(DateTime(2026, 11, 15, 11, 30)), end: _utc(DateTime(2026, 11, 15, 13))),
        _row('noon', start: _utc(DateTime(2026, 11, 15, 12)), end: _utc(DateTime(2026, 11, 15, 12, 30))),
        _row('afternoon', start: _utc(DateTime(2026, 11, 15, 14)), end: _utc(DateTime(2026, 11, 15, 15, 30))),
        _row('evening', start: _utc(DateTime(2026, 11, 15, 21, 5))),
      ]);

      expect(_subtitles(page), {
        'task-midnight': const Literal('12:00 – 12:45 AM'),
        'task-morning': const Literal('8:10 – 8:15 AM'),
        'task-crossNoon': const Literal('11:30 AM – 1:00 PM'),
        'task-noon': const Literal('12:00 – 12:30 PM'),
        'task-afternoon': const Literal('2:00 – 3:30 PM'),
        'task-evening': const Literal('9:05 PM'),
      });
    });

    test('puts a divider between rows but not after the last one', () {
      expect(_rowIds(_map(const [])), isEmpty);
      expect(_rowIds(_map([_row('a', start: '2026-11-15')])), ['task-a']);
      expect(
        _rowIds(
          _map([
            _row('c', start: _utc(DateTime(2026, 11, 15, 10))),
            _row('a', start: '2026-11-15'),
            _row('b', start: _utc(DateTime(2026, 11, 15, 9))),
          ]),
        ),
        ['task-a', 'divider-a', 'task-b', 'divider-b', 'task-c'],
      );
    });

    test('puts all-day rows first, then sorts by start', () {
      final page = _map([
        _row('afternoon', start: _utc(DateTime(2026, 11, 15, 14))),
        _row('allDayFirst', start: '2026-11-15'),
        _row('morning', start: _utc(DateTime(2026, 11, 15, 8))),
        _row('allDaySecond', start: '2026-11-15'),
        _row('noon', start: _seoul(DateTime(2026, 11, 15, 12))),
      ]);

      expect(_ids(page), ['task-allDayFirst', 'task-allDaySecond', 'task-morning', 'task-noon', 'task-afternoon']);
    });

    test('checks done and skipped rows and labels skipped ones', () {
      final page = _map([
        _row('done', start: '2026-11-15', status: 'Done'),
        _row('skipped', start: '2026-11-15', status: 'Skipped'),
        _row('todo', start: '2026-11-15', status: 'To do'),
        _row('noStatus', start: '2026-11-15'),
        _row('skippedMeeting', start: _utc(DateTime(2026, 11, 15, 9)), status: 'Skipped'),
      ]);

      expect(
        page.initialState,
        GenericValues(const {
          'tasks': {
            'done': {'done': true, 'saving': false},
            'skipped': {'done': true, 'saving': false},
            'todo': {'done': false, 'saving': false},
            'noStatus': {'done': false, 'saving': false},
            'skippedMeeting': {'done': true, 'saving': false},
          },
        }),
      );
      expect(_subtitles(page), {
        'task-done': null,
        'task-skipped': const Literal(MyDayPageMapper.skippedText),
        'task-todo': null,
        'task-noStatus': null,
        'task-skippedMeeting': const Literal('9:00 AM · ${MyDayPageMapper.skippedText}'),
      });
    });

    test('joins the title text and skips rows without a date', () {
      final page = _map([
        _row('undated'),
        {
          'id': 'split',
          'properties': {
            'Task': {
              'type': 'title',
              'title': [
                {'plain_text': 'Call '},
                {'plain_text': 'Mom'},
              ],
            },
            'Date': {
              'date': {'start': '2026-11-15'},
            },
          },
        },
      ]);

      expect([for (final tile in _tiles(page)) tile.title], [const Literal('Call Mom')]);
    });

    test('shows nothing planned today for an empty day', () {
      final empty = GenericPage(
        id: MyDayPageMapper.pageId,
        state: GenericValues(const {'tasks': <String, Object?>{}}),
        root: const ColumnNode(
          id: 'root',
          children: [
            AppBarNode(id: 'appBar', title: Literal(MyDayPageMapper.title)),
            ExpandedNode(
              id: 'body',
              child: ScrollNode(
                id: 'scroll',
                onRefresh: [ReloadAction()],
                child: ContainerNode(
                  id: 'empty',
                  padding: Literal(SpacingToken.md),
                  alignment: Literal(AlignmentToken.center),
                  child: TextNode(id: 'emptyText', text: Literal(MyDayPageMapper.emptyText)),
                ),
              ),
            ),
          ],
        ),
      );

      expect(_map(const []), empty);
      expect(_map([_row('tomorrow', start: '2026-11-16')]), empty);
    });
  });

  group('$MyDayPageMapper.widgetFromRows', () {
    test('builds a title that opens My Day and a scroll of the same tiles without refresh', () {
      final rows = [
        _row('b', title: 'Meeting', start: _utc(DateTime(2026, 11, 15, 9)), status: 'Done'),
        _row('a', title: 'Gym', start: '2026-11-15', icon: {'type': 'emoji', 'emoji': '🏋️'}),
        _row('tomorrow', start: '2026-11-16'),
      ];
      final page = _mapWidget(rows);
      final appTiles = _tiles(_map(rows));

      expect(
        page,
        GenericPage(
          id: MyDayPageMapper.widgetPageId,
          state: _map(rows).state,
          root: ColumnNode(
            id: 'root',
            children: [
              ExpandedNode(
                id: 'body',
                child: ScrollNode(
                  id: 'scroll',
                  child: ColumnNode(
                    id: 'tasks',
                    children: [
                      appTiles[0],
                      const DividerNode(id: 'divider-a'),
                      appTiles[1],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      expect(_ids(page), ['task-a', 'task-b']);
      expect(
        page.initialState,
        GenericValues(const {
          'tasks': {
            'a': {'done': false, 'saving': false},
            'b': {'done': true, 'saving': false},
          },
        }),
      );
      _expectWidgetSafe(page);
    });

    test('shows nothing planned today for an empty day', () {
      final empty = GenericPage(
        id: MyDayPageMapper.widgetPageId,
        state: GenericValues(const {'tasks': <String, Object?>{}}),
        root: const ColumnNode(
          id: 'root',
          children: [
            ExpandedNode(
              id: 'body',
              child: ScrollNode(
                id: 'scroll',
                child: ContainerNode(
                  id: 'empty',
                  padding: Literal(SpacingToken.md),
                  alignment: Literal(AlignmentToken.center),
                  child: TextNode(id: 'emptyText', text: Literal(MyDayPageMapper.emptyText)),
                ),
              ),
            ),
          ],
        ),
      );

      expect(_mapWidget(const []), empty);
      expect(_mapWidget([_row('tomorrow', start: '2026-11-16')]), empty);
      _expectWidgetSafe(empty);
    });
  });

  group('$MyDayPageMapper.widgetConnectPage', () {
    const page = MyDayPageMapper.widgetConnectPage;

    test('asks to connect Notion in the app with a prompt that opens My Day', () {
      expect(
        page,
        const GenericPage(
          id: MyDayPageMapper.widgetPageId,
          root: ColumnNode(
            id: 'root',
            children: [
              ExpandedNode(
                id: 'body',
                child: ContainerNode(
                  id: 'connect',
                  padding: Literal(SpacingToken.md),
                  alignment: Literal(AlignmentToken.center),
                  child: ButtonNode(
                    id: 'connectPrompt',
                    label: Literal(MyDayPageMapper.connectInAppText),
                    variant: Literal(ButtonVariant.text),
                    onTap: _openMyDay,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });

    test('uses only widget nodes and actions', () {
      _expectWidgetSafe(page);
    });
  });
}
