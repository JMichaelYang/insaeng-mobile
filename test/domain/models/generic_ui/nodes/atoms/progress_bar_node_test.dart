import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(ProgressBarNode, () {
    test('decodes literal value and max', () {
      expect(
        _decode({'type': 'progressBar', 'id': 'progress', 'value': 2, 'max': 5}),
        const ProgressBarNode(id: 'progress', value: Literal(2), max: Literal(5)),
      );
    });

    test('decodes a bound value and max', () {
      expect(
        _decode({
          'type': 'progressBar',
          'id': 'progress',
          'value': {r'$bind': 'progress.done', 'fallback': 0},
          'max': {r'$bind': 'progress.total'},
        }),
        const ProgressBarNode(
          id: 'progress',
          value: Binding('progress.done', fallback: 0),
          max: Binding('progress.total'),
        ),
      );
    });

    test('round-trips through JSON', () {
      const node = ProgressBarNode(id: 'progress', value: Binding('progress.done', fallback: 0), max: Literal(3));

      expect(_decode(node.toMap()), node);
    });
  });
}
