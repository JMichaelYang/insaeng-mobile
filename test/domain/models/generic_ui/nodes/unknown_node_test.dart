import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(UnknownNode, () {
    test('decodes an unknown type without a fallback', () {
      expect(_decode({'type': 'carousel', 'id': 'hero', 'items': <Object?>[]}), const UnknownNode(id: 'hero'));
    });

    test('decodes an unknown type with its fallback', () {
      expect(
        _decode({
          'type': 'carousel',
          'id': 'hero',
          'fallback': {'type': 'text', 'id': 'heroFallback', 'text': 'Featured'},
        }),
        const UnknownNode(
          id: 'hero',
          fallback: TextNode(id: 'heroFallback', text: Literal('Featured')),
        ),
      );
    });

    test('decodes a nested unknown fallback', () {
      expect(
        _decode({
          'type': 'carousel',
          'id': 'hero',
          'fallback': {
            'type': 'grid',
            'id': 'heroGrid',
            'fallback': {'type': 'column', 'id': 'heroColumn'},
          },
        }),
        const UnknownNode(
          id: 'hero',
          fallback: UnknownNode(
            id: 'heroGrid',
            fallback: ColumnNode(id: 'heroColumn'),
          ),
        ),
      );
    });

    test('decodes an unknown child inside a known node', () {
      expect(
        _decode({
          'type': 'column',
          'id': 'root',
          'children': [
            {'type': 'carousel', 'id': 'hero'},
          ],
        }),
        const ColumnNode(
          id: 'root',
          children: [UnknownNode(id: 'hero')],
        ),
      );
    });
  });
}
