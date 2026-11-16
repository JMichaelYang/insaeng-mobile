import 'dart:convert';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/home_widget/widget_snapshot.dart';

const _snapshot = WidgetSnapshot(
  pageId: 'myDayWidget',
  root: WidgetNode(
    type: 'column',
    id: 'root',
    props: {'spacing': 'sm'},
    children: [
      WidgetNode(type: 'text', id: 'title', props: {'text': 'My Day', 'style': 'titleMedium'}, tap: OpenAppTap()),
      WidgetNode(
        type: 'scroll',
        id: 'tasks',
        children: [
          WidgetNode(
            type: 'checkboxTile',
            id: 'task-1',
            props: {
              'title': 'Write tests',
              'subtitle': null,
              'checked': true,
              'enabled': true,
              'count': 2,
              'ratio': 0.5,
              'tags': ['a', 'b'],
              'meta': {
                'emoji': '🧪',
                'nested': [
                  {'k': 1},
                ],
              },
            },
            tap: EventTap(nodeId: 'task-1', event: 'onChanged'),
          ),
        ],
      ),
    ],
  ),
);

const Map<String, Object?> _json = {
  'pageId': 'myDayWidget',
  'root': {
    'type': 'column',
    'id': 'root',
    'props': {'spacing': 'sm'},
    'children': [
      {
        'type': 'text',
        'id': 'title',
        'props': {'text': 'My Day', 'style': 'titleMedium'},
        'children': <Object?>[],
        'tap': {'type': 'openApp'},
      },
      {
        'type': 'scroll',
        'id': 'tasks',
        'props': <String, Object?>{},
        'children': [
          {
            'type': 'checkboxTile',
            'id': 'task-1',
            'props': {
              'title': 'Write tests',
              'subtitle': null,
              'checked': true,
              'enabled': true,
              'count': 2,
              'ratio': 0.5,
              'tags': ['a', 'b'],
              'meta': {
                'emoji': '🧪',
                'nested': [
                  {'k': 1},
                ],
              },
            },
            'children': <Object?>[],
            'tap': {'type': 'event', 'nodeId': 'task-1', 'event': 'onChanged'},
          },
        ],
      },
    ],
  },
};

void main() {
  group(WidgetSnapshot, () {
    test('encodes nested nodes and both tap kinds to the stable JSON shape', () {
      expect(_snapshot.toMap(), _json);
    });

    test('decodes the stable JSON shape', () {
      expect(WidgetSnapshotMapper.fromMap(_json), _snapshot);
    });

    test('round-trips through a JSON string', () {
      final decoded = WidgetSnapshotMapper.fromJson(_snapshot.toJson());

      expect(decoded, _snapshot);
      expect(jsonDecode(decoded.toJson()), _json);
    });

    test('fails without a pageId or root', () {
      expect(() => WidgetSnapshotMapper.fromMap({'root': _json['root']}), throwsA(isA<MapperException>()));
      expect(() => WidgetSnapshotMapper.fromMap({'pageId': 'p'}), throwsA(isA<MapperException>()));
    });
  });

  group(WidgetNode, () {
    test('decodes with defaults', () {
      expect(WidgetNodeMapper.fromMap({'type': 'spacer', 'id': 's'}), const WidgetNode(type: 'spacer', id: 's'));
    });

    test('omits tap when there is none', () {
      expect(const WidgetNode(type: 'divider', id: 'd').toMap(), {
        'type': 'divider',
        'id': 'd',
        'props': <String, Object?>{},
        'children': <Object?>[],
      });
    });

    test('fails without a type or id', () {
      expect(() => WidgetNodeMapper.fromMap({'id': 'x'}), throwsA(isA<MapperException>()));
      expect(() => WidgetNodeMapper.fromMap({'type': 'text'}), throwsA(isA<MapperException>()));
    });
  });

  group(WidgetTap, () {
    test('round-trips openApp', () {
      expect(const OpenAppTap().toMap(), {'type': 'openApp'});
      expect(WidgetTapMapper.fromMap({'type': 'openApp'}), const OpenAppTap());
    });

    test('round-trips event', () {
      const tap = EventTap(nodeId: 'task-1', event: 'onChanged');
      final json = {'type': 'event', 'nodeId': 'task-1', 'event': 'onChanged'};

      expect(tap.toMap(), json);
      expect(WidgetTapMapper.fromMap(json), tap);
    });

    test('fails on an unknown kind or an event without its fields', () {
      expect(() => WidgetTapMapper.fromMap({'type': 'navigate'}), throwsA(isA<MapperException>()));
      expect(() => WidgetTapMapper.fromMap({'type': 'event', 'nodeId': 'n'}), throwsA(isA<MapperException>()));
    });
  });
}
