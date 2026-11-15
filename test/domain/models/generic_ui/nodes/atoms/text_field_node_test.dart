import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(TextFieldNode, () {
    test('decodes with defaults', () {
      expect(
        _decode({'type': 'textField', 'id': 'email', 'bind': 'form.email'}),
        const TextFieldNode(id: 'email', bind: 'form.email'),
      );
    });

    test('decodes literal label and hint', () {
      expect(
        _decode({
          'type': 'textField',
          'id': 'email',
          'bind': 'form.email',
          'label': 'Email',
          'hint': 'you@example.com',
        }),
        const TextFieldNode(id: 'email', bind: 'form.email', label: Literal('Email'), hint: Literal('you@example.com')),
      );
    });

    test('decodes bound label and hint', () {
      expect(
        _decode({
          'type': 'textField',
          'id': 'email',
          'bind': 'form.email',
          'label': {r'$bind': 'labels.email'},
          'hint': {r'$bind': 'hints.email', 'fallback': 'Email'},
        }),
        const TextFieldNode(
          id: 'email',
          bind: 'form.email',
          label: Binding('labels.email'),
          hint: Binding('hints.email', fallback: 'Email'),
        ),
      );
    });

    test('decodes onChanged and onSubmit actions in order', () {
      expect(
        _decode({
          'type': 'textField',
          'id': 'name',
          'bind': 'name',
          'onChanged': [
            {'type': 'updateState', 'path': 'edits', 'op': 'increment'},
            {'type': 'teleport'},
          ],
          'onSubmit': [
            {'type': 'showMessage', 'text': 'Saved'},
            {'type': 'back'},
          ],
        }),
        const TextFieldNode(
          id: 'name',
          bind: 'name',
          onChanged: [
            UpdateStateAction(path: 'edits', op: Literal(UpdateOp.increment)),
            UnknownAction(),
          ],
          onSubmit: [
            ShowMessageAction(text: Literal('Saved')),
            BackAction(),
          ],
        ),
      );
    });

    test('fails without a bind path', () {
      expect(() => _decode({'type': 'textField', 'id': 'name'}), throwsA(isA<MapperException>()));
    });

    test('fails with actions that are not a list', () {
      expect(
        () => _decode({'type': 'textField', 'id': 'name', 'bind': 'name', 'onSubmit': 'back'}),
        throwsA(isA<MapperException>()),
      );
    });

    test('actions lists onChanged then onSubmit', () {
      const node = TextFieldNode(
        id: 'name',
        bind: 'name',
        onChanged: [UpdateStateAction(path: 'edits', op: Literal(UpdateOp.increment))],
        onSubmit: [BackAction()],
      );

      expect(node.actions, [...node.onChanged, ...node.onSubmit]);
      expect(node.childNodes, isEmpty);
    });
  });
}
