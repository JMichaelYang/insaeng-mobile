import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(GenericNode, () {
    test('fails without an id', () {
      for (final type in ['column', 'appBar', 'text', 'button', 'carousel']) {
        expect(() => _decode({'type': type, 'text': 'a', 'label': 'a'}), throwsA(isA<MapperException>()), reason: type);
      }
    });

    test('ignores unknown properties', () {
      expect(
        _decode({'type': 'text', 'id': 'hello', 'text': 'Hello', 'color': 'red'}),
        const TextNode(id: 'hello', text: Literal('Hello')),
      );
    });
  });
}
