import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(ScrollNode, () {
    test('decodes without a child', () {
      expect(_decode({'type': 'scroll', 'id': 'scroll'}), const ScrollNode(id: 'scroll'));
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
  });
}
