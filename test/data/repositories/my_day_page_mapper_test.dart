import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/repositories/my_day_page_mapper.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable_json.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

final _today = DateTime(2026, 11, 15);

Map<String, Object?> _row(
  String id, {
  String? title,
  String? start,
  String? end,
  String? status,
  String? edited,
  Map<String, Object?>? icon,
}) => {
  'object': 'page',
  'id': id,
  'icon': icon,
  'last_edited_time': ?edited,
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

GenericPage _map(List<Map<String, Object?>> rows, {DateTime? day}) =>
    MyDayPageMapper.fromRows(rows, day: day ?? _today, today: _today);

List<GenericAction> _selectDay(String pageId, String date) => [
  RequestAction(
    method: const Literal(RequestMethod.put),
    endpoint: const Literal(MyDayPageMapper.selectedDayEndpoint),
    body: JsonObject({'pageId': JsonLiteral(pageId), 'date': JsonLiteral(date)}),
  ),
];

DayPickerNode _dayPicker(
  String pageId, {
  String label = 'Sun, Nov 15',
  String? previous = '2026-11-14',
  String? next = '2026-11-16',
}) => DayPickerNode(
  id: 'dayPicker',
  label: Literal(label),
  previousLabel: const Literal(MyDayPageMapper.previousDayLabel),
  nextLabel: const Literal(MyDayPageMapper.nextDayLabel),
  onPrevious: previous == null ? const [] : _selectDay(pageId, previous),
  onNext: next == null ? const [] : _selectDay(pageId, next),
);

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
  ProgressBarNode,
  IconButtonNode,
  DayPickerNode,
};

