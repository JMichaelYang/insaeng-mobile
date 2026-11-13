import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_action.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:insaeng/domain/models/generic_ui/nodes/generic_node.dart';

GenericNode _decode(Map<String, Object?> json) => GenericNodeMapper.fromMap(json);

void main() {
  group(GenericNode, () {
    test('fails without an id', () {
      for (final type in ['column', 'appBar', 'text', 'button', 'carousel']) {
        expect(() => _decode({'type': type, 'text': 'a', 'label': 'a'}), throwsA(isA<MapperException>()), reason: type);
      }
    });

    group(ColumnNode, () {
      test('decodes with defaults', () {
        expect(_decode({'type': 'column', 'id': 'root'}), const ColumnNode(id: 'root'));
      });

      test('decodes spacing and alignment tokens', () {
        expect(
          _decode({'type': 'column', 'id': 'root', 'spacing': 'md', 'alignment': 'center'}),
          const ColumnNode(id: 'root', spacing: Literal(SpacingToken.md), alignment: Literal(AlignmentToken.center)),
        );
      });

      test('decodes bound spacing and alignment', () {
        expect(
          _decode({
            'type': 'column',
            'id': 'root',
            'spacing': {r'$bind': 'gap', 'fallback': 'lg'},
            'alignment': {r'$bind': 'align'},
          }),
          const ColumnNode(
            id: 'root',
            spacing: Binding('gap', fallback: SpacingToken.lg),
            alignment: Binding('align'),
          ),
        );
      });

      test('falls back to the default for unknown tokens', () {
        expect(
          _decode({'type': 'column', 'id': 'root', 'spacing': 'huge', 'alignment': 'justify'}),
          const ColumnNode(id: 'root'),
        );
      });

      test('decodes nested children', () {
        expect(
          _decode({
            'type': 'column',
            'id': 'root',
            'children': [
              {'type': 'appBar', 'id': 'appBar', 'title': 'Counter'},
              {
                'type': 'column',
                'id': 'counter',
                'children': [
                  {'type': 'text', 'id': 'count', 'text': 'Zero'},
                ],
              },
            ],
          }),
          const ColumnNode(
            id: 'root',
            children: [
              AppBarNode(id: 'appBar', title: Literal('Counter')),
              ColumnNode(
                id: 'counter',
                children: [TextNode(id: 'count', text: Literal('Zero'))],
              ),
            ],
          ),
        );
      });
    });

    group(AppBarNode, () {
      test('decodes with defaults', () {
        expect(_decode({'type': 'appBar', 'id': 'appBar'}), const AppBarNode(id: 'appBar'));
      });

      test('decodes title and every leading token', () {
        for (final leading in AppBarLeadingToken.values) {
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
            leading: Binding('leading', fallback: AppBarLeadingToken.back),
          ),
        );
      });

      test('falls back to no leading for an unknown token', () {
        expect(_decode({'type': 'appBar', 'id': 'appBar', 'leading': 'menu'}), const AppBarNode(id: 'appBar'));
      });
    });

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

    group(ButtonNode, () {
      test('decodes with defaults', () {
        expect(
          _decode({'type': 'button', 'id': 'add', 'label': 'Add'}),
          const ButtonNode(id: 'add', label: Literal('Add')),
        );
      });

      test('decodes every variant and loading', () {
        for (final variant in ButtonVariantToken.values) {
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
            variant: Binding('ctaVariant', fallback: ButtonVariantToken.secondary),
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

    group(UnknownNode, () {
      test('decodes an unknown type without a fallback', () {
        expect(_decode({'type': 'carousel', 'id': 'hero', 'items': <Object?>[]}), const UnknownNode(id: 'hero'));
      });

      test('decodes an unknown type with its fallback', () {
        expect(
          _decode({
            'type': 'carousel',
            'id': 'hero',
            'fallback': {'type': 'text', 'id': 'heroFallback', 'text': 'Featured'},
          }),
          const UnknownNode(
            id: 'hero',
            fallback: TextNode(id: 'heroFallback', text: Literal('Featured')),
          ),
        );
      });

      test('decodes a nested unknown fallback', () {
        expect(
          _decode({
            'type': 'carousel',
            'id': 'hero',
            'fallback': {
              'type': 'grid',
              'id': 'heroGrid',
              'fallback': {'type': 'column', 'id': 'heroColumn'},
            },
          }),
          const UnknownNode(
            id: 'hero',
            fallback: UnknownNode(
              id: 'heroGrid',
              fallback: ColumnNode(id: 'heroColumn'),
            ),
          ),
        );
      });

      test('decodes an unknown child inside a known node', () {
        expect(
          _decode({
            'type': 'column',
            'id': 'root',
            'children': [
              {'type': 'carousel', 'id': 'hero'},
            ],
          }),
          const ColumnNode(
            id: 'root',
            children: [UnknownNode(id: 'hero')],
          ),
        );
      });
    });

    test('ignores unknown properties', () {
      expect(
        _decode({'type': 'text', 'id': 'hello', 'text': 'Hello', 'color': 'red'}),
        const TextNode(id: 'hello', text: Literal('Hello')),
      );
    });
  });
}
