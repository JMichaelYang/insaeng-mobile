import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(AppBarNode, () {
    test('decodes with defaults', () {
      expect(_decode({'type': 'appBar', 'id': 'appBar'}), const AppBarNode(id: 'appBar'));
    });

    test('decodes title and every leading token', () {
      for (final leading in AppBarLeading.values) {
        expect(
          _decode({'type': 'appBar', 'id': 'appBar', 'title': 'Log in', 'leading': leading.name}),
          AppBarNode(id: 'appBar', title: const Literal('Log in'), leading: Literal(leading)),
          reason: leading.name,
        );
      }
    });

    test('decodes bound title and leading', () {
      expect(
        _decode({
          'type': 'appBar',
          'id': 'appBar',
          'title': {r'$bind': 'user.name', 'fallback': 'Guest'},
          'leading': {r'$bind': 'leading', 'fallback': 'back'},
        }),
        const AppBarNode(
          id: 'appBar',
          title: Binding('user.name', fallback: 'Guest'),
          leading: Binding('leading', fallback: AppBarLeading.back),
        ),
      );
    });

    test('falls back to no leading for an unknown token', () {
      expect(_decode({'type': 'appBar', 'id': 'appBar', 'leading': 'menu'}), const AppBarNode(id: 'appBar'));
    });
  });
}
