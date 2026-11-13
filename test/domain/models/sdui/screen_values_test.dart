import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/domain/models/sdui/screen_values.dart';
import 'package:insaeng/domain/result.dart';

ScreenValues _ok(Result<ScreenValues> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw StateError('expected ok, got $failure'),
};

Matcher _isOk(Map<String, Object?> values) =>
    isA<Ok<ScreenValues>>().having((r) => r.value, 'value', ScreenValues(values));

Matcher _isErr<T extends ScreenValuesFailure>() =>
    isA<Err<ScreenValues>>().having((r) => r.failure, 'failure', isA<T>());

void main() {
  group(ScreenValues, () {
    final values = ScreenValues(const {
      'count': 2,
      'flag': false,
      'name': 'Kim',
      'user': {
        'name': 'Lee',
        'tags': ['a', 'b'],
      },
      'todos': [
        {'title': 'first', 'done': false},
        {'title': 'second', 'done': true},
      ],
      'nothing': null,
    });

    group('get', () {
      test('reads a top-level key', () {
        expect(values.get('count'), 2);
        expect(values.get('name'), 'Kim');
      });

      test('reads nested keys and list indexes', () {
        expect(values.get('user.name'), 'Lee');
        expect(values.get('user.tags.1'), 'b');
        expect(values.get('todos.0.title'), 'first');
        expect(values.get('todos.1.done'), true);
      });

      test('returns a whole subtree', () {
        expect(values.get('user.tags'), ['a', 'b']);
      });

      test('returns null for missing paths', () {
        expect(values.get('missing'), isNull);
        expect(values.get('user.missing'), isNull);
        expect(values.get('missing.deeper.still'), isNull);
        expect(values.get('nothing.deeper'), isNull);
      });

      test('returns null for out-of-range or non-numeric list indexes', () {
        expect(values.get('todos.2'), isNull);
        expect(values.get('todos.-1'), isNull);
        expect(values.get('todos.first'), isNull);
        expect(values.get('todos.+1'), isNull);
      });

      test('returns null when traversing through a scalar', () {
        expect(values.get('count.value'), isNull);
        expect(values.get('name.0'), isNull);
      });

      test('treats numeric segments as keys inside maps', () {
        expect(
          ScreenValues(const {
            'byId': {'7': 'seven'},
          }).get('byId.7'),
          'seven',
        );
      });
    });

    group('immutability', () {
      test('copies its input so later mutations do not leak in', () {
        final source = <String, Object?>{
          'list': [1],
        };
        final frozen = ScreenValues(source);
        (source['list']! as List<Object?>).add(2);
        source['extra'] = true;

        expect(frozen.get('list'), [1]);
        expect(frozen.get('extra'), isNull);
      });

      test('exposes unmodifiable maps and lists', () {
        expect(() => values.values['count'] = 3, throwsUnsupportedError);
        expect(() => (values.get('user.tags')! as List<Object?>).add('c'), throwsUnsupportedError);
        expect(() => (values.get('user')! as Map<String, Object?>)['name'] = 'x', throwsUnsupportedError);
      });

      test('updates leave the original untouched', () {
        _ok(values.update('user.tags', UpdateOp.append, 'c'));
        _ok(values.set('todos.0.title', 'changed'));

        expect(values.get('user.tags'), ['a', 'b']);
        expect(values.get('todos.0.title'), 'first');
      });

      test('freezes values written into the tree', () {
        final item = <String, Object?>{'id': 1};
        final updated = _ok(values.set('item', item));
        item['id'] = 2;

        expect(updated.get('item.id'), 1);
        expect(() => (updated.get('item')! as Map<String, Object?>)['id'] = 3, throwsUnsupportedError);
      });
    });

    group('equality', () {
      test('compares trees deeply', () {
        expect(
          ScreenValues(const {
            'a': [
              {'b': 1},
            ],
          }),
          ScreenValues(const {
            'a': [
              {'b': 1},
            ],
          }),
        );
        expect(
          ScreenValues(const {
            'a': [
              {'b': 1},
            ],
          }).hashCode,
          ScreenValues(const {
            'a': [
              {'b': 1},
            ],
          }).hashCode,
        );
        expect(ScreenValues(const {'a': 1}), isNot(ScreenValues(const {'a': 2})));
      });

      test('empty equals a default instance', () {
        expect(ScreenValues.empty, ScreenValues());
        expect(ScreenValues.empty.values, isEmpty);
      });
    });

    group('set', () {
      test('replaces an existing value', () {
        expect(ScreenValues(const {'a': 1}).set('a', 'x'), _isOk({'a': 'x'}));
      });

      test('replaces a value inside a list', () {
        expect(
          ScreenValues(const {
            'l': [1, 2],
          }).set('l.1', 9),
          _isOk({
            'l': [1, 9],
          }),
        );
      });

      test('creates a missing key and its missing parents', () {
        expect(
          ScreenValues.empty.set('a.b.c', true),
          _isOk({
            'a': {
              'b': {'c': true},
            },
          }),
        );
      });

      test('creates under a null parent', () {
        expect(
          ScreenValues(const {'a': null}).set('a.b', 1),
          _isOk({
            'a': {'b': 1},
          }),
        );
      });

      test('can store null and structured values', () {
        expect(ScreenValues(const {'a': 1}).set('a', null), _isOk({'a': null}));
        expect(
          ScreenValues.empty.set('a', {
            'b': [1],
          }),
          _isOk({
            'a': {
              'b': [1],
            },
          }),
        );
      });

      test('keeps sibling values', () {
        final updated = _ok(values.set('user.name', 'Park'));

        expect(updated.get('user.name'), 'Park');
        expect(updated.get('user.tags'), ['a', 'b']);
        expect(updated.get('count'), 2);
      });

      test('fails when a parent is a scalar', () {
        expect(ScreenValues(const {'a': 1}).set('a.b', 2), _isErr<ScreenValuesTypeMismatch>());
      });

      test('fails on a non-numeric list index', () {
        expect(
          ScreenValues(const {
            'l': [1],
          }).set('l.x', 2),
          _isErr<ScreenValuesTypeMismatch>(),
        );
      });

      test('fails on an out-of-range list index', () {
        expect(
          ScreenValues(const {
            'l': [1],
          }).set('l.1', 2),
          _isErr<ScreenValuesIndexOutOfRange>(),
        );
        expect(
          ScreenValues(const {
            'l': [1],
          }).set('l.1.a', 2),
          _isErr<ScreenValuesIndexOutOfRange>(),
        );
      });

      test('update with set matches set', () {
        expect(ScreenValues.empty.update('a', UpdateOp.set, 1), ScreenValues.empty.set('a', 1));
      });
    });

    group('toggle', () {
      test('flips a bool', () {
        expect(ScreenValues(const {'f': false}).update('f', UpdateOp.toggle), _isOk({'f': true}));
        expect(ScreenValues(const {'f': true}).update('f', UpdateOp.toggle), _isOk({'f': false}));
      });

      test('flips a nested bool', () {
        expect(values.update('todos.0.done', UpdateOp.toggle).map((v) => v.get('todos.0.done')), true);
      });

      test('sets a missing path to true', () {
        expect(
          ScreenValues.empty.update('a.f', UpdateOp.toggle),
          _isOk({
            'a': {'f': true},
          }),
        );
        expect(ScreenValues(const {'f': null}).update('f', UpdateOp.toggle), _isOk({'f': true}));
      });

      test('fails on a non-bool', () {
        expect(ScreenValues(const {'f': 1}).update('f', UpdateOp.toggle), _isErr<ScreenValuesTypeMismatch>());
        expect(ScreenValues(const {'f': 'true'}).update('f', UpdateOp.toggle), _isErr<ScreenValuesTypeMismatch>());
      });
    });

    group('increment', () {
      test('adds one by default', () {
        expect(ScreenValues(const {'n': 2}).update('n', UpdateOp.increment), _isOk({'n': 3}));
      });

      test('adds the given step, including negatives and doubles', () {
        expect(ScreenValues(const {'n': 2}).update('n', UpdateOp.increment, 5), _isOk({'n': 7}));
        expect(ScreenValues(const {'n': 2}).update('n', UpdateOp.increment, -3), _isOk({'n': -1}));
        expect(ScreenValues(const {'n': 1.5}).update('n', UpdateOp.increment, 1), _isOk({'n': 2.5}));
      });

      test('keeps ints as ints', () {
        expect(ScreenValues(const {'n': 2}).update('n', UpdateOp.increment).map((v) => v.get('n')), isA<int>());
      });

      test('treats a missing path as zero', () {
        expect(ScreenValues.empty.update('n', UpdateOp.increment), _isOk({'n': 1}));
        expect(ScreenValues.empty.update('n', UpdateOp.increment, -2), _isOk({'n': -2}));
        expect(ScreenValues(const {'n': null}).update('n', UpdateOp.increment), _isOk({'n': 1}));
      });

      test('fails on a non-number value', () {
        expect(ScreenValues(const {'n': '2'}).update('n', UpdateOp.increment), _isErr<ScreenValuesTypeMismatch>());
        expect(ScreenValues(const {'n': true}).update('n', UpdateOp.increment), _isErr<ScreenValuesTypeMismatch>());
      });

      test('fails on a non-number step', () {
        expect(ScreenValues(const {'n': 2}).update('n', UpdateOp.increment, '1'), _isErr<ScreenValuesTypeMismatch>());
      });
    });

    group('append', () {
      test('appends to a list', () {
        expect(
          ScreenValues(const {
            'l': [1],
          }).update('l', UpdateOp.append, 2),
          _isOk({
            'l': [1, 2],
          }),
        );
      });

      test('appends structured values', () {
        expect(values.update('todos', UpdateOp.append, {'title': 'third'}).map((v) => v.get('todos.2.title')), 'third');
      });

      test('creates a one-item list at a missing path', () {
        expect(
          ScreenValues.empty.update('a.l', UpdateOp.append, 'x'),
          _isOk({
            'a': {
              'l': ['x'],
            },
          }),
        );
        expect(
          ScreenValues(const {'l': null}).update('l', UpdateOp.append, 'x'),
          _isOk({
            'l': ['x'],
          }),
        );
      });

      test('fails on a non-list', () {
        expect(ScreenValues(const {'l': 'abc'}).update('l', UpdateOp.append, 'd'), _isErr<ScreenValuesTypeMismatch>());
        expect(
          ScreenValues(const {
            'l': {'a': 1},
          }).update('l', UpdateOp.append, 'd'),
          _isErr<ScreenValuesTypeMismatch>(),
        );
      });
    });

    group('removeAt', () {
      test('removes the item at the index', () {
        expect(
          ScreenValues(const {
            'l': ['a', 'b', 'c'],
          }).update('l', UpdateOp.removeAt, 1),
          _isOk({
            'l': ['a', 'c'],
          }),
        );
      });

      test('removes from a nested list', () {
        expect(values.update('todos', UpdateOp.removeAt, 0).map((v) => v.get('todos.0.title')), 'second');
      });

      test('fails on a missing path', () {
        expect(ScreenValues.empty.update('l', UpdateOp.removeAt, 0), _isErr<ScreenValuesMissingPath>());
        expect(ScreenValues.empty.update('a.l', UpdateOp.removeAt, 0), _isErr<ScreenValuesMissingPath>());
        expect(ScreenValues(const {'l': null}).update('l', UpdateOp.removeAt, 0), _isErr<ScreenValuesMissingPath>());
      });

      test('fails on an out-of-range index', () {
        final list = ScreenValues(const {
          'l': ['a'],
        });

        expect(list.update('l', UpdateOp.removeAt, 1), _isErr<ScreenValuesIndexOutOfRange>());
        expect(list.update('l', UpdateOp.removeAt, -1), _isErr<ScreenValuesIndexOutOfRange>());
      });

      test('fails on a non-list', () {
        expect(ScreenValues(const {'l': 'abc'}).update('l', UpdateOp.removeAt, 0), _isErr<ScreenValuesTypeMismatch>());
      });

      test('fails on a non-int index', () {
        final list = ScreenValues(const {
          'l': ['a'],
        });

        expect(list.update('l', UpdateOp.removeAt), _isErr<ScreenValuesTypeMismatch>());
        expect(list.update('l', UpdateOp.removeAt, '0'), _isErr<ScreenValuesTypeMismatch>());
        expect(list.update('l', UpdateOp.removeAt, 0.5), _isErr<ScreenValuesTypeMismatch>());
      });
    });

    group('merge', () {
      test('shallow-merges into a map', () {
        expect(
          ScreenValues(const {
            'm': {
              'a': 1,
              'b': {'x': 1},
            },
          }).update('m', UpdateOp.merge, {
            'b': {'y': 2},
            'c': 3,
          }),
          _isOk({
            'm': {
              'a': 1,
              'b': {'y': 2},
              'c': 3,
            },
          }),
        );
      });

      test('creates the map at a missing path', () {
        expect(
          ScreenValues.empty.update('a.m', UpdateOp.merge, {'k': 'v'}),
          _isOk({
            'a': {
              'm': {'k': 'v'},
            },
          }),
        );
        expect(
          ScreenValues(const {'m': null}).update('m', UpdateOp.merge, {'k': 'v'}),
          _isOk({
            'm': {'k': 'v'},
          }),
        );
      });

      test('fails on a non-map value', () {
        expect(
          ScreenValues(const {'m': 1}).update('m', UpdateOp.merge, {'k': 'v'}),
          _isErr<ScreenValuesTypeMismatch>(),
        );
        expect(
          ScreenValues(const {
            'm': [1],
          }).update('m', UpdateOp.merge, {'k': 'v'}),
          _isErr<ScreenValuesTypeMismatch>(),
        );
      });

      test('fails on a non-map patch', () {
        expect(
          ScreenValues(const {
            'm': {'a': 1},
          }).update('m', UpdateOp.merge, 1),
          _isErr<ScreenValuesTypeMismatch>(),
        );
        expect(ScreenValues.empty.update('m', UpdateOp.merge), _isErr<ScreenValuesTypeMismatch>());
      });
    });

    test('a failed update through a scalar parent fails for every op', () {
      final scalar = ScreenValues(const {'a': 1});

      for (final op in UpdateOp.values) {
        expect(scalar.update('a.b', op, 0), _isErr<ScreenValuesTypeMismatch>(), reason: op.name);
      }
    });
  });
}

extension on Result<ScreenValues> {
  Object? map(Object? Function(ScreenValues values) read) => read(_ok(this));
}
