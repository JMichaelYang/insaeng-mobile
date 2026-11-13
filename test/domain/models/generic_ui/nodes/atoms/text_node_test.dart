import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(TextNode, () {
    test('decodes with defaults', () {
      expect(
        _decode({'type': 'text', 'id': 'hello', 'text': 'Hello'}),
        const TextNode(id: 'hello', text: Literal('Hello')),
      );
    });

    test('decodes every style token', () {
      for (final style in TextStyleToken.values) {
        expect(
          _decode({'type': 'text', 'id': 'hello', 'text': 'Hello', 'style': style.name}),
          TextNode(id: 'hello', text: const Literal('Hello'), style: Literal(style)),
          reason: style.name,
        );
      }
    });

    test('decodes bound text and style', () {
      expect(
        _decode({
          'type': 'text',
          'id': 'count',
          'text': {r'$bind': 'count'},
          'style': {r'$bind': 'countStyle', 'fallback': 'displayMedium'},
        }),
        const TextNode(
          id: 'count',
          text: Binding('count'),
          style: Binding('countStyle', fallback: TextStyleToken.displayMedium),
        ),
      );
    });

    test('falls back to the default for an unknown style', () {
      expect(
        _decode({'type': 'text', 'id': 'hello', 'text': 'Hello', 'style': 'jumbo'}),
        const TextNode(id: 'hello', text: Literal('Hello')),
      );
    });

    test('fails without text', () {
      expect(() => _decode({'type': 'text', 'id': 'hello'}), throwsA(isA<MapperException>()));
    });
  });
}