const _refresh = IconButtonNode(
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

const _footer = RowNode(
  id: 'footer',
  alignment: Literal(AlignmentToken.center),
  children: [
    ExpandedNode(
      id: 'footerStart',
      child: ContainerNode(id: 'footerStartSlot', child: _refresh),
    ),
    IconButtonNode(
      id: 'openClaude',
      icon: Literal(IconToken.edit),
      label: Literal('Open Claude'),
      onTap: [OpenUrlAction(url: Literal('https://claude.ai/new'))],
    ),
  ],
);

ProgressBarNode _progress(int max) => ProgressBarNode(
  id: 'progress',
  value: const Binding(MyDayPageMapper.progressDonePath, fallback: 0),
  max: Literal(max),
);

ContainerNode _progressBar(int max) => ContainerNode(
  id: 'progressBar',
  padding: const Literal(SpacingToken.md),
  alignment: const Literal(AlignmentToken.stretch),
  child: _progress(max),
);

const _openMyDay = [NavigateAction(pageId: Literal(MyDayPageMapper.pageId))];

GenericPage _mapWidget(List<Map<String, Object?>> rows, {DateTime? day}) =>
    MyDayPageMapper.widgetFromRows(rows, day: day ?? _today, today: _today);

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
    test('builds an app bar, a day picker, a progress bar, and a refreshable scroll with a tile per row', () {
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
            'progress': {'done': 0},
          }),
          root: ColumnNode(
            id: 'root',
            children: [
              const AppBarNode(id: 'appBar', title: Literal(MyDayPageMapper.title)),
              _dayPicker(MyDayPageMapper.pageId),
              _progressBar(1),
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

    test('keeps only rows dated the selected day', () {
      final rows = [
        _row('today', start: '2026-11-15'),
        _row('tomorrow', start: '2026-11-16'),
        _row('lateTomorrow', start: _utc(DateTime(2026, 11, 16, 23, 30))),
        _row('later', start: '2026-11-17'),
      ];

      expect(_ids(_map(rows, day: DateTime(2026, 11, 16))), ['task-tomorrow', 'task-lateTomorrow']);
      expect(_ids(_mapWidget(rows, day: DateTime(2026, 11, 16))), ['task-tomorrow', 'task-lateTomorrow']);
    });

    test('labels the picker with the selected day and selects the days around it', () {
      expect(
        _map(const [], day: DateTime(2026, 11, 20)).nodes.whereType<DayPickerNode>().single,
        _dayPicker(MyDayPageMapper.pageId, label: 'Fri, Nov 20', previous: '2026-11-19', next: '2026-11-21'),
      );
      expect(
        _mapWidget(const [], day: DateTime(2026, 11, 14)).nodes.whereType<DayPickerNode>().single,
        _dayPicker(MyDayPageMapper.widgetPageId, label: 'Sat, Nov 14', previous: '2026-11-13', next: '2026-11-15'),
      );
    });

    test('stops the picker at seven days before today', () {
      final day = DateTime(2026, 11, 8);

      expect(
        _map(const [], day: day).nodes.whereType<DayPickerNode>().single,
        _dayPicker(MyDayPageMapper.pageId, label: 'Sun, Nov 8', previous: null, next: '2026-11-09'),
      );
      expect(
        _mapWidget(const [], day: day).nodes.whereType<DayPickerNode>().single,
        _dayPicker(MyDayPageMapper.widgetPageId, label: 'Sun, Nov 8', previous: null, next: '2026-11-09'),
      );
    });

    test('stops the picker at seven days after today', () {
      final day = DateTime(2026, 11, 22);

      expect(
        _map(const [], day: day).nodes.whereType<DayPickerNode>().single,
        _dayPicker(MyDayPageMapper.pageId, label: 'Sun, Nov 22', previous: '2026-11-21', next: null),
      );
      expect(
        _mapWidget(const [], day: day).nodes.whereType<DayPickerNode>().single,
        _dayPicker(MyDayPageMapper.widgetPageId, label: 'Sun, Nov 22', previous: '2026-11-21', next: null),
      );
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

    test('puts completed rows last, most recently completed first', () {
      final page = _map([
        _row('doneEarly', start: '2026-11-15', status: 'Done', edited: _utc(DateTime(2026, 11, 15, 8))),
        _row('afternoon', start: _utc(DateTime(2026, 11, 15, 14)), status: 'To do'),
        _row(
          'skippedLate',
          start: _utc(DateTime(2026, 11, 15, 9)),
          status: 'Skipped',
          edited: _utc(DateTime(2026, 11, 15, 11)),
        ),
        _row('allDay', start: '2026-11-15'),
        _row('doneUnknown', start: '2026-11-15', status: 'Done'),
        _row(
          'doneMid',
          start: _utc(DateTime(2026, 11, 15, 7)),
          status: 'Done',
          edited: _utc(DateTime(2026, 11, 15, 10)),
        ),
        _row(
          'doneTieLater',
          start: _utc(DateTime(2026, 11, 15, 10)),
          status: 'Done',
          edited: _utc(DateTime(2026, 11, 15, 9)),
        ),
        _row(
          'doneTieEarlier',
          start: _utc(DateTime(2026, 11, 15, 6)),
          status: 'Done',
          edited: _utc(DateTime(2026, 11, 15, 9)),
        ),
      ]);

      expect(_ids(page), [
        'task-allDay',
        'task-afternoon',
        'task-skippedLate',
        'task-doneMid',
        'task-doneTieEarlier',
        'task-doneTieLater',
        'task-doneEarly',
        'task-doneUnknown',
      ]);
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
          'progress': {'done': 3},
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

    test('shows nothing planned for an empty day', () {
      final empty = GenericPage(
        id: MyDayPageMapper.pageId,
        state: GenericValues(const {
          'tasks': <String, Object?>{},
          'progress': {'done': 0},
        }),
        root: ColumnNode(
          id: 'root',
          children: [
            const AppBarNode(id: 'appBar', title: Literal(MyDayPageMapper.title)),
            _dayPicker(MyDayPageMapper.pageId),
            _progressBar(0),
            const ExpandedNode(
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
    test('orders tiles like the app, with completed rows last and most recent first', () {
      final rows = [
        _row('doneEarly', start: '2026-11-15', status: 'Done', edited: _utc(DateTime(2026, 11, 15, 8))),
        _row('open', start: _utc(DateTime(2026, 11, 15, 14))),
        _row(
          'doneLate',
          start: _utc(DateTime(2026, 11, 15, 9)),
          status: 'Done',
          edited: _utc(DateTime(2026, 11, 15, 11)),
        ),
      ];

      expect(_ids(_mapWidget(rows)), ['task-open', 'task-doneLate', 'task-doneEarly']);
      expect(_ids(_mapWidget(rows)), _ids(_map(rows)));
    });

    test('builds a day picker, a progress bar, and a scroll of the same tiles without refresh', () {
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
            spacing: const Literal(SpacingToken.sm),
            children: [
              _dayPicker(MyDayPageMapper.widgetPageId),
              _progress(2),
              ExpandedNode(
                id: 'body',
                child: ScrollNode(
                  id: 'scroll',
                  child: ColumnNode(id: 'tasks', children: [appTiles[0], appTiles[1]]),
                ),
              ),
              _footer,
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
          'progress': {'done': 1},
        }),
      );
      _expectWidgetSafe(page);
    });

    test('shows nothing planned outside the scroll for an empty day', () {
      final empty = GenericPage(
        id: MyDayPageMapper.widgetPageId,
        state: GenericValues(const {
          'tasks': <String, Object?>{},
          'progress': {'done': 0},
        }),
        root: ColumnNode(
          id: 'root',
          spacing: const Literal(SpacingToken.sm),
          children: [
            _dayPicker(MyDayPageMapper.widgetPageId),
            _progress(0),
            const ExpandedNode(
              id: 'body',
              child: ContainerNode(
                id: 'empty',
                padding: Literal(SpacingToken.md),
                alignment: Literal(AlignmentToken.center),
                child: TextNode(id: 'emptyText', text: Literal(MyDayPageMapper.emptyText)),
              ),
            ),
            _footer,
          ],
        ),
      );

      expect(_mapWidget(const []), empty);
      expect(_mapWidget([_row('tomorrow', start: '2026-11-16')]), empty);
      _expectWidgetSafe(empty);
    });

    test('ends with a footer whose open claude button sits after an expanded start slot', () {
      for (final rows in [
        const <Map<String, Object?>>[],
        [_row('gym', start: '2026-11-15')],
      ]) {
        final root = _mapWidget(rows).root as ColumnNode;

        expect(root.children.last, _footer);
      }
    });

    test('starts the footer with a refresh button that spins until the reload completes', () {
      final root = _mapWidget([_row('gym', start: '2026-11-15')]).root as ColumnNode;
      final footer = root.children.last as RowNode;
      final start = footer.children.first as ExpandedNode;

      expect(start.child, isA<ContainerNode>().having((slot) => slot.child, 'child', _refresh));
    });

    test('leaves refreshing out of the state so the refresh button starts idle', () {
      for (final rows in [
        const <Map<String, Object?>>[],
        [_row('gym', start: '2026-11-15')],
      ]) {
        final page = _mapWidget(rows);

        expect(page.state?.get(MyDayPageMapper.refreshingPath), isNull);
        expect(_refresh.loading.resolve(page.state ?? GenericValues.empty), isFalse);
      }
    });

    test('opens claude in a new chat', () {
      expect(MyDayPageMapper.claudeUrl, 'https://claude.ai/new');
      expect(_mapWidget(const []).actions.whereType<OpenUrlAction>(), [
        const OpenUrlAction(url: Literal(MyDayPageMapper.claudeUrl)),
      ]);
    });
  });

  group('$MyDayPageMapper selected day', () {
    test('formats and strictly parses dates', () {
      expect(MyDayPageMapper.formatDate(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
      expect(MyDayPageMapper.parseDate('2026-03-05'), DateTime(2026, 3, 5));
      for (final value in ['2026-02-30', '2026-3-5', '2026-03-05T10:00', 'today', '', 20260305, null]) {
        expect(MyDayPageMapper.parseDate(value), isNull, reason: '$value');
      }
    });

    test('keeps days within seven days of today', () {
      for (final day in [DateTime(2026, 11, 8), _today, DateTime(2026, 11, 22)]) {
        expect(MyDayPageMapper.clampDay(day, today: _today), day);
      }
      expect(MyDayPageMapper.clampDay(DateTime(2026, 11, 16, 18), today: _today), DateTime(2026, 11, 16));
    });

    test('clamps days outside the window to its nearest bound', () {
      expect(MyDayPageMapper.clampDay(DateTime(2026, 11, 7), today: _today), DateTime(2026, 11, 8));
      expect(MyDayPageMapper.clampDay(DateTime(2025, 6, 10), today: _today), DateTime(2026, 11, 8));
      expect(MyDayPageMapper.clampDay(DateTime(2026, 11, 23), today: _today), DateTime(2026, 11, 22));
      expect(MyDayPageMapper.clampDay(DateTime(2026, 12, 31), today: _today), DateTime(2026, 11, 22));
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
