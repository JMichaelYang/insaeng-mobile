import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(GenericNode, () {
    test('fails without an id', () {
      for (final type in ['column', 'appBar', 'text', 'button', 'textField', 'carousel']) {
        expect(
          () => _decode({'type': type, 'text': 'a', 'label': 'a', 'bind': 'a'}),
          throwsA(isA<MapperException>()),
          reason: type,
        );
      }
    });

    test('ignores unknown properties', () {
      expect(
        _decode({'type': 'text', 'id': 'hello', 'text': 'Hello', 'color': 'red'}),
        const TextNode(id: 'hello', text: Literal('Hello')),
      );
    });

    test('childNodes lists the children of a column', () {
      const children = [TextNode(id: 'a', text: Literal('a')), TextNode(id: 'b', text: Literal('b'))];

      expect(const ColumnNode(id: 'root', children: children).childNodes, children);
    });

    test('childNodes lists the fallback of an unknown node', () {
      const fallback = TextNode(id: 'heroFallback', text: Literal('Featured'));

      expect(const UnknownNode(id: 'hero', fallback: fallback).childNodes, [fallback]);
      expect(const UnknownNode(id: 'hero').childNodes, isEmpty);
    });

    test('childNodes is empty for leaf nodes', () {
      expect(const TextNode(id: 'a', text: Literal('a')).childNodes, isEmpty);
      expect(const ButtonNode(id: 'add', label: Literal('Add')).childNodes, isEmpty);
      expect(const AppBarNode(id: 'appBar').childNodes, isEmpty);
    });

    test('actions lists the onTap actions of a button', () {
      const onTap = [BackAction()];

      expect(const ButtonNode(id: 'back', label: Literal('Back'), onTap: onTap).actions, onTap);
    });

    test('actions is empty for nodes without events', () {
      expect(const ColumnNode(id: 'root').actions, isEmpty);
      expect(const TextNode(id: 'a', text: Literal('a')).actions, isEmpty);
      expect(const AppBarNode(id: 'appBar').actions, isEmpty);
      expect(const UnknownNode(id: 'hero').actions, isEmpty);
    });
  });
}
