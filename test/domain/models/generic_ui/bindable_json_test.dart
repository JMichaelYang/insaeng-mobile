import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable_json.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';

void main() {
  group(BindableJson, () {
    group('decode', () {
      test('wraps scalars as literals', () {
        for (final value in ['a', 1, 2.5, true, null]) {
          expect(BindableJson.decode(value), JsonLiteral(value), reason: '$value');
        }
      });

      test('parses a binding with or without a fallback', () {
        expect(BindableJson.decode({r'$bind': 'form.email'}), const JsonBinding(Binding('form.email')));
        expect(
          BindableJson.decode({r'$bind': 'user.name', 'fallback': 'Guest'}),
          const JsonBinding(Binding('user.name', fallback: 'Guest')),
        );
      });

      test('parses bindings nested in objects and lists', () {
        expect(
          BindableJson.decode({
            'user': {
              'email': {r'$bind': 'form.email'},
            },
            'items': [
              'z',
              {r'$bind': 'tags.1'},
            ],
          }),
          const JsonObject({
            'user': JsonObject({'email': JsonBinding(Binding('form.email'))}),
            'items': JsonList([JsonLiteral('z'), JsonBinding(Binding('tags.1'))]),
          }),
        );
      });

      test('fails on a binding whose path is not a string, at any depth', () {
        expect(() => BindableJson.decode({r'$bind': 3}), throwsA(isA<MapperException>()));
        expect(
          () => BindableJson.decode({
            'a': [
              {r'$bind': true},
            ],
          }),
          throwsA(isA<MapperException>()),
        );
      });

      test('fails on a value that is not JSON', () {
        expect(() => BindableJson.decode(DateTime(2026)), throwsA(isA<MapperException>()));
      });
    });

    group('resolve', () {
      final values = GenericValues(const {
        'form': {'email': 'a@b.c', 'age': 30},
        'tags': ['x', 'y'],
      });

      test('keeps literals as they are', () {
        expect(
          const JsonObject({
            'a': JsonLiteral(1),
            'b': JsonLiteral('two'),
            'c': JsonLiteral(true),
            'd': JsonLiteral(null),
          }).resolve(values),
          {'a': 1, 'b': 'two', 'c': true, 'd': null},
        );
      });

      test('resolves bindings to any value type', () {
        expect(
          const JsonObject({
            'email': JsonBinding(Binding('form.email')),
            'age': JsonBinding(Binding('form.age')),
            'form': JsonBinding(Binding('form')),
            'tags': JsonBinding(Binding('tags')),
          }).resolve(values),
          {
            'email': 'a@b.c',
            'age': 30,
            'form': {'email': 'a@b.c', 'age': 30},
            'tags': ['x', 'y'],
          },
        );
      });

      test('resolves bindings nested in objects and lists', () {
        expect(
          const JsonObject({
            'user': JsonObject({
              'contact': JsonObject({'email': JsonBinding(Binding('form.email'))}),
            }),
            'items': JsonList([
              JsonLiteral('z'),
              JsonBinding(Binding('tags.1')),
              JsonObject({'age': JsonBinding(Binding('form.age'))}),
            ]),
          }).resolve(values),
          {
            'user': {
              'contact': {'email': 'a@b.c'},
            },
            'items': [
              'z',
              'y',
              {'age': 30},
            ],
          },
        );
      });

      test('uses the fallback for a missing path, or null without one', () {
        expect(
          const JsonObject({
            'name': JsonBinding(Binding('user.name', fallback: 'Guest')),
            'phone': JsonBinding(Binding('user.phone')),
          }).resolve(values),
          {'name': 'Guest', 'phone': null},
        );
      });
    });

    test('encodes back to the decoded JSON', () {
      final json = {
        'email': {r'$bind': 'form.email'},
        'name': {r'$bind': 'user.name', 'fallback': 'Guest'},
        'remember': true,
        'meta': {
          'tags': [
            'x',
            {r'$bind': 'tag'},
            null,
          ],
        },
      };

      expect(BindableJson.decode(json).encode(), json);
    });
  });

  group(BindableJsonHook, () {
    test('passes null and decoded values through', () {
      const json = JsonLiteral(1);

      expect(const BindableJsonHook().beforeDecode(null), isNull);
      expect(const BindableJsonHook().beforeDecode(json), same(json));
    });

    test('decodes and encodes raw JSON', () {
      expect(const BindableJsonHook().beforeDecode({r'$bind': 'form'}), const JsonBinding(Binding('form')));
      expect(const BindableJsonHook().beforeEncode(const JsonBinding(Binding('form'))), {r'$bind': 'form'});
    });
  });
}
