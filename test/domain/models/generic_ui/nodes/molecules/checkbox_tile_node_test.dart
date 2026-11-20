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

    test('decodes literal subtitle, emoji, and busy', () {
      expect(
        _decode({
          'type': 'checkboxTile',
          'id': 'done',
          'bind': 'todo.done',
          'title': 'Done',
          'subtitle': 'Mark the task complete',
          'emoji': '🧘',
          'busy': true,
        }),
        const CheckboxTileNode(
          id: 'done',
          bind: 'todo.done',
          title: Literal('Done'),
          subtitle: Literal('Mark the task complete'),
          emoji: Literal('🧘'),
          busy: Literal(true),
        ),
      );
    });

    test('decodes bound title, subtitle, emoji, and busy', () {
      expect(
        _decode({
          'type': 'checkboxTile',
          'id': 'done',
          'bind': 'todo.done',
          'title': {r'$bind': 'todo.title'},
          'subtitle': {r'$bind': 'todo.due', 'fallback': 'No due date'},
          'emoji': {r'$bind': 'todo.emoji', 'fallback': '📝'},
          'busy': {r'$bind': 'saving', 'fallback': false},
        }),
        const CheckboxTileNode(
          id: 'done',
          bind: 'todo.done',
          title: Binding('todo.title'),
          subtitle: Binding('todo.due', fallback: 'No due date'),
          emoji: Binding('todo.emoji', fallback: '📝'),
          busy: Binding('saving', fallback: false),
        ),
      );
    });

    test('decodes every mark', () {
      for (final mark in CheckboxMarkToken.values) {
        expect(
          _decode({'type': 'checkboxTile', 'id': 'done', 'bind': 'todo.done', 'title': 'Done', 'mark': mark.name}),
          CheckboxTileNode(id: 'done', bind: 'todo.done', title: const Literal('Done'), mark: Literal(mark)),
          reason: mark.name,
        );
      }
    });

    test('defaults the mark to check when absent', () {
      final node = _decode({'type': 'checkboxTile', 'id': 'done', 'bind': 'todo.done', 'title': 'Done'});

      expect((node as CheckboxTileNode).mark, const Literal(CheckboxMarkToken.check));
    });

    test('falls back to check for an unknown mark', () {
      expect(
        _decode({'type': 'checkboxTile', 'id': 'done', 'bind': 'todo.done', 'title': 'Done', 'mark': 'cross'}),
        const CheckboxTileNode(id: 'done', bind: 'todo.done', title: Literal('Done')),
      );
    });

    test('decodes a bound mark', () {
      expect(
        _decode({
          'type': 'checkboxTile',
          'id': 'done',
          'bind': 'todo.done',
          'title': 'Done',
          'mark': {r'$bind': 'todo.mark', 'fallback': 'dash'},
        }),
        const CheckboxTileNode(
          id: 'done',
          bind: 'todo.done',
          title: Literal('Done'),
          mark: Binding('todo.mark', fallback: CheckboxMarkToken.dash),
        ),
      );
    });

    for (final mark in [
      const Literal(CheckboxMarkToken.dash),
      const Binding('todo.mark', fallback: CheckboxMarkToken.dash),
    ]) {
      test('round trips a ${mark.runtimeType} mark through JSON', () {
        final node = CheckboxTileNode(id: 'done', bind: 'todo.done', title: const Literal('Done'), mark: mark);

        expect(GenericNodeMapper.fromJson(node.toJson()), node);
      });
    }

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
