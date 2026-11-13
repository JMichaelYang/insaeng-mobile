import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:insaeng/domain/result.dart';
import 'package:meta/meta.dart';

part 'generic_values.mapper.dart';

@MappableEnum()
enum UpdateOp { set, toggle, increment, append, removeAt, merge }

sealed class GenericValuesFailure extends Failure {
  const new();
}

final class GenericValuesTypeMismatch extends GenericValuesFailure {
  const new();
}

final class GenericValuesIndexOutOfRange extends GenericValuesFailure {
  const new();
}

final class GenericValuesMissingPath extends GenericValuesFailure {
  const new();
}

@immutable
final class GenericValues {
  new([Map<String, Object?> values = const {}]) : _root = _freezeMap(values);

  const new _(this._root);

  static const empty = GenericValues._(<String, Object?>{});

  static const _equality = DeepCollectionEquality();
  static final _indexPattern = RegExp(r'^\d+$');

  final Map<String, Object?> _root;

  Map<String, Object?> get values => _root;

  Object? get(String path) {
    Object? node = _root;
    for (final key in path.split('.')) {
      node = switch (node) {
        Map() => node[key],
        List() => switch (_index(key)) {
          final index? when index < node.length => node[index],
          _ => null,
        },
        _ => null,
      };
    }
    return node;
  }

  Result<GenericValues> set(String path, Object? value) => update(path, UpdateOp.set, value);

  Result<GenericValues> update(String path, UpdateOp op, [Object? value]) {
    final result = _write(_root, path.split('.'), (current) => _apply(op, current, value));
    return switch (result) {
      Ok(:final value) => Result.ok(GenericValues._(value! as Map<String, Object?>)),
      Err(:final failure) => Result.err(failure),
    };
  }

  static Result<Object?> _write(Object? node, List<String> keys, Result<Object?> Function(Object? current) apply) {
    if (keys.isEmpty) return apply(node);
    final [key, ...rest] = keys;
    switch (node) {
      case null:
        return _write(const <String, Object?>{}, keys, apply);
      case Map<String, Object?>():
        return switch (_write(node[key], rest, apply)) {
          Ok(:final value) => Result.ok(Map<String, Object?>.unmodifiable({...node, key: value})),
          final Err<Object?> err => err,
        };
      case List<Object?>():
        final index = _index(key);
        if (index == null) return const Result.err(GenericValuesTypeMismatch());
        if (index >= node.length) return const Result.err(GenericValuesIndexOutOfRange());
        return switch (_write(node[index], rest, apply)) {
          Ok(:final value) => Result.ok(List<Object?>.unmodifiable([...node]..[index] = value)),
          final Err<Object?> err => err,
        };
      default:
        return const Result.err(GenericValuesTypeMismatch());
    }
  }

  static Result<Object?> _apply(UpdateOp op, Object? current, Object? value) => switch (op) {
    UpdateOp.set => Result.ok(_freeze(value)),
    UpdateOp.toggle => switch (current) {
      null => const Result.ok(true),
      final bool flag => Result.ok(!flag),
      _ => const Result.err(GenericValuesTypeMismatch()),
    },
    UpdateOp.increment => switch ((current ?? 0, value ?? 1)) {
      (final num base, final num step) => Result.ok(base + step),
      _ => const Result.err(GenericValuesTypeMismatch()),
    },
    UpdateOp.append => switch (current) {
      null => Result.ok(List<Object?>.unmodifiable([_freeze(value)])),
      final List<Object?> list => Result.ok(List<Object?>.unmodifiable([...list, _freeze(value)])),
      _ => const Result.err(GenericValuesTypeMismatch()),
    },
    UpdateOp.removeAt => switch ((current, value)) {
      (null, _) => const Result.err(GenericValuesMissingPath()),
      (final List<Object?> list, final int index) when index >= 0 && index < list.length => Result.ok(
        List<Object?>.unmodifiable([...list]..removeAt(index)),
      ),
      (List<Object?>(), int()) => const Result.err(GenericValuesIndexOutOfRange()),
      _ => const Result.err(GenericValuesTypeMismatch()),
    },
    UpdateOp.merge => switch ((current, value)) {
      (null, final Map<Object?, Object?> patch) => Result.ok(_freezeMap(patch)),
      (final Map<String, Object?> base, final Map<Object?, Object?> patch) => Result.ok(
        Map<String, Object?>.unmodifiable({...base, ..._freezeMap(patch)}),
      ),
      _ => const Result.err(GenericValuesTypeMismatch()),
    },
  };

  static int? _index(String key) => _indexPattern.hasMatch(key) ? int.tryParse(key) : null;

  static Object? _freeze(Object? value) => switch (value) {
    final Map<Object?, Object?> map => _freezeMap(map),
    final List<Object?> list => List<Object?>.unmodifiable(list.map(_freeze)),
    _ => value,
  };

  static Map<String, Object?> _freezeMap(Map<Object?, Object?> map) =>
      Map<String, Object?>.unmodifiable({for (final MapEntry(:key, :value) in map.entries) '$key': _freeze(value)});

  @override
  bool operator ==(Object other) => other is GenericValues && _equality.equals(other._root, _root);

  @override
  int get hashCode => _equality.hash(_root);

  @override
  String toString() => 'GenericValues($_root)';
}
