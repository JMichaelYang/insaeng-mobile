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

      expect(_subtitles(page), {'task-earlyToday': const Literal('00:30'), 'task-lateToday': const Literal('23:30')});
    });

    test('shows the local time range of timed rows', () {
      final page = _map([
        _row('meeting', start: _seoul(DateTime(2026, 11, 15, 9)), end: _utc(DateTime(2026, 11, 15, 10, 30))),
      ]);

      expect(_subtitles(page), {'task-meeting': const Literal('09:00–10:30')});
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
        'task-skippedMeeting': const Literal('09:00 · ${MyDayPageMapper.skippedText}'),
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
}
