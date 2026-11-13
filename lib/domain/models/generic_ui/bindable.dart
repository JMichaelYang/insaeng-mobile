import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:meta/meta.dart';

@immutable
sealed class Bindable<T extends Object> {
  const new();

  static const _equality = DeepCollectionEquality();

  T? resolve(GenericValues values);
}

final class Literal<T extends Object> extends Bindable<T> {
  const new(this.value);

  final T value;

  @override
  T resolve(GenericValues values) => value;

  @override
  bool operator ==(Object other) => other is Literal<T> && Bindable._equality.equals(other.value, value);

  @override
  int get hashCode => Object.hash(Literal, Bindable._equality.hash(value));

  @override
  String toString() => 'Literal<$T>($value)';
}

final class Binding<T extends Object> extends Bindable<T> {
  const new(this.path, {this.fallback});

  final String path;
  final T? fallback;

  @override
  T? resolve(GenericValues values) => switch (values.get(path)) {
    final T value => value,
    final Object value when (value is num || value is bool) && '' is T => '$value' as T,
    _ => fallback,
  };

  @override
  bool operator ==(Object other) =>
      other is Binding<T> && other.path == path && Bindable._equality.equals(other.fallback, fallback);

  @override
  int get hashCode => Object.hash(Binding, path, Bindable._equality.hash(fallback));

  @override
  String toString() => 'Binding<$T>($path, fallback: $fallback)';
}

final class BindableHook<T extends Object> extends MappingHook {
  const new();

  static const bindKey = r'$bind';
  static const fallbackKey = 'fallback';

  @override
  Object? beforeDecode(Object? value) => switch (value) {
    null || Bindable<T>() => value,
    final Map<Object?, Object?> json when json.containsKey(bindKey) => switch (json[bindKey]) {
      final String path => Binding<T>(path, fallback: MapperContainer.globals.fromValue<T?>(json[fallbackKey])),
      final path => throw MapperException.unexpectedType(path.runtimeType, 'String'),
    },
    _ => Literal<T>(MapperContainer.globals.fromValue<T>(value)),
  };

  @override
  Object? beforeEncode(Object? value) => switch (value) {
    Literal<T>(:final value) => MapperContainer.globals.toValue<T>(value),
    Binding<T>(:final path, :final fallback) => <String, Object?>{
      bindKey: path,
      if (fallback != null) fallbackKey: MapperContainer.globals.toValue<T>(fallback),
    },
    _ => value,
  };
}
