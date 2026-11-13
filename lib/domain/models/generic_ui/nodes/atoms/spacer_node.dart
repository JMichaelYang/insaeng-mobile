part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'spacer')
final class SpacerNode extends GenericNode with SpacerNodeMappable {
  const new({required super.id});
}
