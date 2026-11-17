import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(DayPickerNode, () {
    test('decodes with defaults', () {
      expect(
        _decode({
          'type': 'dayPicker',
          'id': 'day',
          'label': 'Mon, Jan 12',
          'previousLabel': 'Previous day',
          'nextLabel': 'Next day',
        }),
        const DayPickerNode(
          id: 'day',
          label: Literal('Mon, Jan 12'),
          previousLabel: Literal('Previous day'),
          nextLabel: Literal('Next day'),
        ),
      );
    });

    test('decodes bound labels', () {
      expect(
        _decode({
          'type': 'dayPicker',
          'id': 'day',
          'label': {r'$bind': 'day.label', 'fallback': 'Today'},
          'previousLabel': {r'$bind': 'day.previous'},
          'nextLabel': {r'$bind': 'day.next'},
        }),
        const DayPickerNode(
          id: 'day',
          label: Binding('day.label', fallback: 'Today'),
          previousLabel: Binding('day.previous'),
          nextLabel: Binding('day.next'),
        ),
      );
    });

    test('decodes onPrevious and onNext in order and exposes both as its actions', () {
      final node = _decode({
        'type': 'dayPicker',
        'id': 'day',
        'label': 'Mon, Jan 12',
        'previousLabel': 'Previous day',
        'nextLabel': 'Next day',
        'onPrevious': [
          {'type': 'updateState', 'path': 'offset', 'op': 'increment', 'value': -1},
          {'type': 'reload'},
        ],
        'onNext': [
          {'type': 'updateState', 'path': 'offset', 'op': 'increment'},
        ],
      });

      const onPrevious = [
        UpdateStateAction(path: 'offset', op: Literal(UpdateOp.increment), value: Literal(-1)),
        ReloadAction(),
      ];
      const onNext = [UpdateStateAction(path: 'offset', op: Literal(UpdateOp.increment))];
      expect(
        node,
        const DayPickerNode(
          id: 'day',
          label: Literal('Mon, Jan 12'),
          previousLabel: Literal('Previous day'),
          nextLabel: Literal('Next day'),
          onPrevious: onPrevious,
          onNext: onNext,
        ),
      );
      expect(node.actions, [...onPrevious, ...onNext]);
    });

    test('decodes a label tap with its hint and exposes it after the chevron actions', () {
      final node = _decode({
        'type': 'dayPicker',
        'id': 'day',
        'label': 'Mon, Jan 12',
        'previousLabel': 'Previous day',
        'nextLabel': 'Next day',
        'labelTapHint': {r'$bind': 'day.hint', 'fallback': 'Go to today'},
        'onNext': [
          {'type': 'updateState', 'path': 'offset', 'op': 'increment'},
        ],
        'onLabelTap': [
          {'type': 'updateState', 'path': 'offset', 'value': 0},
          {'type': 'reload'},
        ],
      });

      const onNext = [UpdateStateAction(path: 'offset', op: Literal(UpdateOp.increment))];
      const onLabelTap = [UpdateStateAction(path: 'offset', value: Literal(0)), ReloadAction()];
      expect(
        node,
        const DayPickerNode(
          id: 'day',
          label: Literal('Mon, Jan 12'),
          previousLabel: Literal('Previous day'),
          nextLabel: Literal('Next day'),
          labelTapHint: Binding('day.hint', fallback: 'Go to today'),
          onNext: onNext,
          onLabelTap: onLabelTap,
        ),
      );
      expect(node.actions, [...onNext, ...onLabelTap]);
    });

    test('fails without a label or a chevron label', () {
      const json = {
        'type': 'dayPicker',
        'id': 'day',
        'label': 'Mon, Jan 12',
        'previousLabel': 'Previous day',
        'nextLabel': 'Next day',
      };
      for (final key in ['label', 'previousLabel', 'nextLabel']) {
        expect(() => _decode({...json}..remove(key)), throwsA(isA<MapperException>()), reason: key);
      }
    });
  });
}
