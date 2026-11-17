import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/data/repositories/my_day_page_mapper.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';
import 'package:insaeng/domain/models/home_widget/widget_snapshot.dart';
import 'package:insaeng/domain/models/home_widget/widget_snapshot_resolver.dart';

const _fixturePath = 'test/fixtures/widget_snapshots/my_day.json';

final _today = DateTime(2026, 11, 15);

WidgetNode _resolveNode(GenericNode node, [Map<String, Object?> values = const {}]) =>
    WidgetSnapshotResolver.resolve(GenericPage(id: 'page', root: node), GenericValues(values)).root;

Map<String, Object?> _row(String id, {required String title, required String start, String? end, String? status}) => {
  'object': 'page',
  'id': id,
  'icon': {'type': 'emoji', 'emoji': '✅'},
  'properties': {
    'Name': {
      'type': 'title',
      'title': [
        {'type': 'text', 'plain_text': title},
      ],
    },
    'Date': {
      'type': 'date',
      'date': {'start': start, 'end': end, 'time_zone': null},
    },
    'Status': {
      'type': 'status',
      'status': status == null ? null : {'name': status},
    },
  },
};

String _utc(DateTime local) => local.toUtc().toIso8601String();

WidgetSnapshot _myDaySnapshot() {
  final page = MyDayPageMapper.widgetFromRows(
    [
      _row('gym', title: 'Gym', start: '2026-11-15'),
      _row(
        'meeting',
        title: 'Team meeting',
        start: _utc(DateTime(2026, 11, 15, 9)),
        end: _utc(DateTime(2026, 11, 15, 10, 30)),
        status: 'Done',
      ),
      _row('lunch', title: 'Lunch', start: _utc(DateTime(2026, 11, 15, 12, 30)), status: 'Skipped'),
      _row('tomorrow', title: 'Tomorrow', start: '2026-11-16'),
    ],
    day: _today,
    today: _today,
  );
  return WidgetSnapshotResolver.resolve(page, page.initialState);
}

Object? _sorted(Object? value) => switch (value) {
  final Map<String, Object?> map => {for (final key in map.keys.toList()..sort()) key: _sorted(map[key])},
  final List<Object?> list => [for (final item in list) _sorted(item)],
  _ => value,
};

String _encode(WidgetSnapshot snapshot) => '${const JsonEncoder.withIndent('  ').convert(_sorted(snapshot.toMap()))}\n';

