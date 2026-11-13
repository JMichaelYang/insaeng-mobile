import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(ButtonNode, () {
    test('decodes with defaults', () {
      expect(
        _decode({'type': 'button', 'id': 'add', 'label': 'Add'}),
        const ButtonNode(id: 'add', label: Literal('Add')),
      );
    });

    test('decodes every variant and loading', () {
      for (final variant in ButtonVariant.values) {
        expect(
          _decode({'type': 'button', 'id': 'add', 'label': 'Add', 'variant': variant.name, 'loading': true}),
          ButtonNode(id: 'add', label: const Literal('Add'), variant: Literal(variant), loading: const Literal(true)),
          reason: variant.name,
        );
      }
    });

    test('decodes bound label, variant, and loading', () {
      expect(
        _decode({
          'type': 'button',
          'id': 'submit',
          'label': {r'$bind': 'cta'},
          'variant': {r'$bind': 'ctaVariant', 'fallback': 'secondary'},
          'loading': {r'$bind': 'submitting', 'fallback': false},
        }),
        const ButtonNode(
          id: 'submit',
          label: Binding('cta'),
          variant: Binding('ctaVariant', fallback: ButtonVariant.secondary),
          loading: Binding('submitting', fallback: false),
        ),
      );
    });

    test('decodes onTap actions in order', () {
      expect(
        _decode({
          'type': 'button',
          'id': 'add',
          'label': 'Add',
          'onTap': [
            {'type': 'updateState', 'path': 'count', 'op': 'increment'},
            {'type': 'showMessage', 'text': 'Added'},
            {'type': 'teleport'},
          ],
        }),
        const ButtonNode(
          id: 'add',
          label: Literal('Add'),
          onTap: [
            UpdateStateAction(path: 'count', op: Literal(UpdateOp.increment)),
            ShowMessageAction(text: Literal('Added')),
            UnknownAction(),
          ],
        ),
      );
    });

    test('fails without a label or with onTap that is not a list', () {
      expect(() => _decode({'type': 'button', 'id': 'add'}), throwsA(isA<MapperException>()));
      expect(
        () => _decode({'type': 'button', 'id': 'add', 'label': 'Add', 'onTap': 'increment'}),
        throwsA(isA<MapperException>()),
      );
    });
  });
}
