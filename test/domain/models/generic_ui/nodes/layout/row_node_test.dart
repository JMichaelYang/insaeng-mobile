import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(RowNode, () {
    test('decodes with defaults', () {
      expect(_decode({'type': 'row', 'id': 'actions'}), const RowNode(id: 'actions'));
    });

    test('decodes spacing and alignment tokens', () {
      expect(
        _decode({'type': 'row', 'id': 'actions', 'spacing': 'sm', 'alignment': 'end'}),
        const RowNode(id: 'actions', spacing: Literal(SpacingToken.sm), alignment: Literal(AlignmentToken.end)),
      );
    });

    test('decodes bound spacing and alignment', () {
      expect(
        _decode({
          'type': 'row',
          'id': 'actions',
          'spacing': {r'$bind': 'gap', 'fallback': 'xs'},
          'alignment': {r'$bind': 'align'},
        }),
        const RowNode(
          id: 'actions',
          spacing: Binding('gap', fallback: SpacingToken.xs),
          alignment: Binding('align'),
        ),
      );
    });

    test('falls back to the default for unknown tokens', () {
      expect(
        _decode({'type': 'row', 'id': 'actions', 'spacing': 'huge', 'alignment': 'baseline'}),
        const RowNode(id: 'actions'),
      );
    });

    test('decodes its children', () {
      expect(
        _decode({
          'type': 'row',
          'id': 'actions',
          'children': [
            {'type': 'text', 'id': 'label', 'text': 'Total'},
            {'type': 'spacer', 'id': 'gap'},
            {'type': 'button', 'id': 'pay', 'label': 'Pay'},
          ],
        }),
        const RowNode(
          id: 'actions',
          children: [
            TextNode(id: 'label', text: Literal('Total')),
            SpacerNode(id: 'gap'),
            ButtonNode(id: 'pay', label: Literal('Pay')),
          ],
        ),
      );
    });
  });
}
