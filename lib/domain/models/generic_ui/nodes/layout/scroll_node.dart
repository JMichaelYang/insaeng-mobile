part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'scroll')
final class ScrollNode extends GenericNode with ScrollNodeMappable {
  const new({required super.id, this.child});

  final GenericNode? child;

  @override
  List<GenericNode> get childNodes => [?child];
}
