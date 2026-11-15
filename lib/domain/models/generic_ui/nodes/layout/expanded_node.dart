part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'expanded')
final class ExpandedNode extends GenericNode with ExpandedNodeMappable {
  const new({required super.id, this.child, this.flex = 1});

  final GenericNode? child;

  final int flex;

  @override
  List<GenericNode> get childNodes => [?child];
}
