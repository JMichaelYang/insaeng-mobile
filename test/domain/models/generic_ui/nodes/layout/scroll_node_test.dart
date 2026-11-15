import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(ScrollNode, () {
    test('decodes without a child or onRefresh', () {
      final node = _decode({'type': 'scroll', 'id': 'scroll'});

      expect(node, const ScrollNode(id: 'scroll'));
      expect((node as ScrollNode).onRefresh, isEmpty);
    });

    test('decodes its child', () {
      expect(
        _decode({
          'type': 'scroll',
          'id': 'scroll',
          'child': {
            'type': 'column',
            'id': 'list',
            'children': [
              {'type': 'text', 'id': 'first', 'text': 'One'},
            ],
          },
        }),
        const ScrollNode(
          id: 'scroll',
          child: ColumnNode(
            id: 'list',
            children: [TextNode(id: 'first', text: Literal('One'))],
          ),
        ),
      );
    });

    test('decodes onRefresh actions in order', () {
      expect(
        _decode({
          'type': 'scroll',
          'id': 'scroll',
          'onRefresh': [
            {'type': 'reload'},
            {'type': 'showMessage', 'text': 'Refreshed'},
            {'type': 'teleport'},
          ],
        }),
        const ScrollNode(
          id: 'scroll',
          onRefresh: [
            ReloadAction(),
            ShowMessageAction(text: Literal('Refreshed')),
            UnknownAction(),
          ],
        ),
      );
    });

    test('fails with onRefresh that is not a list', () {
      expect(() => _decode({'type': 'scroll', 'id': 'scroll', 'onRefresh': 'reload'}), throwsA(isA<MapperException>()));
    });

    test('actions lists the onRefresh actions', () {
      const onRefresh = [ReloadAction()];

      expect(const ScrollNode(id: 'scroll', onRefresh: onRefresh).actions, onRefresh);
    });
  });
}
