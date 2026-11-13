part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'divider')
final class DividerNode extends GenericNode with DividerNodeMappable {
  const new({required super.id});
}
