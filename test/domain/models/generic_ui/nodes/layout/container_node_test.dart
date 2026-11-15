import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(ContainerNode, () {
    test('decodes with defaults', () {
      expect(_decode({'type': 'container', 'id': 'content'}), const ContainerNode(id: 'content'));
    });

    test('decodes padding and alignment tokens', () {
      expect(
        _decode({'type': 'container', 'id': 'content', 'padding': 'lg', 'alignment': 'center'}),
        const ContainerNode(
          id: 'content',
          padding: Literal(SpacingToken.lg),
          alignment: Literal(AlignmentToken.center),
        ),
      );
    });

    test('decodes bound padding and alignment', () {
      expect(
        _decode({
          'type': 'container',
          'id': 'content',
          'padding': {r'$bind': 'inset', 'fallback': 'md'},
          'alignment': {r'$bind': 'align'},
        }),
        const ContainerNode(
          id: 'content',
          padding: Binding('inset', fallback: SpacingToken.md),
          alignment: Binding('align'),
        ),
      );
    });

    test('falls back to the default for unknown tokens', () {
      expect(
        _decode({'type': 'container', 'id': 'content', 'padding': 'huge', 'alignment': 'justify'}),
        const ContainerNode(id: 'content'),
      );
    });

    test('decodes its child', () {
      expect(
        _decode({
          'type': 'container',
          'id': 'content',
          'child': {'type': 'text', 'id': 'hello', 'text': 'Hello'},
        }),
        const ContainerNode(
          id: 'content',
          child: TextNode(id: 'hello', text: Literal('Hello')),
        ),
      );
    });
  });
}
