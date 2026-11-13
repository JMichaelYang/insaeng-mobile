import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(ColumnNode, () {
    test('decodes with defaults', () {
      expect(_decode({'type': 'column', 'id': 'root'}), const ColumnNode(id: 'root'));
    });

    test('decodes spacing and alignment tokens', () {
      expect(
        _decode({'type': 'column', 'id': 'root', 'spacing': 'md', 'alignment': 'center'}),
        const ColumnNode(id: 'root', spacing: Literal(SpacingToken.md), alignment: Literal(AlignmentToken.center)),
      );
    });

    test('decodes bound spacing and alignment', () {
      expect(
        _decode({
          'type': 'column',
          'id': 'root',
          'spacing': {r'$bind': 'gap', 'fallback': 'lg'},
          'alignment': {r'$bind': 'align'},
        }),
        const ColumnNode(
          id: 'root',
          spacing: Binding('gap', fallback: SpacingToken.lg),
          alignment: Binding('align'),
        ),
      );
    });

    test('falls back to the default for unknown tokens', () {
      expect(
        _decode({'type': 'column', 'id': 'root', 'spacing': 'huge', 'alignment': 'justify'}),
        const ColumnNode(id: 'root'),
      );
    });

    test('decodes nested children', () {
      expect(
        _decode({
          'type': 'column',
          'id': 'root',
          'children': [
            {'type': 'appBar', 'id': 'appBar', 'title': 'Counter'},
            {
              'type': 'column',
              'id': 'counter',
              'children': [
                {'type': 'text', 'id': 'count', 'text': 'Zero'},
              ],
            },
          ],
        }),
        const ColumnNode(
          id: 'root',
          children: [
            AppBarNode(id: 'appBar', title: Literal('Counter')),
            ColumnNode(
              id: 'counter',
              children: [TextNode(id: 'count', text: Literal('Zero'))],
            ),
          ],
        ),
      );
    });
  });
}