void main() {
  group(WidgetSnapshotResolver, () {
    test('resolves a column and a row with their token names', () {
      expect(
        _resolveNode(
          const ColumnNode(
            id: 'column',
            spacing: Literal(SpacingToken.md),
            alignment: Literal(AlignmentToken.center),
            children: [RowNode(id: 'row', spacing: Literal(SpacingToken.xs))],
          ),
        ),
        const WidgetNode(
          type: 'column',
          id: 'column',
          props: {'spacing': 'md', 'alignment': 'center'},
          children: [
            WidgetNode(type: 'row', id: 'row', props: {'spacing': 'xs', 'alignment': 'start'}),
          ],
        ),
      );
    });

    test('resolves a container, an expanded and a scroll with their child as the only child', () {
      expect(
        _resolveNode(
          const ContainerNode(
            id: 'container',
            padding: Literal(SpacingToken.lg),
            alignment: Literal(AlignmentToken.end),
            child: ExpandedNode(
              id: 'expanded',
              flex: Literal(2),
              child: ScrollNode(
                id: 'scroll',
                onRefresh: [ReloadAction()],
                child: DividerNode(id: 'divider'),
              ),
            ),
          ),
        ),
        const WidgetNode(
          type: 'container',
          id: 'container',
          props: {'padding': 'lg', 'alignment': 'end'},
          children: [
            WidgetNode(
              type: 'expanded',
              id: 'expanded',
              props: {'flex': 2},
              children: [
                WidgetNode(
                  type: 'scroll',
                  id: 'scroll',
                  children: [WidgetNode(type: 'divider', id: 'divider')],
                ),
              ],
            ),
          ],
        ),
      );
    });

    test('resolves a spacer and bound text with its fallback', () {
      expect(
        _resolveNode(
          const RowNode(
            id: 'row',
            children: [
              SpacerNode(id: 'spacer', size: Literal(SpacingToken.xl)),
              TextNode(id: 'name', text: Binding('user.name'), style: Literal(TextStyleToken.titleSmall)),
              TextNode(
                id: 'guest',
                text: Binding('user.missing', fallback: 'Guest'),
              ),
              TextNode(id: 'count', text: Binding('count')),
            ],
          ),
          {
            'user': {'name': 'Jae'},
            'count': 3,
          },
        ).children,
        const [
          WidgetNode(type: 'spacer', id: 'spacer', props: {'size': 'xl'}),
          WidgetNode(type: 'text', id: 'name', props: {'text': 'Jae', 'style': 'titleSmall'}),
          WidgetNode(type: 'text', id: 'guest', props: {'text': 'Guest', 'style': 'bodyMedium'}),
          WidgetNode(type: 'text', id: 'count', props: {'text': '3', 'style': 'bodyMedium'}),
        ],
      );
    });

    test('omits props that resolve to nothing', () {
      expect(
        _resolveNode(const TextNode(id: 'text', text: Binding('missing'), style: Binding('missing'))),
        const WidgetNode(type: 'text', id: 'text'),
      );
    });

    test('resolves a button with bound loading and its variant name', () {
      expect(
        _resolveNode(
          const ButtonNode(
            id: 'save',
            label: Literal('Save'),
            variant: Literal(ButtonVariant.secondary),
            loading: Binding('saving'),
          ),
          {'saving': true},
        ),
        const WidgetNode(type: 'button', id: 'save', props: {'label': 'Save', 'variant': 'secondary', 'loading': true}),
      );
    });

    test('resolves an icon button with its icon name, label, bound loading, and tap', () {
      const node = IconButtonNode(
        id: 'refresh',
        icon: Literal(IconToken.edit),
        label: Literal('Refresh'),
        loading: Binding('refreshing', fallback: false),
        onTap: [ReloadAction()],
      );

      expect(
        _resolveNode(node, {'refreshing': true}),
        const WidgetNode(
          type: 'iconButton',
          id: 'refresh',
          props: {'icon': 'edit', 'label': 'Refresh', 'loading': true},
          tap: EventTap(nodeId: 'refresh', event: 'onTap'),
        ),
      );
      expect(
        _resolveNode(node),
        const WidgetNode(
          type: 'iconButton',
          id: 'refresh',
          props: {'icon': 'edit', 'label': 'Refresh', 'loading': false},
          tap: EventTap(nodeId: 'refresh', event: 'onTap'),
        ),
      );
    });

    test('resolves a day picker to its label and two chevron icon buttons that tap its own events', () {
      const node = DayPickerNode(
        id: 'day',
        label: Binding('day.label'),
        previousLabel: Literal('Previous day'),
        nextLabel: Literal('Next day'),
        onPrevious: [UpdateStateAction(path: 'offset', op: Literal(UpdateOp.increment), value: Literal(-1))],
        onNext: [UpdateStateAction(path: 'offset', op: Literal(UpdateOp.increment))],
      );

      expect(
        _resolveNode(node, {
          'day': {'label': 'Mon, Jan 12'},
        }),
        const WidgetNode(
          type: 'dayPicker',
          id: 'day',
          props: {'label': 'Mon, Jan 12'},
          children: [
            WidgetNode(
              type: 'iconButton',
              id: 'dayPrevious',
              props: {'icon': 'chevronLeft', 'label': 'Previous day'},
              tap: EventTap(nodeId: 'day', event: 'onPrevious'),
            ),
            WidgetNode(
              type: 'iconButton',
              id: 'dayNext',
              props: {'icon': 'chevronRight', 'label': 'Next day'},
              tap: EventTap(nodeId: 'day', event: 'onNext'),
            ),
          ],
        ),
      );
    });

    test('puts the label tap of a day picker on the picker itself and leaves its chevrons their own taps', () {
      const node = DayPickerNode(
        id: 'day',
        label: Literal('Fri, Jan 16'),
        previousLabel: Literal('Previous day'),
        nextLabel: Literal('Next day'),
        labelTapHint: Literal('Go to today'),
        onPrevious: [UpdateStateAction(path: 'offset', op: Literal(UpdateOp.increment), value: Literal(-1))],
        onLabelTap: [UpdateStateAction(path: 'offset', value: Literal(0))],
      );

      final picker = _resolveNode(node);

      expect(picker.tap, const EventTap(nodeId: 'day', event: 'onLabelTap'));
      expect(picker.props, {'label': 'Fri, Jan 16'});
      expect(picker.children.map((child) => child.tap), [const EventTap(nodeId: 'day', event: 'onPrevious'), null]);
    });

    test('gives a day picker without a label tap no tap of its own', () {
      const node = DayPickerNode(
        id: 'day',
        label: Literal('Mon, Jan 12'),
        previousLabel: Literal('Previous day'),
        nextLabel: Literal('Next day'),
        onNext: [UpdateStateAction(path: 'offset', op: Literal(UpdateOp.increment))],
      );

      expect(_resolveNode(node).tap, isNull);
    });

    test('gives a day picker chevron without actions no tap', () {
      const node = DayPickerNode(
        id: 'day',
        label: Literal('Mon, Jan 12'),
        previousLabel: Literal('Previous day'),
        nextLabel: Literal('Next day'),
        onNext: [NavigateAction(pageId: Literal('myDay'))],
      );

      expect(_resolveNode(node).children.map((child) => child.tap), [null, const OpenAppTap()]);
    });

    test('resolves a progress bar with a bound value and literal max', () {
      expect(
        _resolveNode(
          const ProgressBarNode(id: 'progress', value: Binding('progress.done', fallback: 0), max: Literal(5)),
          {
            'progress': {'done': 2},
          },
        ),
        const WidgetNode(type: 'progressBar', id: 'progress', props: {'value': 2, 'max': 5}),
      );
      expect(
        _resolveNode(
          const ProgressBarNode(id: 'progress', value: Binding('progress.done', fallback: 0), max: Literal(0)),
        ),
        const WidgetNode(type: 'progressBar', id: 'progress', props: {'value': 0, 'max': 0}),
      );
    });

    test('resolves a checkbox tile with checked from its bind path', () {
      const tile = CheckboxTileNode(
        id: 'task',
        bind: 'tasks.a.done',
        title: Literal('Gym'),
        subtitle: Literal('9:00 AM'),
        emoji: Literal('🏋️'),
        busy: Binding('tasks.a.saving', fallback: false),
      );

      expect(
        _resolveNode(tile, {
          'tasks': {
            'a': {'done': true, 'saving': true},
          },
        }),
        const WidgetNode(
          type: 'checkboxTile',
          id: 'task',
          props: {'title': 'Gym', 'subtitle': '9:00 AM', 'emoji': '🏋️', 'busy': true, 'checked': true},
        ),
      );
      expect(
        _resolveNode(tile),
        const WidgetNode(
          type: 'checkboxTile',
          id: 'task',
          props: {'title': 'Gym', 'subtitle': '9:00 AM', 'emoji': '🏋️', 'busy': false, 'checked': false},
        ),
      );
    });

    test('resolves an unknown node to its fallback and drops it without one', () {
      expect(
        _resolveNode(
          const ColumnNode(
            id: 'root',
            children: [
              UnknownNode(
                id: 'chart',
                fallback: DividerNode(id: 'chartFallback'),
              ),
              UnknownNode(id: 'map'),
            ],
          ),
        ).children,
        const [WidgetNode(type: 'divider', id: 'chartFallback')],
      );
    });

    test('drops app bars and text fields', () {
      expect(
        _resolveNode(
          const ColumnNode(
            id: 'root',
            children: [
              AppBarNode(id: 'appBar', title: Literal('Title')),
              TextFieldNode(id: 'email', bind: 'email'),
              ContainerNode(
                id: 'container',
                child: TextFieldNode(id: 'name', bind: 'name'),
              ),
            ],
          ),
        ).children,
        const [
          WidgetNode(type: 'container', id: 'container', props: {'padding': 'none', 'alignment': 'start'}),
        ],
      );
    });

    test('resolves a dropped root to an empty column', () {
      expect(_resolveNode(const AppBarNode(id: 'root')), const WidgetNode(type: 'column', id: 'root'));
    });

    test('turns a navigate-only action list into an open-app tap', () {
      expect(
        _resolveNode(
          const ButtonNode(
            id: 'open',
            label: Literal('Open'),
            onTap: [NavigateAction(pageId: Literal('myDay'))],
          ),
        ).tap,
        const OpenAppTap(),
      );
    });

    test('turns an open-url-only action list into an open-url tap with its resolved url', () {
      expect(
        _resolveNode(
          const ButtonNode(
            id: 'claude',
            label: Literal('Ask Claude'),
            onTap: [OpenUrlAction(url: Literal('https://claude.ai/new'))],
          ),
        ).tap,
        const OpenUrlTap(url: 'https://claude.ai/new'),
      );
      expect(
        _resolveNode(
          const IconButtonNode(
            id: 'link',
            icon: Literal(IconToken.edit),
            label: Literal('Open link'),
            onTap: [OpenUrlAction(url: Binding('link.url'))],
          ),
          {
            'link': {'url': 'https://example.com'},
          },
        ).tap,
        const OpenUrlTap(url: 'https://example.com'),
      );
    });

    test('gives an open-url action whose url resolves to null no tap', () {
      expect(
        _resolveNode(
          const ButtonNode(
            id: 'link',
            label: Literal('Link'),
            onTap: [OpenUrlAction(url: Binding('missing'))],
          ),
        ).tap,
        isNull,
      );
    });

    test('turns an open-url action alongside other actions into an event tap', () {
      expect(
        _resolveNode(
          const ButtonNode(
            id: 'link',
            label: Literal('Link'),
            onTap: [
              UpdateStateAction(path: 'opened', value: Literal(true)),
              OpenUrlAction(url: Literal('https://claude.ai')),
            ],
          ),
        ).tap,
        const EventTap(nodeId: 'link', event: 'onTap'),
      );
    });

    test('turns any other action list into an event tap named after its field', () {
      expect(
        _resolveNode(
          const ButtonNode(
            id: 'open',
            label: Literal('Open'),
            onTap: [
              UpdateStateAction(path: 'opened', value: Literal(true)),
              NavigateAction(pageId: Literal('myDay')),
            ],
          ),
        ).tap,
        const EventTap(nodeId: 'open', event: 'onTap'),
      );
      expect(
        _resolveNode(
          const CheckboxTileNode(id: 'task', bind: 'done', title: Literal('Gym'), onChanged: [ReloadAction()]),
        ).tap,
        const EventTap(nodeId: 'task', event: 'onChanged'),
      );
    });

    test('gives an empty action list no tap', () {
      expect(_resolveNode(const ButtonNode(id: 'idle', label: Literal('Idle'))).tap, isNull);
      expect(_resolveNode(const CheckboxTileNode(id: 'task', bind: 'done', title: Literal('Gym'))).tap, isNull);
    });

    test('resolves the My Day widget page to the shared fixture', () {
      final snapshot = _myDaySnapshot();
      final fixture = File(_fixturePath);
      if (Platform.environment['UPDATE_FIXTURES'] == 'true') {
        fixture
          ..createSync(recursive: true)
          ..writeAsStringSync(_encode(snapshot));
      }

      expect(_encode(snapshot), fixture.readAsStringSync());
      expect(WidgetSnapshotMapper.fromJson(fixture.readAsStringSync()), snapshot);
    });
  });
}
