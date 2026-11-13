import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/sdui/bindable.dart';
import 'package:insaeng/domain/models/sdui/screen_values.dart';

part 'bindable_test.mapper.dart';

@MappableClass()
class BindableItem with BindableItemMappable {
  const new({required this.label, this.loading = const Literal(false), this.size});

  @MappableField(hook: BindableHook<String>())
  final Bindable<String> label;

  @MappableField(hook: BindableHook<bool>())
  final Bindable<bool> loading;

  @MappableField(hook: BindableHook<double>())
  final Bindable<double>? size;
}

void main() {
  group(BindableHook, () {
    group('beforeDecode', () {
      test('wraps a literal', () {
        expect(const BindableHook<String>().beforeDecode('Hi'), const Literal('Hi'));
        expect(const BindableHook<bool>().beforeDecode(true), const Literal(true));
      });

      test('converts a literal through the mapper', () {
        expect(const BindableHook<double>().beforeDecode(2), const Literal<double>(2));
      });

      test('reads a binding without a fallback', () {
        expect(const BindableHook<String>().beforeDecode({r'$bind': 'user.name'}), const Binding<String>('user.name'));
      });

      test('reads a binding with a fallback', () {
        expect(
          const BindableHook<String>().beforeDecode({r'$bind': 'user.name', 'fallback': 'Guest'}),
          const Binding('user.name', fallback: 'Guest'),
        );
      });

      test('converts a fallback through the mapper', () {
        expect(
          const BindableHook<double>().beforeDecode({r'$bind': 'size', 'fallback': 1}),
          const Binding<double>('size', fallback: 1),
        );
      });

      test('passes null and decoded values through', () {
        expect(const BindableHook<String>().beforeDecode(null), isNull);
        expect(const BindableHook<String>().beforeDecode(const Literal('Hi')), const Literal('Hi'));
      });

      test('throws on a literal the mapper cannot convert', () {
        expect(() => const BindableHook<double>().beforeDecode('big'), throwsA(isA<MapperException>()));
        expect(() => const BindableHook<int>().beforeDecode({'other': 1}), throwsA(isA<MapperException>()));
      });

      test('throws on a binding whose path is not a string', () {
        expect(() => const BindableHook<String>().beforeDecode({r'$bind': 1}), throwsA(isA<MapperException>()));
      });

      test('throws on a fallback the mapper cannot convert', () {
        expect(
          () => const BindableHook<double>().beforeDecode({r'$bind': 'size', 'fallback': 'big'}),
          throwsA(isA<MapperException>()),
        );
      });
    });

    group('beforeEncode', () {
      test('writes a literal as its value', () {
        expect(const BindableHook<String>().beforeEncode(const Literal('Hi')), 'Hi');
      });

      test('writes a binding as a bind object', () {
        expect(const BindableHook<String>().beforeEncode(const Binding<String>('name')), {r'$bind': 'name'});
        expect(const BindableHook<String>().beforeEncode(const Binding('name', fallback: 'Guest')), {
          r'$bind': 'name',
          'fallback': 'Guest',
        });
      });

      test('passes null through', () {
        expect(const BindableHook<String>().beforeEncode(null), isNull);
      });
    });

    group('on a mappable class', () {
      test('decodes literals and bindings', () {
        final item = BindableItemMapper.fromMap({
          'label': 'Save',
          'loading': {r'$bind': 'submitting', 'fallback': false},
          'size': {r'$bind': 'size'},
        });

        expect(item.label, const Literal('Save'));
        expect(item.loading, const Binding('submitting', fallback: false));
        expect(item.size, const Binding<double>('size'));
      });

      test('applies field defaults when a property is absent', () {
        final item = BindableItemMapper.fromMap({
          'label': {r'$bind': 'title'},
        });

        expect(item.loading, const Literal(false));
        expect(item.size, isNull);
      });

      test('fails when a required property is absent', () {
        expect(() => BindableItemMapper.fromMap({}), throwsA(isA<MapperException>()));
      });

      test('round-trips through toMap', () {
        final json = {
          'label': {r'$bind': 'title', 'fallback': 'Untitled'},
          'loading': true,
          'size': 2.5,
        };

        expect(BindableItemMapper.fromMap(json).toMap(), json);
      });

      test('compares by value', () {
        expect(
          BindableItemMapper.fromMap({
            'label': {r'$bind': 'title'},
          }),
          const BindableItem(label: Binding('title')),
        );
      });
    });
  });

  group(Bindable, () {
    final values = ScreenValues(const {
      'name': 'Kim',
      'count': 3,
      'ratio': 0.5,
      'flag': true,
      'user': {
        'tags': ['a', 'b'],
      },
      'nothing': null,
    });

    group(Literal, () {
      test('resolves to its value', () {
        expect(const Literal('Hi').resolve(values), 'Hi');
        expect(const Literal('Hi').resolve(ScreenValues.empty), 'Hi');
      });
    });

    group(Binding, () {
      test('resolves to the value at its path', () {
        expect(const Binding<String>('name').resolve(values), 'Kim');
        expect(const Binding<int>('count').resolve(values), 3);
        expect(const Binding<bool>('flag').resolve(values), isTrue);
      });

      test('resolves nested keys and list indexes', () {
        expect(const Binding<String>('user.tags.1').resolve(values), 'b');
        expect(const Binding<List<Object?>>('user.tags').resolve(values), ['a', 'b']);
      });

      test('resolves a missing path to null without a fallback', () {
        expect(const Binding<String>('missing').resolve(values), isNull);
        expect(const Binding<String>('user.tags.5').resolve(values), isNull);
        expect(const Binding<String>('nothing').resolve(values), isNull);
      });

      test('resolves a missing path to its fallback', () {
        expect(const Binding('missing', fallback: 'Guest').resolve(values), 'Guest');
        expect(const Binding('name.deeper', fallback: 'Guest').resolve(values), 'Guest');
        expect(const Binding('nothing', fallback: 'Guest').resolve(values), 'Guest');
      });

      test('resolves a value of the wrong type to its fallback', () {
        expect(const Binding('name', fallback: false).resolve(values), isFalse);
        expect(const Binding('user', fallback: 0).resolve(values), 0);
        expect(const Binding<String>('user.tags').resolve(values), isNull);
      });

      test('shows a number or bool bound to a string as text', () {
        expect(const Binding<String>('count').resolve(values), '3');
        expect(const Binding<String>('ratio').resolve(values), '0.5');
        expect(const Binding<String>('flag').resolve(values), 'true');
      });

      test('does not convert a string to a number or bool', () {
        final strings = ScreenValues(const {'count': '3', 'flag': 'true'});

        expect(const Binding('count', fallback: 1).resolve(strings), 1);
        expect(const Binding<bool>('flag').resolve(strings), isNull);
      });

      test('follows the latest values', () {
        const binding = Binding('name', fallback: 'Guest');

        expect(binding.resolve(ScreenValues.empty), 'Guest');
        expect(binding.resolve(ScreenValues(const {'name': 'Lee'})), 'Lee');
      });
    });
  });
}
