part of '../generic_node.dart';

@MappableClass(discriminatorValue: 'expanded')
final class ExpandedNode extends GenericNode with ExpandedNodeMappable {
  const new({required super.id, this.child, this.flex = const Literal(1)});

  final GenericNode? child;

  @MappableField(hook: BindableHook<int>())
  final Bindable<int> flex;

  @override
  List<GenericNode> get childNodes => [?child];
}
