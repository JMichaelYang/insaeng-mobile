part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'scroll')
final class ScrollNode extends GenericNode with ScrollNodeMappable {
  const new({required super.id, this.child, this.onRefresh = const []});

  final GenericNode? child;

  final List<GenericAction> onRefresh;

  @override
  List<GenericNode> get childNodes => [?child];

  @override
  List<GenericAction> get actions => onRefresh;
}
