import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_page.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericPage _decode(Map<String, Object?> json) => GenericPageMapper.fromMap(json);

void main() {
  group(GenericPage, () {
    test('decodes a full counter payload', () {
      expect(
        _decode({
          'id': 'counter',
          'state': {'count': 0},
          'onLoad': [
            {'type': 'showMessage', 'text': 'Welcome'},
          ],
          'root': {
            'type': 'column',
            'id': 'root',
            'children': [
              {'type': 'appBar', 'id': 'appBar', 'title': 'Counter'},
              {
                'type': 'column',
                'id': 'counter',
                'spacing': 'md',
                'alignment': 'center',
                'children': [
                  {
                    'type': 'text',
                    'id': 'count',
                    'text': {r'$bind': 'count'},
                    'style': 'displayMedium',
                  },
                  {
                    'type': 'button',
                    'id': 'add',
                    'label': 'Add',
                    'onTap': [
                      {'type': 'updateState', 'path': 'count', 'op': 'increment'},
                    ],
                  },
                ],
              },
            ],
          },
        }),
        GenericPage(
          id: 'counter',
          state: GenericValues(const {'count': 0}),
          onLoad: const [ShowMessageAction(text: Literal('Welcome'))],
          root: const ColumnNode(
            id: 'root',
            children: [
              AppBarNode(id: 'appBar', title: Literal('Counter')),
              ColumnNode(
                id: 'counter',
                spacing: Literal(SpacingToken.md),
                alignment: Literal(AlignmentToken.center),
                children: [
                  TextNode(id: 'count', text: Binding('count'), style: Literal(TextStyleToken.displayMedium)),
                  ButtonNode(
                    id: 'add',
                    label: Literal('Add'),
                    onTap: [UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment))],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });

    test('decodes with defaults', () {
      final page = _decode({
        'id': 'home',
        'root': {'type': 'column', 'id': 'root'},
      });

      expect(
        page,
        const GenericPage(
          id: 'home',
          root: ColumnNode(id: 'root'),
        ),
      );
      expect(page.state, isNull);
      expect(page.initialState, GenericValues.empty);
    });

    test('decodes nested state', () {
      expect(
        _decode({
          'id': 'todos',
          'state': {
            'todos': [
              {'title': 'a', 'done': false},
            ],
          },
          'root': {'type': 'column', 'id': 'root'},
        }).initialState.get('todos.0.title'),
        'a',
      );
    });

    test('encodes back to the same payload', () {
      final json = {
        'id': 'counter',
        'root': {'type': 'text', 'id': 'count', 'text': 'Zero'},
        'state': {'count': 0},
      };

      expect(_decode(_decode(json).toMap()), _decode(json));
    });

    test('ignores unknown properties', () {
      expect(
        _decode({
          'id': 'home',
          'title': 'Home',
          'root': {'type': 'column', 'id': 'root'},
        }),
        const GenericPage(
          id: 'home',
          root: ColumnNode(id: 'root'),
        ),
      );
    });

    test('fails without an id or root', () {
      expect(
        () => _decode({
          'root': {'type': 'column', 'id': 'root'},
        }),
        throwsA(isA<MapperException>()),
      );
      expect(() => _decode({'id': 'home'}), throwsA(isA<MapperException>()));
    });

    test('fails when state is not an object', () {
      expect(
        () => _decode({
          'id': 'home',
          'state': [1],
          'root': {'type': 'column', 'id': 'root'},
        }),
        throwsA(isA<MapperException>()),
      );
    });
  });
}
