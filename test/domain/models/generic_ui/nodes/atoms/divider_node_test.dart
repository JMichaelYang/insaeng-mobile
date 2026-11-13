import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(DividerNode, () {
    test('decodes', () {
      expect(_decode({'type': 'divider', 'id': 'divider'}), const DividerNode(id: 'divider'));
    });
  });
}
