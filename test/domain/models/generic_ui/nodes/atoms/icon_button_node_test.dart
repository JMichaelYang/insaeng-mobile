import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(IconButtonNode, () {
    test('decodes with defaults', () {
      expect(
        _decode({'type': 'iconButton', 'id': 'reload', 'icon': 'refresh'}),
        const IconButtonNode(id: 'reload', icon: Literal(IconButtonIcon.refresh)),
      );
    });

    test('falls back to the default icon for an unknown icon', () {
      expect(
        _decode({'type': 'iconButton', 'id': 'reload', 'icon': 'unknown'}),
        const IconButtonNode(id: 'reload', icon: Literal(IconButtonIcon.refresh)),
      );
    });

    test('decodes a bound label and onTap actions', () {
      expect(
        _decode({
          'type': 'iconButton',
          'id': 'reload',
          'icon': 'refresh',
          'label': {r'$bind': 'reloadLabel'},
          'onTap': [
            {'type': 'reload'},
          ],
        }),
        const IconButtonNode(
          id: 'reload',
          icon: Literal(IconButtonIcon.refresh),
          label: Binding('reloadLabel'),
          onTap: [ReloadAction()],
        ),
      );
    });

    test('exposes its onTap actions', () {
      const node = IconButtonNode(id: 'reload', icon: Literal(IconButtonIcon.refresh), onTap: [ReloadAction()]);

      expect(node.actions, const [ReloadAction()]);
    });

    test('round-trips through JSON', () {
      const node = IconButtonNode(
        id: 'reload',
        icon: Literal(IconButtonIcon.refresh),
        label: Literal('Reload'),
        onTap: [ReloadAction()],
      );

      expect(_decode(node.toMap()), node);
    });
  });
}
