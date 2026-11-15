import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(CheckboxTileNode, () {
    test('decodes with defaults', () {
      expect(
        _decode({'type': 'checkboxTile', 'id': 'done', 'bind': 'todo.done', 'title': 'Done'}),
        const CheckboxTileNode(id: 'done', bind: 'todo.done', title: Literal('Done')),
      );
    });

    test('decodes literal subtitle and busy', () {
      expect(
        _decode({
          'type': 'checkboxTile',
          'id': 'done',
          'bind': 'todo.done',
          'title': 'Done',
          'subtitle': 'Mark the task complete',
          'busy': true,
        }),
        const CheckboxTileNode(
          id: 'done',
          bind: 'todo.done',
          title: Literal('Done'),
          subtitle: Literal('Mark the task complete'),
          busy: Literal(true),
        ),
      );
    });

    test('decodes bound title, subtitle, and busy', () {
      expect(
        _decode({
          'type': 'checkboxTile',
          'id': 'done',
          'bind': 'todo.done',
          'title': {r'$bind': 'todo.title'},
          'subtitle': {r'$bind': 'todo.due', 'fallback': 'No due date'},
          'busy': {r'$bind': 'saving', 'fallback': false},
        }),
        const CheckboxTileNode(
          id: 'done',
          bind: 'todo.done',
          title: Binding('todo.title'),
          subtitle: Binding('todo.due', fallback: 'No due date'),
          busy: Binding('saving', fallback: false),
        ),
      );
    });

    test('decodes onChanged actions in order', () {
      expect(
        _decode({
          'type': 'checkboxTile',
          'id': 'done',
          'bind': 'todo.done',
          'title': 'Done',
          'onChanged': [
            {'type': 'updateState', 'path': 'changes', 'op': 'increment'},
            {'type': 'teleport'},
            {'type': 'showMessage', 'text': 'Saved'},
          ],
        }),
        const CheckboxTileNode(
          id: 'done',
          bind: 'todo.done',
          title: Literal('Done'),
          onChanged: [
            UpdateStateAction(path: 'changes', op: Literal(UpdateOp.increment)),
            UnknownAction(),
            ShowMessageAction(text: Literal('Saved')),
          ],
        ),
      );
    });

    test('fails without a bind path', () {
      expect(() => _decode({'type': 'checkboxTile', 'id': 'done', 'title': 'Done'}), throwsA(isA<MapperException>()));
    });

    test('fails without a title', () {
      expect(
        () => _decode({'type': 'checkboxTile', 'id': 'done', 'bind': 'todo.done'}),
        throwsA(isA<MapperException>()),
      );
    });

    test('fails with actions that are not a list', () {
      expect(
        () =>
            _decode({'type': 'checkboxTile', 'id': 'done', 'bind': 'todo.done', 'title': 'Done', 'onChanged': 'back'}),
        throwsA(isA<MapperException>()),
      );
    });

    test('actions lists onChanged', () {
      const node = CheckboxTileNode(id: 'done', bind: 'todo.done', title: Literal('Done'), onChanged: [BackAction()]);

      expect(node.actions, node.onChanged);
      expect(node.childNodes, isEmpty);
    });
  });
}
