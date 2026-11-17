import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(IconButtonNode, () {
    test('decodes with defaults', () {
      expect(
        _decode({'type': 'iconButton', 'id': 'open', 'icon': 'edit', 'label': 'Open Claude'}),
        const IconButtonNode(id: 'open', icon: Literal(IconToken.edit), label: Literal('Open Claude')),
      );
    });

    test('decodes loading and falls back to edit for an unknown icon', () {
      expect(
        _decode({'type': 'iconButton', 'id': 'open', 'icon': 'rocket', 'label': 'Open', 'loading': true}),
        const IconButtonNode(id: 'open', icon: Literal(IconToken.edit), label: Literal('Open'), loading: Literal(true)),
      );
    });

    test('decodes bound icon, label, and loading', () {
      expect(
        _decode({
          'type': 'iconButton',
          'id': 'refresh',
          'icon': {r'$bind': 'icon', 'fallback': 'edit'},
          'label': {r'$bind': 'label'},
          'loading': {r'$bind': 'refreshing', 'fallback': false},
        }),
        const IconButtonNode(
          id: 'refresh',
          icon: Binding('icon', fallback: IconToken.edit),
          label: Binding('label'),
          loading: Binding('refreshing', fallback: false),
        ),
      );
    });

    test('decodes onTap actions in order and exposes them as its actions', () {
      final node = _decode({
        'type': 'iconButton',
        'id': 'open',
        'icon': 'edit',
        'label': 'Open',
        'onTap': [
          {'type': 'updateState', 'path': 'opened', 'value': true},
          {'type': 'back'},
        ],
      });

      const onTap = [UpdateStateAction(path: 'opened', value: Literal(true)), BackAction()];
      expect(
        node,
        const IconButtonNode(id: 'open', icon: Literal(IconToken.edit), label: Literal('Open'), onTap: onTap),
      );
      expect(node.actions, onTap);
    });

    test('fails without an icon or a label', () {
      expect(() => _decode({'type': 'iconButton', 'id': 'open', 'label': 'Open'}), throwsA(isA<MapperException>()));
      expect(() => _decode({'type': 'iconButton', 'id': 'open', 'icon': 'edit'}), throwsA(isA<MapperException>()));
    });
  });
}
