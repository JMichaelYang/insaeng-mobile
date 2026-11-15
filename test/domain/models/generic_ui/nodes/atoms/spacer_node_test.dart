import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(SpacerNode, () {
    test('decodes with defaults', () {
      expect(_decode({'type': 'spacer', 'id': 'gap'}), const SpacerNode(id: 'gap'));
    });

    test('decodes every size token', () {
      for (final size in SpacingToken.values) {
        expect(
          _decode({'type': 'spacer', 'id': 'gap', 'size': size.name}),
          SpacerNode(id: 'gap', size: Literal(size)),
          reason: size.name,
        );
      }
    });

    test('decodes a bound size', () {
      expect(
        _decode({
          'type': 'spacer',
          'id': 'gap',
          'size': {r'$bind': 'gap', 'fallback': 'xl'},
        }),
        const SpacerNode(
          id: 'gap',
          size: Binding('gap', fallback: SpacingToken.xl),
        ),
      );
    });

    test('falls back to the token default for an unknown size', () {
      expect(
        _decode({'type': 'spacer', 'id': 'gap', 'size': 'huge'}),
        const SpacerNode(id: 'gap', size: Literal(SpacingToken.none)),
      );
    });
  });
}
