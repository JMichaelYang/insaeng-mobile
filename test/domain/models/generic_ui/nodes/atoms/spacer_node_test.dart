import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(SpacerNode, () {
    test('decodes', () {
      expect(_decode({'type': 'spacer', 'id': 'gap'}), const SpacerNode(id: 'gap'));
    });
  });
}
