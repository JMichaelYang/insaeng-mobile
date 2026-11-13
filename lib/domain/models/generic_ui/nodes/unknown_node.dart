part of 'generic_node.dart';

@MappableClass(discriminatorValue: MappableClass.useAsDefault)
final class UnknownNode extends GenericNode with UnknownNodeMappable {
  const new({required super.id, this.fallback});

  final GenericNode? fallback;
}
