import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(ExpandedNode, () {
    test('decodes with defaults', () {
      expect(_decode({'type': 'expanded', 'id': 'gap'}), const ExpandedNode(id: 'gap'));
    });

    test('decodes flex', () {
      expect(_decode({'type': 'expanded', 'id': 'gap', 'flex': 2}), const ExpandedNode(id: 'gap', flex: Literal(2)));
    });

    test('decodes its child', () {
      expect(
        _decode({
          'type': 'expanded',
          'id': 'body',
          'child': {
            'type': 'scroll',
            'id': 'scroll',
            'child': {'type': 'text', 'id': 'hello', 'text': 'Hello'},
          },
        }),
        const ExpandedNode(
          id: 'body',
          child: ScrollNode(
            id: 'scroll',
            child: TextNode(id: 'hello', text: Literal('Hello')),
          ),
        ),
      );
    });

    test('decodes a bound flex', () {
      expect(
        _decode({
          'type': 'expanded',
          'id': 'gap',
          'flex': {r'$bind': 'weight', 'fallback': 2},
        }),
        const ExpandedNode(id: 'gap', flex: Binding('weight', fallback: 2)),
      );
    });

    test('fails with a flex that is not an integer', () {
      expect(() => _decode({'type': 'expanded', 'id': 'gap', 'flex': 'wide'}), throwsA(isA<MapperException>()));
    });
  });
}
