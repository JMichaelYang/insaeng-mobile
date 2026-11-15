import 'package:collection/collection.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:insaeng/domain/models/generic_ui/bindable.dart';
import 'package:insaeng/domain/models/generic_ui/generic_values.dart';
import 'package:meta/meta.dart';

@immutable
sealed class BindableJson {
  const new();

  static const _equality = DeepCollectionEquality();

  static BindableJson decode(Object? json) => switch (BindableHook.decodeBinding<Object>(json)) {
    final binding? => JsonBinding(binding),
    null => switch (json) {
      final Map<Object?, Object?> map => JsonObject({
        for (final MapEntry(:key, :value) in map.entries) '$key': BindableJson.decode(value),
      }),
      final List<Object?> list => JsonList([for (final item in list) BindableJson.decode(item)]),
      null || String() || num() || bool() => JsonLiteral(json),
      _ => throw MapperException.unexpectedType(json.runtimeType, 'JSON'),
    },
  };

  Object? resolve(GenericValues values);

  Object? encode();
}

final class JsonLiteral extends BindableJson {
  const new(this.value);

  final Object? value;

  @override
  Object? resolve(GenericValues values) => value;

  @override
  Object? encode() => value;

  @override
  bool operator ==(Object other) => other is JsonLiteral && other.value == value;

  @override
  int get hashCode => Object.hash(JsonLiteral, value);

  @override
  String toString() => 'JsonLiteral($value)';
}

final class JsonBinding extends BindableJson {
  const new(this.binding);

  final Binding<Object> binding;

  @override
  Object? resolve(GenericValues values) => binding.resolve(values);

  @override
  Object? encode() => BindableHook.encodeBinding(binding);

  @override
  bool operator ==(Object other) => other is JsonBinding && other.binding == binding;

  @override
  int get hashCode => Object.hash(JsonBinding, binding);

  @override
  String toString() => 'JsonBinding($binding)';
}

final class JsonObject extends BindableJson {
  const new(this.fields);

  final Map<String, BindableJson> fields;

  @override
  Map<String, Object?> resolve(GenericValues values) => {
    for (final MapEntry(:key, :value) in fields.entries) key: value.resolve(values),
  };

  @override
  Map<String, Object?> encode() => {for (final MapEntry(:key, :value) in fields.entries) key: value.encode()};

  @override
  bool operator ==(Object other) => other is JsonObject && BindableJson._equality.equals(other.fields, fields);

  @override
  int get hashCode => Object.hash(JsonObject, BindableJson._equality.hash(fields));

  @override
  String toString() => 'JsonObject($fields)';
}

final class JsonList extends BindableJson {
  const new(this.items);

  final List<BindableJson> items;

  @override
  List<Object?> resolve(GenericValues values) => [for (final item in items) item.resolve(values)];

  @override
  List<Object?> encode() => [for (final item in items) item.encode()];

  @override
  bool operator ==(Object other) => other is JsonList && BindableJson._equality.equals(other.items, items);

  @override
  int get hashCode => Object.hash(JsonList, BindableJson._equality.hash(items));

  @override
  String toString() => 'JsonList($items)';
}

final class BindableJsonHook extends MappingHook {
  const new();

  @override
  Object? beforeDecode(Object? value) => switch (value) {
    null || BindableJson() => value,
    _ => BindableJson.decode(value),
  };

  @override
  Object? beforeEncode(Object? value) => switch (value) {
    final BindableJson json => json.encode(),
    _ => value,
  };
}
